#include "audio_platform_rtaudio.h"
#include "RtAudio.h"
#include <iostream>
#include <vector>
#include <stdexcept>

// RtAudio callback function
int rtaudioCallback(void* outputBuffer, void* /*inputBuffer*/, unsigned int nFrames,
                   double /*streamTime*/, RtAudioStreamStatus status, void* userData) {
    if (status) {
        std::cerr << "Stream underflow detected!" << std::endl;
    }
    
    // Get user callback
    auto* callback = static_cast<AudioPlatform::AudioCallback*>(userData);
    if (callback) {
        (*callback)(static_cast<float*>(outputBuffer), nFrames, 2);
    }
    
    return 0;
}

// Private implementation for RTAudioPlatform
class RTAudioPlatform::Impl {
public:
    Impl() : initialized(false), running(false), sampleRate(44100), 
             bufferSize(512), numChannels(2), lastError("") {
        // Try to detect and handle any device errors
        try {
            rtAudio = std::make_unique<RtAudio>();
        } catch (const std::exception& e) {
            lastError = e.what();
        }
    }
    
    ~Impl() {
        if (running) {
            try {
                rtAudio->stopStream();
            } catch (const std::exception& e) {
                std::cerr << "Error stopping stream: " << e.what() << std::endl;
            }
        }
        
        if (initialized) {
            try {
                if (rtAudio->isStreamOpen()) {
                    rtAudio->closeStream();
                }
            } catch (const std::exception& e) {
                std::cerr << "Error closing stream: " << e.what() << std::endl;
            }
        }
    }
    
    bool initialize(int sr, int bs, int nc, AudioPlatform::AudioCallback cb) {
        if (initialized) {
            return true; // Already initialized
        }
        
        if (!rtAudio) {
            lastError = "RTAudio failed to initialize";
            return false;
        }
        
        sampleRate = sr;
        bufferSize = bs;
        numChannels = nc;
        callback = cb;
        
        try {
            // Check if we have audio devices
            if (rtAudio->getDeviceCount() < 1) {
                lastError = "No audio devices found";
                return false;
            }
            
            // Get default output device
            unsigned int deviceId = rtAudio->getDefaultOutputDevice();
            RtAudio::DeviceInfo deviceInfo = rtAudio->getDeviceInfo(deviceId);
            
            // Configure stream parameters
            RtAudio::StreamParameters outParams;
            outParams.deviceId = deviceId;
            outParams.nChannels = numChannels;
            outParams.firstChannel = 0;
            
            // Open stream
            rtAudio->openStream(&outParams, nullptr, RTAUDIO_FLOAT32, 
                               sampleRate, &bufferSize, &rtaudioCallback, 
                               &callback);
            
            initialized = true;
            return true;
        } catch (const std::exception& e) {
            lastError = e.what();
            return false;
        }
    }
    
    bool start() {
        if (!initialized) {
            lastError = "Cannot start: not initialized";
            return false;
        }
        
        if (running) {
            return true; // Already running
        }
        
        try {
            rtAudio->startStream();
            running = true;
            return true;
        } catch (const std::exception& e) {
            lastError = e.what();
            return false;
        }
    }
    
    bool stop() {
        if (!running) {
            return true; // Already stopped
        }
        
        try {
            rtAudio->stopStream();
            running = false;
            return true;
        } catch (const std::exception& e) {
            lastError = e.what();
            return false;
        }
    }
    
    std::unique_ptr<RtAudio> rtAudio;
    bool initialized;
    bool running;
    unsigned int sampleRate;
    unsigned int bufferSize;
    unsigned int numChannels;
    std::string lastError;
    AudioPlatform::AudioCallback callback;
};

// RTAudioPlatform implementation
RTAudioPlatform::RTAudioPlatform() : pImpl(std::make_unique<Impl>()) {}

RTAudioPlatform::~RTAudioPlatform() = default;

bool RTAudioPlatform::initialize(int sampleRate, int bufferSize, int numChannels, AudioCallback callback) {
    return pImpl->initialize(sampleRate, bufferSize, numChannels, callback);
}

bool RTAudioPlatform::start() {
    return pImpl->start();
}

bool RTAudioPlatform::stop() {
    return pImpl->stop();
}

int RTAudioPlatform::getSampleRate() const {
    return pImpl->sampleRate;
}

int RTAudioPlatform::getBufferSize() const {
    return pImpl->bufferSize;
}

int RTAudioPlatform::getNumOutputChannels() const {
    return pImpl->numChannels;
}

bool RTAudioPlatform::isInitialized() const {
    return pImpl->initialized;
}

bool RTAudioPlatform::isRunning() const {
    return pImpl->running;
}

std::string RTAudioPlatform::getLastError() const {
    return pImpl->lastError;
}