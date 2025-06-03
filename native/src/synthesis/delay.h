#ifndef DELAY_H
#define DELAY_H

#include <cmath>
#include <vector>
#include <algorithm>

/**
 * A delay effect with feedback and filtering.
 */
class Delay {
public:
    Delay() : sampleRate(44100), maxDelayTime(2.0f), delayTime(0.5f), feedback(0.3f),
             mix(0.5f), lowpassCoeff(0.0f), buffer(nullptr), bufferSize(0),
             writeIndex(0), readIndex(0) {
        // Initialize delay buffer for max delay time at 48kHz (highest common sample rate)
        resize(maxDelayTime, 48000);
        setLowpassCutoff(10000.0f); // Default feedback lowpass filter cutoff
    }
    
    ~Delay() {
        if (buffer) {
            delete[] buffer;
            buffer = nullptr;
        }
    }
    
    /**
     * Process one sample through the delay.
     * 
     * @param input The input sample
     * @return The processed output sample
     */
    float process(float input) {
        if (!buffer) return input;
        
        // Read from buffer with fractional delay
        float delayedSample = readFractional();
        
        // Apply feedback lowpass filter to the delayed sample
        feedbackFilter = (feedbackFilter * lowpassCoeff) + (delayedSample * (1.0f - lowpassCoeff));
        
        // Write to buffer with feedback
        buffer[writeIndex] = input + (feedbackFilter * feedback);
        
        // Update indices
        writeIndex = (writeIndex + 1) % bufferSize;
        updateReadIndex();
        
        // Mix dry and wet signals
        return input * (1.0f - mix) + delayedSample * mix;
    }
    
    /**
     * Set the sample rate.
     * 
     * @param sr The new sample rate
     */
    void setSampleRate(int sr) {
        if (sampleRate != sr) {
            sampleRate = sr;
            updateReadIndex();
        }
    }
    
    /**
     * Set the delay time.
     * 
     * @param time The delay time in seconds
     */
    void setTime(float time) {
        delayTime = std::clamp(time, 0.01f, maxDelayTime);
        updateReadIndex();
    }
    
    /**
     * Set the feedback amount.
     * 
     * @param fb The feedback amount (0.0 - 1.0)
     */
    void setFeedback(float fb) {
        feedback = std::clamp(fb, 0.0f, 0.99f); // Limit to prevent infinite feedback
    }
    
    /**
     * Set the wet/dry mix.
     * 
     * @param m The mix amount (0.0 = dry, 1.0 = wet)
     */
    void setMix(float m) {
        mix = std::clamp(m, 0.0f, 1.0f);
    }
    
    /**
     * Set the lowpass filter cutoff frequency for the feedback path.
     * 
     * @param cutoff The cutoff frequency in Hz
     */
    void setLowpassCutoff(float cutoff) {
        // Simple one-pole lowpass coefficient calculation
        float freq = std::clamp(cutoff, 20.0f, 20000.0f);
        lowpassCoeff = std::exp(-2.0f * M_PI * freq / sampleRate);
    }
    
    /**
     * Clear the delay buffer.
     */
    void clear() {
        if (buffer) {
            for (int i = 0; i < bufferSize; ++i) {
                buffer[i] = 0.0f;
            }
        }
        feedbackFilter = 0.0f;
    }
    
private:
    /**
     * Resize the delay buffer for a new maximum delay time.
     * 
     * @param maxTime The maximum delay time in seconds
     * @param maxSampleRate The maximum expected sample rate
     */
    void resize(float maxTime, int maxSampleRate) {
        int newSize = static_cast<int>(maxTime * maxSampleRate) + 1;
        
        if (newSize != bufferSize) {
            if (buffer) {
                delete[] buffer;
            }
            
            buffer = new float[newSize]();
            bufferSize = newSize;
            writeIndex = 0;
            readIndex = 0;
            clear();
        }
    }
    
    /**
     * Update the read index based on the current delay time.
     */
    void updateReadIndex() {
        float delaySamples = delayTime * sampleRate;
        
        // Calculate the fractional delay samples and integer part
        fracDelay = delaySamples - std::floor(delaySamples);
        int delayInSamples = static_cast<int>(delaySamples);
        
        // Safety check
        if (delayInSamples >= bufferSize) {
            delayInSamples = bufferSize - 1;
            fracDelay = 0.0f;
        }
        
        // Calculate read position
        readIndex = (writeIndex - delayInSamples + bufferSize) % bufferSize;
    }
    
    /**
     * Read from the delay buffer with linear interpolation for fractional delays.
     * 
     * @return The interpolated sample value
     */
    float readFractional() {
        if (!buffer) return 0.0f;
        
        // Read current sample
        float sample1 = buffer[readIndex];
        
        // Read next sample for interpolation
        int nextIndex = (readIndex + 1) % bufferSize;
        float sample2 = buffer[nextIndex];
        
        // Linear interpolation for fractional delay
        return sample1 + fracDelay * (sample2 - sample1);
    }
    
    int sampleRate;
    float maxDelayTime;
    float delayTime;
    float feedback;
    float mix;
    float lowpassCoeff;
    float feedbackFilter;
    float fracDelay;
    
    float* buffer;
    int bufferSize;
    int writeIndex;
    int readIndex;
};

#endif // DELAY_H