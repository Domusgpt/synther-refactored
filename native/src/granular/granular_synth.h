#pragma once
#include "grain.h"
#include <vector>
#include <random>
#include <algorithm>

namespace synth {

/// Granular synthesis engine
class GranularSynthesizer {
public:
    GranularSynthesizer() 
        : sampleRate_(44100.0f)
        , grainRate_(10.0f)  // 10 grains per second
        , grainDuration_(0.05f)  // 50ms
        , grainDurationVariation_(0.0f)
        , position_(0.0f)
        , positionVariation_(0.0f)
        , pitch_(1.0f)
        , pitchVariation_(0.0f)
        , amplitude_(1.0f)
        , pan_(0.0f)
        , panVariation_(0.0f)
        , windowType_(Grain::WindowType::Hann)
        , framesSinceLastGrain_(0)
        , randomEngine_(std::random_device{}())
        , randomDist_(0.0f, 1.0f) {
        
        // Initialize grain pool
        grains_.resize(128);  // Pool of 128 grains
    }
    
    void setSampleRate(float sampleRate) {
        sampleRate_ = sampleRate;
    }
    
    void setBuffer(const std::vector<float>& buffer) {
        sourceBuffer_ = buffer;
    }
    
    void clearBuffer() {
        sourceBuffer_.clear();
    }
    
    // Process stereo output
    void process(float& left, float& right) {
        left = 0.0f;
        right = 0.0f;
        
        if (sourceBuffer_.empty()) return;
        
        // Check if it's time to trigger a new grain
        float framesBetweenGrains = sampleRate_ / grainRate_;
        if (framesSinceLastGrain_ >= framesBetweenGrains) {
            triggerNewGrain();
            framesSinceLastGrain_ = 0;
        }
        framesSinceLastGrain_++;
        
        // Process all active grains
        for (auto& grain : grains_) {
            if (grain.isActive()) {
                float grainSample = grain.process(sourceBuffer_, sampleRate_);
                
                // Apply stereo panning
                float pan = grain.getPan();
                float leftGain = std::sqrt(0.5f * (1.0f - pan));
                float rightGain = std::sqrt(0.5f * (1.0f + pan));
                
                left += grainSample * leftGain;
                right += grainSample * rightGain;
            }
        }
        
        // Apply master amplitude
        left *= amplitude_;
        right *= amplitude_;
    }
    
    // Granular parameters
    void setGrainRate(float rate) { grainRate_ = std::max(0.1f, std::min(100.0f, rate)); }
    void setGrainDuration(float duration) { grainDuration_ = std::max(0.001f, std::min(1.0f, duration)); }
    void setGrainDurationVariation(float variation) { grainDurationVariation_ = std::max(0.0f, std::min(1.0f, variation)); }
    void setPosition(float pos) { position_ = std::max(0.0f, std::min(1.0f, pos)); }
    void setPositionVariation(float variation) { positionVariation_ = std::max(0.0f, std::min(1.0f, variation)); }
    void setPitch(float pitch) { pitch_ = std::max(0.1f, std::min(4.0f, pitch)); }
    void setPitchVariation(float variation) { pitchVariation_ = std::max(0.0f, std::min(2.0f, variation)); }
    void setAmplitude(float amp) { amplitude_ = std::max(0.0f, std::min(1.0f, amp)); }
    void setPan(float pan) { pan_ = std::max(-1.0f, std::min(1.0f, pan)); }
    void setPanVariation(float variation) { panVariation_ = std::max(0.0f, std::min(1.0f, variation)); }
    void setWindowType(Grain::WindowType type) { windowType_ = type; }
    
    // Getters
    float getGrainRate() const { return grainRate_; }
    float getGrainDuration() const { return grainDuration_; }
    float getPosition() const { return position_; }
    float getPitch() const { return pitch_; }
    float getAmplitude() const { return amplitude_; }
    
private:
    void triggerNewGrain() {
        // Find an inactive grain
        auto it = std::find_if(grains_.begin(), grains_.end(), 
            [](const Grain& g) { return !g.isActive(); });
        
        if (it != grains_.end()) {
            // Calculate grain parameters with variations
            float duration = grainDuration_ + (randomDist_(randomEngine_) - 0.5f) * 2.0f * grainDurationVariation_;
            float pos = position_ + (randomDist_(randomEngine_) - 0.5f) * 2.0f * positionVariation_;
            float pitch = pitch_ + (randomDist_(randomEngine_) - 0.5f) * 2.0f * pitchVariation_;
            float pan = pan_ + (randomDist_(randomEngine_) - 0.5f) * 2.0f * panVariation_;
            
            // Clamp values
            duration = std::max(0.001f, duration);
            pos = std::max(0.0f, std::min(1.0f, pos));
            pitch = std::max(0.1f, pitch);
            pan = std::max(-1.0f, std::min(1.0f, pan));
            
            // Set window type and trigger
            it->setWindowType(windowType_);
            it->trigger(pos, duration, pitch, 1.0f, pan);
        }
    }
    
    float sampleRate_;
    std::vector<float> sourceBuffer_;
    std::vector<Grain> grains_;
    
    // Granular parameters
    float grainRate_;           // Grains per second
    float grainDuration_;       // Base grain duration in seconds
    float grainDurationVariation_;
    float position_;            // Position in source buffer (0-1)
    float positionVariation_;
    float pitch_;               // Base pitch shift
    float pitchVariation_;
    float amplitude_;           // Master amplitude
    float pan_;                 // Base pan position
    float panVariation_;
    Grain::WindowType windowType_;
    
    // Timing
    size_t framesSinceLastGrain_;
    
    // Random number generation
    std::mt19937 randomEngine_;
    std::uniform_real_distribution<float> randomDist_;
};

} // namespace synth