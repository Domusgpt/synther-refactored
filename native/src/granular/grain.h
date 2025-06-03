#pragma once
#include <vector>
#include <memory>
#include <cmath>

namespace synth {

/// Represents a single grain of sound
class Grain {
public:
    enum class WindowType {
        Hann,
        Gaussian,
        Triangular,
        Tukey
    };
    
    Grain() 
        : position_(0.0f)
        , length_(0.05f)  // 50ms default
        , pitch_(1.0f)
        , amplitude_(1.0f)
        , pan_(0.0f)
        , windowType_(WindowType::Hann)
        , isActive_(false)
        , currentFrame_(0) {
    }
    
    // Initialize the grain with parameters
    void trigger(float position, float length, float pitch, float amplitude, float pan) {
        position_ = position;
        length_ = length;
        pitch_ = pitch;
        amplitude_ = amplitude;
        pan_ = pan;
        currentFrame_ = 0;
        isActive_ = true;
    }
    
    // Process one sample of the grain
    float process(const std::vector<float>& buffer, float sampleRate) {
        if (!isActive_ || buffer.empty()) return 0.0f;
        
        // Calculate position in the buffer
        float bufferPos = position_ * buffer.size() + currentFrame_ * pitch_;
        
        // Check if grain has finished
        float grainProgress = currentFrame_ / (length_ * sampleRate);
        if (grainProgress >= 1.0f || bufferPos >= buffer.size()) {
            isActive_ = false;
            return 0.0f;
        }
        
        // Interpolate sample from buffer
        size_t index0 = static_cast<size_t>(bufferPos);
        size_t index1 = (index0 + 1) % buffer.size();
        float fraction = bufferPos - index0;
        
        float sample = buffer[index0] * (1.0f - fraction) + buffer[index1] * fraction;
        
        // Apply window
        float window = getWindowValue(grainProgress);
        sample *= window * amplitude_;
        
        currentFrame_++;
        return sample;
    }
    
    bool isActive() const { return isActive_; }
    float getPan() const { return pan_; }
    
    void setWindowType(WindowType type) { windowType_ = type; }
    
private:
    float getWindowValue(float progress) const {
        switch (windowType_) {
            case WindowType::Hann:
                return 0.5f * (1.0f - std::cos(2.0f * M_PI * progress));
                
            case WindowType::Gaussian: {
                float alpha = 2.5f;  // Width parameter
                float x = (progress - 0.5f) * 2.0f;
                return std::exp(-0.5f * alpha * x * x);
            }
            
            case WindowType::Triangular:
                return progress < 0.5f ? 2.0f * progress : 2.0f * (1.0f - progress);
                
            case WindowType::Tukey: {
                float taperRatio = 0.1f;
                if (progress < taperRatio / 2) {
                    return 0.5f * (1.0f + std::cos(M_PI * (2.0f * progress / taperRatio - 1.0f)));
                } else if (progress > 1.0f - taperRatio / 2) {
                    return 0.5f * (1.0f + std::cos(M_PI * (2.0f * progress - 2.0f / taperRatio + 1.0f)));
                } else {
                    return 1.0f;
                }
            }
            
            default:
                return 1.0f;
        }
    }
    
    float position_;      // Position in the source buffer (0-1)
    float length_;        // Grain length in seconds
    float pitch_;         // Pitch shift factor
    float amplitude_;     // Grain amplitude
    float pan_;          // Stereo pan (-1 to 1)
    WindowType windowType_;
    bool isActive_;
    size_t currentFrame_;
};

} // namespace synth