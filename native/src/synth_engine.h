#ifndef SYNTH_ENGINE_H
#define SYNTH_ENGINE_H

#include <vector>
#include <memory>
#include <mutex>
#include <atomic>
#include <unordered_map>
#include <functional>

// Forward declarations
class Oscillator;
class Filter;
class Envelope;
class Delay;
class Reverb;
class AudioPlatform;

namespace synth {
    class WavetableManager;
    class GranularSynthesizer;
}

/**
 * Main class for the synthesizer engine.
 * 
 * This class handles all audio processing, parameter management,
 * and coordinates between different audio modules.
 */
class SynthEngine {
public:
    // Singleton pattern
    static SynthEngine& getInstance();
    
    // Delete copy and move operations
    SynthEngine(const SynthEngine&) = delete;
    SynthEngine& operator=(const SynthEngine&) = delete;
    SynthEngine(SynthEngine&&) = delete;
    SynthEngine& operator=(SynthEngine&&) = delete;
    
    /**
     * Initialize the engine with given parameters.
     * 
     * @param sampleRate The sample rate to use (e.g., 44100, 48000)
     * @param bufferSize The buffer size to use
     * @param initialVolume The initial master volume (0.0 - 1.0)
     * @return True on success, false on failure
     */
    bool initialize(int sampleRate, int bufferSize, float initialVolume);
    
    /**
     * Shut down the engine and clean up resources.
     */
    void shutdown();
    
    /**
     * Process a batch of audio samples.
     * 
     * @param outputBuffer Pointer to the output buffer
     * @param numFrames Number of frames to process
     * @param numChannels Number of audio channels
     */
    void processAudio(float* outputBuffer, int numFrames, int numChannels);
    
    /**
     * Handle a note-on event.
     * 
     * @param note The MIDI note number (0-127)
     * @param velocity The note velocity (0-127)
     * @return True on success, false on failure
     */
    bool noteOn(int note, int velocity);
    
    /**
     * Handle a note-off event.
     * 
     * @param note The MIDI note number (0-127)
     * @return True on success, false on failure
     */
    bool noteOff(int note);
    
    /**
     * Process a raw MIDI event.
     * 
     * @param status The MIDI status byte
     * @param data1 The first MIDI data byte
     * @param data2 The second MIDI data byte
     * @return True on success, false on failure
     */
    bool processMidiEvent(unsigned char status, unsigned char data1, unsigned char data2);
    
    /**
     * Set a parameter value.
     * 
     * @param parameterId The ID of the parameter to set
     * @param value The new value for the parameter
     * @return True on success, false on failure
     */
    bool setParameter(int parameterId, float value);
    
    /**
     * Get a parameter value.
     * 
     * @param parameterId The ID of the parameter to get
     * @return The parameter value
     */
    float getParameter(int parameterId);
    
    /**
     * Get the current sample rate.
     * 
     * @return The current sample rate
     */
    int getSampleRate() const {
        return sampleRate;
    }
    
    /**
     * Get the current buffer size.
     * 
     * @return The current buffer size
     */
    int getBufferSize() const {
        return bufferSize;
    }
    
    /**
     * Check if the engine is initialized.
     * 
     * @return True if initialized, false otherwise
     */
    bool isInitialized() const {
        return initialized;
    }
    
    /**
     * Load an audio buffer for granular synthesis.
     * 
     * @param buffer The audio buffer to load
     * @return True on success, false on failure
     */
    bool loadGranularBuffer(const std::vector<float>& buffer);
    
    /**
     * Audio analysis functions for visualization.
     */
    double getBassLevel() const;
    double getMidLevel() const;
    double getHighLevel() const;
    double getAmplitudeLevel() const;
    double getDominantFrequency() const;

private:
    // Private constructor for singleton
    SynthEngine();
    ~SynthEngine();
    
    // Engine state
    std::atomic<bool> initialized;
    int sampleRate;
    int bufferSize;
    float masterVolume;
    bool masterMute;
    
    // Audio platform
    std::unique_ptr<AudioPlatform> audioPlatform;
    
    // Audio modules
    std::vector<std::unique_ptr<Oscillator>> oscillators;
    std::unique_ptr<Filter> filter;
    std::unique_ptr<Envelope> envelope;
    std::unique_ptr<Delay> delay;
    std::unique_ptr<Reverb> reverb;
    std::unique_ptr<synth::WavetableManager> wavetableManager;
    std::unique_ptr<synth::GranularSynthesizer> granularSynth;
    
    // Note tracking
    std::unordered_map<int, float> activeNotes; // note -> velocity
    std::mutex notesMutex;
    
    // Parameter cache
    std::unordered_map<int, float> parameterCache;
    std::mutex parameterMutex;
    
    // Audio analysis data
    mutable std::atomic<double> bassLevel{0.0};
    mutable std::atomic<double> midLevel{0.0};
    mutable std::atomic<double> highLevel{0.0};
    mutable std::atomic<double> amplitudeLevel{0.0};
    mutable std::atomic<double> dominantFrequency{0.0};
    
    // Audio analysis filter states
    float bassFilterState{0.0f};
    float midFilterState{0.0f};
    float highFilterState{0.0f};
    
    // Internal methods
    void initializeDefaultModules();
    float noteToFrequency(int note) const;
    void updateAudioAnalysis(const float* buffer, int numFrames, int numChannels);
};

// Parameter IDs
namespace SynthParameterId {
    // Master parameters
    constexpr int masterVolume = 0;
    constexpr int masterMute = 1;
    
    // Filter parameters
    constexpr int filterCutoff = 10;
    constexpr int filterResonance = 11;
    constexpr int filterType = 12;
    
    // Envelope parameters
    constexpr int attackTime = 20;
    constexpr int decayTime = 21;
    constexpr int sustainLevel = 22;
    constexpr int releaseTime = 23;
    
    // Effect parameters
    constexpr int reverbMix = 30;
    constexpr int delayTime = 31;
    constexpr int delayFeedback = 32;
    
    // Granular parameters
    constexpr int granularActive = 40;
    constexpr int granularGrainRate = 41;
    constexpr int granularGrainDuration = 42;
    constexpr int granularPosition = 43;
    constexpr int granularPitch = 44;
    constexpr int granularAmplitude = 45;
    constexpr int granularPositionVar = 46;
    constexpr int granularPitchVar = 47;
    constexpr int granularDurationVar = 48;
    constexpr int granularPan = 49;
    constexpr int granularPanVar = 50;
    constexpr int granularWindowType = 51;
    
    // Oscillator parameters (per oscillator)
    // For oscillator n, use: oscillatorType + (n * 10)
    constexpr int oscillatorType = 100;
    constexpr int oscillatorFrequency = 101;
    constexpr int oscillatorDetune = 102;
    constexpr int oscillatorVolume = 103;
    constexpr int oscillatorPan = 104;
    constexpr int oscillatorWavetableIndex = 105;
    constexpr int oscillatorWavetablePosition = 106;
}

#endif // SYNTH_ENGINE_H