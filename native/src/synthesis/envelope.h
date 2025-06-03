#ifndef ENVELOPE_H
#define ENVELOPE_H

#include <cmath>
#include <algorithm>

/**
 * ADSR (Attack, Decay, Sustain, Release) envelope generator.
 */
class Envelope {
public:
    enum class State {
        Idle,
        Attack,
        Decay,
        Sustain,
        Release
    };
    
    enum class CurveType {
        Linear,
        Exponential,
        Logarithmic,
        SCurve
    };
    
    Envelope() : 
        sampleRate(44100),
        attackTime(0.01f),
        decayTime(0.1f),
        sustainLevel(0.7f),
        releaseTime(0.5f),
        attackCurve(CurveType::Exponential),
        decayCurve(CurveType::Exponential),
        releaseCurve(CurveType::Exponential),
        currentState(State::Idle),
        currentLevel(0.0f),
        currentTime(0.0f),
        releaseLevel(0.0f),
        velocity(1.0f) {
    }
    
    ~Envelope() = default;
    
    /**
     * Trigger the envelope attack phase.
     * 
     * @param vel Velocity value (0.0 - 1.0)
     */
    void noteOn(float vel = 1.0f) {
        currentState = State::Attack;
        currentTime = 0.0f;
        velocity = vel;
        
        // If already have some level (e.g., legato notes), start from there
        // Otherwise, reset to zero
        if (currentLevel <= 0.001f) {
            currentLevel = 0.0f;
        }
    }
    
    /**
     * Trigger the envelope release phase.
     */
    void noteOff() {
        if (currentState != State::Idle) {
            currentState = State::Release;
            releaseLevel = currentLevel;
            currentTime = 0.0f;
        }
    }
    
    /**
     * Process the envelope and get the current value.
     * 
     * @return The current envelope value (0.0 - 1.0)
     */
    float process() {
        float output = 0.0f;
        float samplesPerMs = sampleRate / 1000.0f;
        
        switch (currentState) {
            case State::Attack: {
                // Convert to milliseconds for more precise short attacks
                float attackMs = attackTime * 1000.0f;
                currentTime += 1.0f / samplesPerMs;
                
                if (attackMs <= 0.0f) {
                    // Instant attack
                    currentLevel = 1.0f * velocity;
                    currentState = State::Decay;
                    currentTime = 0.0f;
                } else {
                    // Apply attack curve
                    float attackProgress = currentTime / attackMs;
                    if (attackProgress >= 1.0f) {
                        currentLevel = 1.0f * velocity;
                        currentState = State::Decay;
                        currentTime = 0.0f;
                    } else {
                        currentLevel = applyCurve(attackProgress, attackCurve) * velocity;
                    }
                }
                output = currentLevel;
                break;
            }
                
            case State::Decay: {
                float decayMs = decayTime * 1000.0f;
                currentTime += 1.0f / samplesPerMs;
                
                if (decayMs <= 0.0f) {
                    // Instant decay
                    currentLevel = sustainLevel * velocity;
                    currentState = State::Sustain;
                } else {
                    // Apply decay curve
                    float decayProgress = currentTime / decayMs;
                    if (decayProgress >= 1.0f) {
                        currentLevel = sustainLevel * velocity;
                        currentState = State::Sustain;
                    } else {
                        float decayCurveValue = applyCurve(decayProgress, decayCurve);
                        currentLevel = (1.0f - decayCurveValue * (1.0f - sustainLevel)) * velocity;
                    }
                }
                output = currentLevel;
                break;
            }
                
            case State::Sustain:
                currentLevel = sustainLevel * velocity;
                output = currentLevel;
                break;
                
            case State::Release: {
                float releaseMs = releaseTime * 1000.0f;
                currentTime += 1.0f / samplesPerMs;
                
                if (releaseMs <= 0.0f) {
                    // Instant release
                    currentLevel = 0.0f;
                    currentState = State::Idle;
                } else {
                    // Apply release curve
                    float releaseProgress = currentTime / releaseMs;
                    if (releaseProgress >= 1.0f) {
                        currentLevel = 0.0f;
                        currentState = State::Idle;
                    } else {
                        float releaseCurveValue = applyCurve(releaseProgress, releaseCurve);
                        currentLevel = releaseLevel * (1.0f - releaseCurveValue);
                    }
                }
                output = currentLevel;
                break;
            }
                
            case State::Idle:
            default:
                currentLevel = 0.0f;
                output = 0.0f;
                break;
        }
        
        return output;
    }
    
    /**
     * Set the sample rate.
     * 
     * @param sr The new sample rate
     */
    void setSampleRate(int sr) {
        sampleRate = sr;
    }
    
    /**
     * Set the attack time.
     * 
     * @param time The attack time in seconds
     */
    void setAttack(float time) {
        attackTime = std::max(0.001f, time);
    }
    
    /**
     * Set the decay time.
     * 
     * @param time The decay time in seconds
     */
    void setDecay(float time) {
        decayTime = std::max(0.001f, time);
    }
    
    /**
     * Set the sustain level.
     * 
     * @param level The sustain level (0.0 - 1.0)
     */
    void setSustain(float level) {
        sustainLevel = std::clamp(level, 0.0f, 1.0f);
    }
    
    /**
     * Set the release time.
     * 
     * @param time The release time in seconds
     */
    void setRelease(float time) {
        releaseTime = std::max(0.001f, time);
    }
    
    /**
     * Set the attack curve type.
     * 
     * @param type The curve type
     */
    void setAttackCurve(CurveType type) {
        attackCurve = type;
    }
    
    /**
     * Set the decay curve type.
     * 
     * @param type The curve type
     */
    void setDecayCurve(CurveType type) {
        decayCurve = type;
    }
    
    /**
     * Set the release curve type.
     * 
     * @param type The curve type
     */
    void setReleaseCurve(CurveType type) {
        releaseCurve = type;
    }
    
    /**
     * Check if the envelope is currently active.
     * 
     * @return True if the envelope is active, false otherwise
     */
    bool isActive() const {
        return currentState != State::Idle;
    }
    
    /**
     * Get the current envelope state.
     * 
     * @return The current state
     */
    State getState() const {
        return currentState;
    }
    
private:
    /**
     * Apply a curve function to a linear progress value.
     * 
     * @param value Linear progress (0.0 - 1.0)
     * @param curve The curve type to apply
     * @return The curved value (0.0 - 1.0)
     */
    float applyCurve(float value, CurveType curve) {
        // Ensure value is in [0,1] range
        value = std::clamp(value, 0.0f, 1.0f);
        
        switch (curve) {
            case CurveType::Linear:
                return value;
                
            case CurveType::Exponential:
                // Exponential curve
                return value * value;
                
            case CurveType::Logarithmic:
                // Logarithmic curve (inverse of exponential)
                return std::sqrt(value);
                
            case CurveType::SCurve:
                // Smooth S-curve using sine function
                return (std::sin((value - 0.5f) * M_PI) * 0.5f) + 0.5f;
                
            default:
                return value;
        }
    }
    
    int sampleRate;
    float attackTime;
    float decayTime;
    float sustainLevel;
    float releaseTime;
    CurveType attackCurve;
    CurveType decayCurve;
    CurveType releaseCurve;
    
    State currentState;
    float currentLevel;
    float currentTime;
    float releaseLevel;
    float velocity;
};

#endif // ENVELOPE_H