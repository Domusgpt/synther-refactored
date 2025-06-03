#pragma once
#include <vector>
#include <string>
#include <cmath>

namespace synth {

/// A single wavetable frame/cycle
struct WaveFrame {
    std::vector<float> samples;
    
    WaveFrame(size_t size = 2048) : samples(size, 0.0f) {}
    
    float getSample(float phase) const {
        if (samples.empty()) return 0.0f;
        
        // Linear interpolation between samples
        float indexFloat = phase * (samples.size() - 1);
        size_t index0 = static_cast<size_t>(indexFloat);
        size_t index1 = (index0 + 1) % samples.size();
        float fraction = indexFloat - index0;
        
        return samples[index0] * (1.0f - fraction) + samples[index1] * fraction;
    }
};

/// A collection of wave frames that can be morphed between
class Wavetable {
public:
    Wavetable(const std::string& name = "Default") : name_(name) {}
    
    // Add a wave frame to the table
    void addFrame(const WaveFrame& frame) {
        frames_.push_back(frame);
    }
    
    // Get interpolated sample from the wavetable
    float getSample(float phase, float position) const {
        if (frames_.empty()) return 0.0f;
        
        // Position determines which frames to interpolate between
        float frameIndex = position * (frames_.size() - 1);
        size_t frame0 = static_cast<size_t>(frameIndex);
        size_t frame1 = (frame0 + 1) % frames_.size();
        float frameFraction = frameIndex - frame0;
        
        // Get samples from both frames
        float sample0 = frames_[frame0].getSample(phase);
        float sample1 = frames_[frame1].getSample(phase);
        
        // Interpolate between frames
        return sample0 * (1.0f - frameFraction) + sample1 * frameFraction;
    }
    
    // Factory methods for common wavetables
    static Wavetable createBasicShapes() {
        Wavetable table("Basic Shapes");
        const size_t frameSize = 2048;
        
        // Sine wave
        WaveFrame sineFrame(frameSize);
        for (size_t i = 0; i < frameSize; ++i) {
            float phase = static_cast<float>(i) / frameSize;
            sineFrame.samples[i] = std::sin(2.0f * M_PI * phase);
        }
        table.addFrame(sineFrame);
        
        // Triangle wave
        WaveFrame triangleFrame(frameSize);
        for (size_t i = 0; i < frameSize; ++i) {
            float phase = static_cast<float>(i) / frameSize;
            triangleFrame.samples[i] = 2.0f * std::abs(2.0f * (phase - 0.5f)) - 1.0f;
        }
        table.addFrame(triangleFrame);
        
        // Square wave (band-limited)
        WaveFrame squareFrame(frameSize);
        for (size_t i = 0; i < frameSize; ++i) {
            float phase = static_cast<float>(i) / frameSize;
            float square = 0.0f;
            // Band-limited square using additive synthesis
            for (int harmonic = 1; harmonic <= 15; harmonic += 2) {
                square += (1.0f / harmonic) * std::sin(2.0f * M_PI * harmonic * phase);
            }
            squareFrame.samples[i] = square * (4.0f / M_PI);
        }
        table.addFrame(squareFrame);
        
        // Saw wave (band-limited)
        WaveFrame sawFrame(frameSize);
        for (size_t i = 0; i < frameSize; ++i) {
            float phase = static_cast<float>(i) / frameSize;
            float saw = 0.0f;
            // Band-limited saw using additive synthesis
            for (int harmonic = 1; harmonic <= 20; harmonic++) {
                saw += (1.0f / harmonic) * std::sin(2.0f * M_PI * harmonic * phase);
            }
            sawFrame.samples[i] = saw * (2.0f / M_PI);
        }
        table.addFrame(sawFrame);
        
        return table;
    }
    
    static Wavetable createPWM() {
        Wavetable table("PWM");
        const size_t frameSize = 2048;
        const int numFrames = 32;
        
        for (int frame = 0; frame < numFrames; ++frame) {
            WaveFrame pwmFrame(frameSize);
            float pulseWidth = static_cast<float>(frame) / (numFrames - 1);
            
            for (size_t i = 0; i < frameSize; ++i) {
                float phase = static_cast<float>(i) / frameSize;
                pwmFrame.samples[i] = (phase < pulseWidth) ? 1.0f : -1.0f;
            }
            table.addFrame(pwmFrame);
        }
        
        return table;
    }
    
    const std::string& getName() const { return name_; }
    size_t getFrameCount() const { return frames_.size(); }
    
private:
    std::string name_;
    std::vector<WaveFrame> frames_;
};

/// Wavetable oscillator class
class WavetableOscillator {
public:
    WavetableOscillator() 
        : phase_(0.0f)
        , phaseIncrement_(0.0f)
        , frequency_(440.0f)
        , sampleRate_(44100.0f)
        , tablePosition_(0.0f)
        , currentTable_(nullptr) {
        updatePhaseIncrement();
    }
    
    void setSampleRate(float sampleRate) {
        sampleRate_ = sampleRate;
        updatePhaseIncrement();
    }
    
    void setFrequency(float frequency) {
        frequency_ = frequency;
        updatePhaseIncrement();
    }
    
    void setWavetable(const Wavetable* table) {
        currentTable_ = table;
    }
    
    void setTablePosition(float position) {
        tablePosition_ = std::clamp(position, 0.0f, 1.0f);
    }
    
    float process() {
        if (!currentTable_) return 0.0f;
        
        float sample = currentTable_->getSample(phase_, tablePosition_);
        
        // Update phase
        phase_ += phaseIncrement_;
        if (phase_ >= 1.0f) {
            phase_ -= 1.0f;
        }
        
        return sample;
    }
    
    void reset() {
        phase_ = 0.0f;
    }
    
private:
    void updatePhaseIncrement() {
        phaseIncrement_ = frequency_ / sampleRate_;
    }
    
    float phase_;
    float phaseIncrement_;
    float frequency_;
    float sampleRate_;
    float tablePosition_;
    const Wavetable* currentTable_;
};

} // namespace synth