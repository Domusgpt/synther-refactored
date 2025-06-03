#ifndef OSCILLATOR_H
#define OSCILLATOR_H

#include <cmath>
#include <vector>
#include <random>

/**
 * Base class for oscillator implementations
 */
class Oscillator {
public:
    enum class WaveformType {
        Sine,
        Square,
        Triangle,
        Sawtooth,
        Noise,
        Pulse,
        Wavetable // For future expansion
    };

    Oscillator() : sampleRate(44100), frequency(440.0f), phase(0.0f), phaseIncrement(0.0f),
                  volume(0.5f), detune(0.0f), pan(0.0f), pulseWidth(0.5f),
                  waveformType(WaveformType::Sine), lastOutput(0.0f) {
        updatePhaseIncrement();
    }
    
    virtual ~Oscillator() = default;
    
    /**
     * Process one sample of audio.
     * 
     * @return The computed sample value
     */
    virtual float process() {
        // Calculate base waveform
        float sample = 0.0f;
        
        switch (waveformType) {
            case WaveformType::Sine:
                sample = processSine();
                break;
                
            case WaveformType::Square:
                sample = processSquare();
                break;
                
            case WaveformType::Triangle:
                sample = processTriangle();
                break;
                
            case WaveformType::Sawtooth:
                sample = processSawtooth();
                break;
                
            case WaveformType::Noise:
                sample = processNoise();
                break;
                
            case WaveformType::Pulse:
                sample = processPulse();
                break;
                
            case WaveformType::Wavetable:
                sample = processWavetable();
                break;
        }
        
        // Update phase
        phase += phaseIncrement;
        if (phase >= 1.0f) {
            phase -= 1.0f;
        }
        
        // Apply volume
        lastOutput = sample * volume;
        return lastOutput;
    }
    
    /**
     * Set the sample rate.
     * 
     * @param sr The new sample rate
     */
    virtual void setSampleRate(int sr) {
        sampleRate = sr;
        updatePhaseIncrement();
    }
    
    /**
     * Set the oscillator frequency.
     * 
     * @param freq The new frequency in Hz
     */
    virtual void setFrequency(float freq) {
        frequency = freq;
        updatePhaseIncrement();
    }
    
    /**
     * Set the oscillator detune amount.
     * 
     * @param det The detune amount in cents
     */
    virtual void setDetune(float det) {
        detune = det;
        updatePhaseIncrement();
    }
    
    /**
     * Set the oscillator volume.
     * 
     * @param vol The volume level (0.0 - 1.0)
     */
    virtual void setVolume(float vol) {
        volume = vol;
    }
    
    /**
     * Set the oscillator panning.
     * 
     * @param p The pan position (-1.0 = left, 0.0 = center, 1.0 = right)
     */
    virtual void setPan(float p) {
        pan = p;
    }
    
    /**
     * Set the oscillator waveform type.
     * 
     * @param type The waveform type
     */
    virtual void setType(int type) {
        waveformType = static_cast<WaveformType>(type);
    }
    
    /**
     * Set the pulse width for pulse waveform.
     * 
     * @param width The pulse width (0.0 - 1.0)
     */
    virtual void setPulseWidth(float width) {
        pulseWidth = width;
    }
    
    /**
     * Get the current frequency.
     * 
     * @return The current frequency in Hz
     */
    float getFrequency() const {
        return frequency;
    }
    
    /**
     * Get the current waveform type.
     * 
     * @return The current waveform type
     */
    WaveformType getType() const {
        return waveformType;
    }
    
    /**
     * Get the current volume.
     * 
     * @return The current volume level
     */
    float getVolume() const {
        return volume;
    }

protected:
    // Processing methods for each waveform type
    virtual float processSine() {
        return std::sin(2.0f * M_PI * phase);
    }
    
    virtual float processSquare() {
        // Anti-aliased square using PolyBLEP
        float value = (phase < 0.5f) ? 1.0f : -1.0f;
        return value - polyBLEP(phase) + polyBLEP(fmod(phase + 0.5f, 1.0f));
    }
    
    virtual float processTriangle() {
        // Generate triangle from modified sawtooth waves
        float saw1 = 2.0f * (phase - floor(phase + 0.5f));
        return 2.0f * (std::abs(saw1) - 0.5f);
    }
    
    virtual float processSawtooth() {
        // Anti-aliased sawtooth using PolyBLEP
        float value = 2.0f * phase - 1.0f;
        return value - polyBLEP(phase);
    }
    
    virtual float processNoise() {
        // White noise generator
        static std::random_device rd;
        static std::mt19937 gen(rd());
        static std::uniform_real_distribution<float> dist(-1.0f, 1.0f);
        return dist(gen);
    }
    
    virtual float processPulse() {
        // Anti-aliased pulse wave using PolyBLEP
        float value = (phase < pulseWidth) ? 1.0f : -1.0f;
        return value - polyBLEP(phase) + polyBLEP(fmod(phase + (1.0f - pulseWidth), 1.0f));
    }
    
    virtual float processWavetable() {
        // Default wavetable implementation (can be overridden)
        return processSine(); // Fallback to sine
    }
    
    // PolyBLEP implementation for anti-aliasing
    float polyBLEP(float t) {
        float dt = phaseIncrement;
        
        // t = 0 to 1
        if (t < dt) {
            t /= dt;
            return t + t - t * t - 1.0f;
        }
        // t = 1 to 0
        else if (t > 1.0f - dt) {
            t = (t - 1.0f) / dt;
            return t * t + t + t + 1.0f;
        }
        // Default case, no discontinuity
        else {
            return 0.0f;
        }
    }
    
    void updatePhaseIncrement() {
        // Apply detune in cents to frequency
        float detuneMultiplier = std::pow(2.0f, detune / 1200.0f);
        float detuneFreq = frequency * detuneMultiplier;
        
        // Calculate phase increment per sample
        phaseIncrement = detuneFreq / static_cast<float>(sampleRate);
    }
    
    int sampleRate;
    float frequency;
    float phase;
    float phaseIncrement;
    float volume;
    float detune;
    float pan;
    float pulseWidth;
    WaveformType waveformType;
    float lastOutput;
};

#endif // OSCILLATOR_H