#pragma once
#include "synthesis/oscillator.h"
#include "wavetable_manager.h"

namespace synth {

/// Enhanced oscillator that supports both traditional waveforms and wavetables
class WavetableOscillatorImpl : public Oscillator {
public:
    WavetableOscillatorImpl() 
        : Oscillator()
        , wavetableOsc_()
        , wavetableManager_(nullptr)
        , currentWavetableName_("Basic Shapes")
        , wavetablePosition_(0.0f) {
    }
    
    void setWavetableManager(WavetableManager* manager) {
        wavetableManager_ = manager;
        selectWavetable(currentWavetableName_);
    }
    
    void selectWavetable(const std::string& tableName) {
        if (wavetableManager_) {
            const Wavetable* table = wavetableManager_->getWavetable(tableName);
            if (table) {
                wavetableOsc_.setWavetable(table);
                currentWavetableName_ = tableName;
            }
        }
    }
    
    void setWavetablePosition(float position) {
        wavetablePosition_ = position;
        wavetableOsc_.setTablePosition(position);
    }
    
    float getWavetablePosition() const {
        return wavetablePosition_;
    }
    
    std::string getCurrentWavetableName() const {
        return currentWavetableName_;
    }
    
    void setSampleRate(int sr) override {
        Oscillator::setSampleRate(sr);
        wavetableOsc_.setSampleRate(static_cast<float>(sr));
    }
    
    void setFrequency(float freq) override {
        Oscillator::setFrequency(freq);
        wavetableOsc_.setFrequency(freq);
    }
    
    void reset() {
        phase = 0.0f;
        wavetableOsc_.reset();
    }
    
protected:
    float processWavetable() override {
        return wavetableOsc_.process();
    }
    
private:
    WavetableOscillator wavetableOsc_;
    WavetableManager* wavetableManager_;
    std::string currentWavetableName_;
    float wavetablePosition_;
};

} // namespace synth