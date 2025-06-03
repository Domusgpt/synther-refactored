#ifndef FILTER_H
#define FILTER_H

#include <cmath>
#include <algorithm>

/**
 * A multi-mode filter class implementing a state-variable filter.
 * 
 * This filter provides low-pass, high-pass, band-pass, and notch filtering
 * using a state-variable filter architecture.
 */
class Filter {
public:
    enum class FilterType {
        LowPass,
        HighPass,
        BandPass,
        Notch,
        LowShelf,
        HighShelf
    };
    
    Filter() : sampleRate(44100), cutoff(1000.0f), resonance(0.5f),
               type(FilterType::LowPass), lowpass(0.0f), highpass(0.0f),
               bandpass(0.0f), notch(0.0f), peak(0.0f), gain(1.0f) {
        calculateCoefficients();
    }
    
    ~Filter() = default;
    
    /**
     * Process one sample through the filter.
     * 
     * @param input The input sample
     * @return The filtered output sample
     */
    float process(float input) {
        // State variable filter algorithm
        
        // Calculation of state-variable filter components
        lowpass = lowpass + f * bandpass;
        highpass = scale * input - lowpass - q * bandpass;
        bandpass = bandpass + f * highpass;
        notch = highpass + lowpass;
        peak = lowpass - highpass;
        
        // Select output based on filter type
        switch (type) {
            case FilterType::LowPass:
                return lowpass;
            case FilterType::HighPass:
                return highpass;
            case FilterType::BandPass:
                return bandpass;
            case FilterType::Notch:
                return notch;
            case FilterType::LowShelf:
                return input + (lowpass - input) * gain;
            case FilterType::HighShelf:
                return input + (highpass - input) * gain;
            default:
                return lowpass;
        }
    }
    
    /**
     * Set the sample rate.
     * 
     * @param sr The new sample rate
     */
    void setSampleRate(int sr) {
        sampleRate = sr;
        calculateCoefficients();
    }
    
    /**
     * Set the filter cutoff frequency.
     * 
     * @param freq The cutoff frequency in Hz
     */
    void setCutoff(float freq) {
        cutoff = std::clamp(freq, 20.0f, 20000.0f);
        calculateCoefficients();
    }
    
    /**
     * Set the filter resonance.
     * 
     * @param res The resonance (Q) value (0.0 - 1.0)
     */
    void setResonance(float res) {
        resonance = std::clamp(res, 0.0f, 1.0f);
        calculateCoefficients();
    }
    
    /**
     * Set the filter type.
     * 
     * @param t The filter type as integer (cast from FilterType enum)
     */
    void setType(int t) {
        type = static_cast<FilterType>(t);
    }
    
    /**
     * Set the filter gain for shelf filters.
     * 
     * @param g The gain value (0.0 - 10.0)
     */
    void setGain(float g) {
        gain = g;
    }
    
    /**
     * Reset the filter state.
     */
    void reset() {
        lowpass = highpass = bandpass = notch = peak = 0.0f;
    }
    
    /**
     * Get the current cutoff frequency.
     * 
     * @return The cutoff frequency in Hz
     */
    float getCutoff() const {
        return cutoff;
    }
    
    /**
     * Get the current resonance.
     * 
     * @return The resonance value (0.0 - 1.0)
     */
    float getResonance() const {
        return resonance;
    }
    
    /**
     * Get the current filter type.
     * 
     * @return The filter type
     */
    FilterType getType() const {
        return type;
    }
    
    /**
     * Get the current gain for shelf filters.
     * 
     * @return The gain value
     */
    float getGain() const {
        return gain;
    }
    
private:
    /**
     * Calculate filter coefficients based on current settings.
     */
    void calculateCoefficients() {
        // Limit cutoff frequency to Nyquist
        float nyquist = sampleRate * 0.5f;
        float safeFreq = std::min(cutoff, nyquist - 1.0f);
        
        // Calculate normalized frequency [0..1]
        float normalizedFreq = safeFreq / nyquist;
        
        // State variable filter coefficient calculations
        // f = 2.0f * sin(M_PI * normalizedFreq);
        f = 2.0f * std::sin(M_PI * normalizedFreq);
        
        // Resonance (q) calculation with safety limit
        float safeResonance = std::min(resonance, 0.99f);
        q = 1.0f - safeResonance;
        
        // Scale to normalize volume changes with high resonance
        scale = 1.0f / (1.0f + std::sqrt(q));
    }
    
    int sampleRate;
    float cutoff;
    float resonance;
    FilterType type;
    float gain;
    
    // Filter state variables
    float lowpass;
    float highpass;
    float bandpass;
    float notch;
    float peak;
    
    // Filter coefficients
    float f;  // Frequency coefficient
    float q;  // Resonance coefficient
    float scale; // Scale factor
};

#endif // FILTER_H