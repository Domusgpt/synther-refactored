#ifndef REVERB_H
#define REVERB_H

#include "delay.h"
#include <memory>
#include <array>

/**
 * A simple reverb effect using a feedback delay network.
 */
class Reverb {
public:
    Reverb() : sampleRate(44100), roomSize(0.5f), damping(0.5f), mix(0.2f) {
        // Create a network of delays with different times
        static const float delayTimes[8] = {
            0.0297f, 0.0371f, 0.0411f, 0.0437f,
            0.0533f, 0.0653f, 0.0747f, 0.0863f
        };
        
        // Initialize delay lines
        for (int i = 0; i < 8; ++i) {
            delays[i] = std::make_unique<Delay>();
            delays[i]->setTime(delayTimes[i]);
            delays[i]->setMix(1.0f); // Full wet signal for the network
            delays[i]->setFeedback(0.0f); // No internal feedback in the delays
        }
        
        // Apply room size and damping
        updateParameters();
    }
    
    ~Reverb() = default;
    
    /**
     * Process one sample through the reverb.
     * 
     * @param input The input sample
     * @return The processed output sample
     */
    float process(float input) {
        // Apply input diffusion by spreading the signal across all delay lines
        for (int i = 0; i < 8; ++i) {
            diffusionBuffer[i] = input * 0.125f; // Distribute energy evenly
        }
        
        // Process through the feedback delay network
        for (int i = 0; i < 4; ++i) {
            // Process the first half of delay lines
            float delayOut1 = delays[i]->process(diffusionBuffer[i]);
            
            // Process the second half of delay lines
            float delayOut2 = delays[i + 4]->process(diffusionBuffer[i + 4]);
            
            // Feedback from one delay to others
            feedbackBuffer[i] = delayOut1;
            feedbackBuffer[i + 4] = delayOut2;
        }
        
        // Apply the feedback matrix between all delay lines
        for (int i = 0; i < 8; ++i) {
            diffusionBuffer[i] = 0.0f;
            for (int j = 0; j < 8; ++j) {
                // Hadamard feedback matrix
                float feedback = (i & j) ? -feedbackMatrix[i][j] : feedbackMatrix[i][j];
                diffusionBuffer[i] += feedbackBuffer[j] * feedback;
            }
        }
        
        // Combine all outputs
        float wetOutput = 0.0f;
        for (int i = 0; i < 8; ++i) {
            wetOutput += feedbackBuffer[i] * 0.125f;
        }
        
        // Apply low-pass filtering to simulate air absorption
        wetOutput = lpFilter(wetOutput);
        
        // Mix dry and wet signals
        return input * (1.0f - mix) + wetOutput * mix;
    }
    
    /**
     * Set the sample rate.
     * 
     * @param sr The new sample rate
     */
    void setSampleRate(int sr) {
        sampleRate = sr;
        for (auto& delay : delays) {
            if (delay) {
                delay->setSampleRate(sr);
            }
        }
    }
    
    /**
     * Set the room size.
     * 
     * @param size The room size (0.0 - 1.0)
     */
    void setRoomSize(float size) {
        roomSize = std::clamp(size, 0.1f, 0.9f);
        updateParameters();
    }
    
    /**
     * Set the damping amount.
     * 
     * @param damp The damping amount (0.0 - 1.0)
     */
    void setDamping(float damp) {
        damping = std::clamp(damp, 0.0f, 1.0f);
        updateParameters();
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
     * Clear the reverb state.
     */
    void clear() {
        for (auto& delay : delays) {
            if (delay) {
                delay->clear();
            }
        }
        
        for (int i = 0; i < 8; ++i) {
            diffusionBuffer[i] = 0.0f;
            feedbackBuffer[i] = 0.0f;
        }
        
        lpFilterState = 0.0f;
    }
    
private:
    /**
     * Update internal parameters based on room size and damping.
     */
    void updateParameters() {
        // Update feedback gain based on room size
        float feedbackGain = 0.7f + roomSize * 0.29f;
        
        // Update feedback matrix with the gain
        for (int i = 0; i < 8; ++i) {
            for (int j = 0; j < 8; ++j) {
                feedbackMatrix[i][j] = (i == j) ? 0.0f : feedbackGain / 7.0f;
            }
        }
        
        // Update damping (low-pass filter cutoff)
        // Map damping 0-1 to cutoff range 10000-2000 Hz (higher damping = lower cutoff)
        float cutoff = 10000.0f - (damping * 8000.0f);
        lpCoeff = std::exp(-2.0f * M_PI * cutoff / sampleRate);
    }
    
    /**
     * Apply a simple one-pole low-pass filter.
     * 
     * @param input The input sample
     * @return The filtered output sample
     */
    float lpFilter(float input) {
        lpFilterState = (lpFilterState * lpCoeff) + (input * (1.0f - lpCoeff));
        return lpFilterState;
    }
    
    int sampleRate;
    float roomSize;
    float damping;
    float mix;
    
    // Delay network
    std::array<std::unique_ptr<Delay>, 8> delays;
    
    // Buffers for the feedback delay network
    float diffusionBuffer[8] = {0.0f};
    float feedbackBuffer[8] = {0.0f};
    
    // Feedback matrix
    float feedbackMatrix[8][8] = {0.0f};
    
    // Low-pass filter for damping
    float lpCoeff = 0.0f;
    float lpFilterState = 0.0f;
};

#endif // REVERB_H