#ifndef AUDIO_PLATFORM_H
#define AUDIO_PLATFORM_H

#include <functional>
#include <memory>
#include <string>

/**
 * Abstract base class for platform-specific audio implementations.
 * 
 * This class defines the interface for platform-specific audio implementations,
 * such as CoreAudio on macOS/iOS, WASAPI on Windows, OpenSL ES on Android, etc.
 */
class AudioPlatform {
public:
    // Callback type for audio processing
    using AudioCallback = std::function<void(float* buffer, int numFrames, int numChannels)>;
    
    // Destructor
    virtual ~AudioPlatform() = default;
    
    /**
     * Initialize the audio platform.
     * 
     * @param sampleRate The desired sample rate
     * @param bufferSize The desired buffer size
     * @param numChannels The number of audio channels (1=mono, 2=stereo)
     * @param callback The callback function for audio processing
     * @return True on success, false on failure
     */
    virtual bool initialize(int sampleRate, int bufferSize, int numChannels, AudioCallback callback) = 0;
    
    /**
     * Start audio processing.
     * 
     * @return True on success, false on failure
     */
    virtual bool start() = 0;
    
    /**
     * Stop audio processing.
     * 
     * @return True on success, false on failure
     */
    virtual bool stop() = 0;
    
    /**
     * Get the actual sample rate being used.
     * 
     * @return The actual sample rate
     */
    virtual int getSampleRate() const = 0;
    
    /**
     * Get the actual buffer size being used.
     * 
     * @return The actual buffer size
     */
    virtual int getBufferSize() const = 0;
    
    /**
     * Get the number of output channels.
     * 
     * @return The number of output channels
     */
    virtual int getNumOutputChannels() const = 0;
    
    /**
     * Check if the audio platform is initialized.
     * 
     * @return True if initialized, false otherwise
     */
    virtual bool isInitialized() const = 0;
    
    /**
     * Check if audio processing is running.
     * 
     * @return True if running, false otherwise
     */
    virtual bool isRunning() const = 0;
    
    /**
     * Get error message for the last error.
     * 
     * @return Error message string
     */
    virtual std::string getLastError() const = 0;
    
    /**
     * Create an appropriate audio platform instance for the current platform.
     * 
     * @return A unique_ptr to the platform-specific implementation
     */
    static std::unique_ptr<AudioPlatform> createForCurrentPlatform();
};

#endif // AUDIO_PLATFORM_H