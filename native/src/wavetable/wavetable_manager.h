#pragma once
#include "wavetable.h"
#include <unordered_map>
#include <memory>

namespace synth {

/// Manages a collection of wavetables and provides access to them
class WavetableManager {
public:
    WavetableManager() {
        initializeBuiltinTables();
    }
    
    // Get a wavetable by name
    const Wavetable* getWavetable(const std::string& name) const {
        auto it = tables_.find(name);
        return (it != tables_.end()) ? it->second.get() : nullptr;
    }
    
    // Add a custom wavetable
    void addWavetable(const std::string& name, std::unique_ptr<Wavetable> table) {
        tables_[name] = std::move(table);
    }
    
    // Get list of available wavetable names
    std::vector<std::string> getTableNames() const {
        std::vector<std::string> names;
        names.reserve(tables_.size());
        for (const auto& pair : tables_) {
            names.push_back(pair.first);
        }
        return names;
    }
    
private:
    void initializeBuiltinTables() {
        // Basic waveforms
        tables_["Basic Shapes"] = std::make_unique<Wavetable>(Wavetable::createBasicShapes());
        tables_["PWM"] = std::make_unique<Wavetable>(Wavetable::createPWM());
        
        // Harmonic series
        tables_["Harmonic Series"] = std::make_unique<Wavetable>(createHarmonicSeries());
        
        // Formant wavetable
        tables_["Vocal Formants"] = std::make_unique<Wavetable>(createVocalFormants());
        
        // Bell/Metallic sounds
        tables_["Bell"] = std::make_unique<Wavetable>(createBellTable());
    }
    
    Wavetable createHarmonicSeries() {
        Wavetable table("Harmonic Series");
        const size_t frameSize = 2048;
        const int numFrames = 16;
        
        for (int frame = 0; frame < numFrames; ++frame) {
            WaveFrame harmonicFrame(frameSize);
            int maxHarmonic = frame + 1;
            
            for (size_t i = 0; i < frameSize; ++i) {
                float phase = static_cast<float>(i) / frameSize;
                float sample = 0.0f;
                
                for (int harmonic = 1; harmonic <= maxHarmonic; ++harmonic) {
                    sample += (1.0f / harmonic) * std::sin(2.0f * M_PI * harmonic * phase);
                }
                
                harmonicFrame.samples[i] = sample / maxHarmonic;
            }
            table.addFrame(harmonicFrame);
        }
        
        return table;
    }
    
    Wavetable createVocalFormants() {
        Wavetable table("Vocal Formants");
        const size_t frameSize = 2048;
        
        // Define formant frequencies for different vowels
        struct Formant {
            float f1, f2, f3;  // Formant frequencies
            float a1, a2, a3;  // Formant amplitudes
        };
        
        std::vector<Formant> vowels = {
            {700, 1220, 2600, 1.0f, 0.7f, 0.3f},   // "a"
            {390, 2300, 3000, 1.0f, 0.3f, 0.1f},   // "e"  
            {250, 2020, 2960, 1.0f, 0.5f, 0.2f},   // "i"
            {400, 750, 2400, 1.0f, 0.8f, 0.3f},    // "o"
            {350, 600, 2400, 1.0f, 0.6f, 0.2f}     // "u"
        };
        
        for (const auto& vowel : vowels) {
            WaveFrame formantFrame(frameSize);
            
            for (size_t i = 0; i < frameSize; ++i) {
                float phase = static_cast<float>(i) / frameSize;
                float sample = 0.0f;
                
                // Add formant peaks
                sample += vowel.a1 * std::sin(2.0f * M_PI * (vowel.f1 / 44100.0f) * i);
                sample += vowel.a2 * std::sin(2.0f * M_PI * (vowel.f2 / 44100.0f) * i);
                sample += vowel.a3 * std::sin(2.0f * M_PI * (vowel.f3 / 44100.0f) * i);
                
                formantFrame.samples[i] = sample / 3.0f;
            }
            table.addFrame(formantFrame);
        }
        
        return table;
    }
    
    Wavetable createBellTable() {
        Wavetable table("Bell");
        const size_t frameSize = 2048;
        const int numFrames = 8;
        
        for (int frame = 0; frame < numFrames; ++frame) {
            WaveFrame bellFrame(frameSize);
            float brightness = static_cast<float>(frame) / (numFrames - 1);
            
            for (size_t i = 0; i < frameSize; ++i) {
                float phase = static_cast<float>(i) / frameSize;
                float sample = 0.0f;
                
                // Bell-like spectrum with inharmonic partials
                sample += std::sin(2.0f * M_PI * 1.0f * phase);
                sample += 0.5f * std::sin(2.0f * M_PI * 2.76f * phase);
                sample += 0.3f * std::sin(2.0f * M_PI * 4.07f * phase);
                sample += 0.2f * std::sin(2.0f * M_PI * 5.52f * phase);
                
                // Add more partials based on brightness
                if (brightness > 0.3f) {
                    sample += 0.15f * std::sin(2.0f * M_PI * 6.94f * phase);
                    sample += 0.1f * std::sin(2.0f * M_PI * 8.21f * phase);
                }
                
                bellFrame.samples[i] = sample / 2.0f;
            }
            table.addFrame(bellFrame);
        }
        
        return table;
    }
    
    std::unordered_map<std::string, std::unique_ptr<Wavetable>> tables_;
};

} // namespace synth