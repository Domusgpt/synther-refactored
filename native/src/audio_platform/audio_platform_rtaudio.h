#ifndef AUDIO_PLATFORM_RTAUDIO_H
#define AUDIO_PLATFORM_RTAUDIO_H

#include "audio_platform.h"

/**
 * RTAudio implementation of the AudioPlatform interface.
 * 
 * This class uses RTAudio for cross-platform desktop audio I/O.
 * It works on Windows, macOS, and Linux.
 */
class RTAudioPlatform : public AudioPlatform {
public:
    RTAudioPlatform();
    ~RTAudioPlatform() override;
    
    bool initialize(int sampleRate, int bufferSize, int numChannels, AudioCallback callback) override;
    bool start() override;
    bool stop() override;
    int getSampleRate() const override;
    int getBufferSize() const override;
    int getNumOutputChannels() const override;
    bool isInitialized() const override;
    bool isRunning() const override;
    std::string getLastError() const override;
    
private:
    // Forward declaration of private implementation
    // This is to avoid exposing RTAudio headers to clients
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

#endif // AUDIO_PLATFORM_RTAUDIO_H