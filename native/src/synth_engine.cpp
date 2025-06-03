#include "synth_engine.h"
#include "synthesis/oscillator.h"
#include "synthesis/filter.h"
#include "synthesis/envelope.h"
#include "synthesis/delay.h"
#include "synthesis/reverb.h"
#include "audio_platform/audio_platform.h"
#include "wavetable/wavetable_manager.h"
#include "wavetable/wavetable_oscillator_impl.h"
#include "granular/granular_synth.h"
#include <cmath>
#include <iostream>

// SynthEngine implementation
SynthEngine& SynthEngine::getInstance() {
    static SynthEngine instance;
    return instance;
}

SynthEngine::SynthEngine() : initialized(false), sampleRate(44100), bufferSize(512),
                           masterVolume(0.75f), masterMute(false), audioPlatform(nullptr) {
    // Full initialization happens in initialize()
}

SynthEngine::~SynthEngine() {
    shutdown();
}

bool SynthEngine::initialize(int sr, int bs, float initialVolume) {
    if (initialized) {
        return true; // Already initialized
    }
    
    try {
        sampleRate = sr;
        bufferSize = bs;
        masterVolume = initialVolume;
        
        // Initialize wavetable manager
        wavetableManager = std::make_unique<synth::WavetableManager>();
        
        // Initialize granular synth
        granularSynth = std::make_unique<synth::GranularSynthesizer>();
        granularSynth->setSampleRate(sampleRate);
        
        // Initialize modules
        initializeDefaultModules();
        
        // Create audio platform
        audioPlatform = AudioPlatform::createForCurrentPlatform();
        
        // Set up audio callback
        auto callback = [this](float* buffer, int numFrames, int numChannels) {
            this->processAudio(buffer, numFrames, numChannels);
        };
        
        // Initialize audio platform
        if (!audioPlatform->initialize(sampleRate, bufferSize, 2, callback)) {
            std::cerr << "Failed to initialize audio platform: " 
                      << audioPlatform->getLastError() << std::endl;
            return false;
        }
        
        // Start audio processing
        if (!audioPlatform->start()) {
            std::cerr << "Failed to start audio processing: " 
                      << audioPlatform->getLastError() << std::endl;
            return false;
        }
        
        initialized = true;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::initialize: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::initialize" << std::endl;
        return false;
    }
}

void SynthEngine::shutdown() {
    if (!initialized) {
        return;
    }
    
    // Stop audio processing
    if (audioPlatform) {
        audioPlatform->stop();
    }
    
    // Clean up all modules
    oscillators.clear();
    filter.reset();
    envelope.reset();
    delay.reset();
    reverb.reset();
    wavetableManager.reset();
    granularSynth.reset();
    
    // Clear audio platform
    audioPlatform.reset();
    
    // Clear active notes
    {
        std::lock_guard<std::mutex> lock(notesMutex);
        activeNotes.clear();
    }
    
    // Clear parameter cache
    {
        std::lock_guard<std::mutex> lock(parameterMutex);
        parameterCache.clear();
    }
    
    initialized = false;
}

void SynthEngine::processAudio(float* outputBuffer, int numFrames, int numChannels) {
    if (!initialized || masterMute) {
        // Clear the output buffer if engine is not initialized or muted
        for (int i = 0; i < numFrames * numChannels; ++i) {
            outputBuffer[i] = 0.0f;
        }
        return;
    }
    
    // Process audio for each frame
    for (int frame = 0; frame < numFrames; ++frame) {
        float sampleLeft = 0.0f;
        float sampleRight = 0.0f;
        
        // Process all oscillators
        for (auto& osc : oscillators) {
            float oscSample = osc->process();
            
            // Apply envelope
            if (envelope && envelope->isActive()) {
                oscSample *= envelope->process();
            }
            
            // Apply filter
            if (filter) {
                oscSample = filter->process(oscSample);
            }
            
            // Add to output (simple stereo panning would go here)
            sampleLeft += oscSample;
            sampleRight += oscSample;
        }
        
        // Add granular synthesis if active
        if (granularSynth) {
            float granLeft = 0.0f, granRight = 0.0f;
            granularSynth->process(granLeft, granRight);
            sampleLeft += granLeft;
            sampleRight += granRight;
        }
        
        // Apply effects
        if (delay) {
            sampleLeft = delay->process(sampleLeft);
            sampleRight = delay->process(sampleRight);
        }
        
        if (reverb) {
            sampleLeft = reverb->process(sampleLeft);
            sampleRight = reverb->process(sampleRight);
        }
        
        // Apply master volume
        sampleLeft *= masterVolume;
        sampleRight *= masterVolume;
        
        // Write to output buffer
        if (numChannels == 1) {
            // Mono output
            outputBuffer[frame] = (sampleLeft + sampleRight) * 0.5f;
        } else {
            // Stereo output
            outputBuffer[frame * numChannels] = sampleLeft;
            outputBuffer[frame * numChannels + 1] = sampleRight;
        }
    }
    
    // Update audio analysis
    updateAudioAnalysis(outputBuffer, numFrames, numChannels);
}

bool SynthEngine::noteOn(int note, int velocity) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Normalize velocity to 0.0-1.0
        float normalizedVelocity = static_cast<float>(velocity) / 127.0f;
        
        // Set oscillator frequencies based on MIDI note
        float frequency = noteToFrequency(note);
        for (auto& osc : oscillators) {
            osc->setFrequency(frequency);
        }
        
        // Trigger envelope
        if (envelope) {
            envelope->noteOn(normalizedVelocity);
        }
        
        // Track active note
        {
            std::lock_guard<std::mutex> lock(notesMutex);
            activeNotes[note] = normalizedVelocity;
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::noteOn: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::noteOn" << std::endl;
        return false;
    }
}

bool SynthEngine::noteOff(int note) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Check if this note is active
        bool noteWasActive = false;
        {
            std::lock_guard<std::mutex> lock(notesMutex);
            auto it = activeNotes.find(note);
            if (it != activeNotes.end()) {
                activeNotes.erase(it);
                noteWasActive = true;
            }
        }
        
        if (noteWasActive) {
            // If there are no more active notes, trigger envelope release
            bool anyNotesActive = false;
            {
                std::lock_guard<std::mutex> lock(notesMutex);
                anyNotesActive = !activeNotes.empty();
            }
            
            if (!anyNotesActive && envelope) {
                envelope->noteOff();
            }
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::noteOff: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::noteOff" << std::endl;
        return false;
    }
}

bool SynthEngine::processMidiEvent(unsigned char status, unsigned char data1, unsigned char data2) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Basic MIDI message parsing
        unsigned char messageType = status & 0xF0; // Top 4 bits = message type
        unsigned char channel = status & 0x0F;     // Bottom 4 bits = channel
        
        switch (messageType) {
            case 0x90: // Note On
                if (data2 > 0) {
                    return noteOn(data1, data2);
                } else {
                    // Note On with velocity 0 is equivalent to Note Off
                    return noteOff(data1);
                }
                
            case 0x80: // Note Off
                return noteOff(data1);
                
            case 0xB0: // Control Change
                // Handle various MIDI CC messages
                switch (data1) {
                    case 7: // Volume
                        return setParameter(SynthParameterId::masterVolume, data2 / 127.0f);
                    case 1: // Modulation wheel - map to filter cutoff
                        return setParameter(SynthParameterId::filterCutoff, 
                                           20.0f + (data2 / 127.0f) * 19980.0f); // 20Hz to 20kHz
                    default:
                        // Unhandled CC
                        return false;
                }
                
            default:
                // Unhandled MIDI message type
                return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::processMidiEvent: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::processMidiEvent" << std::endl;
        return false;
    }
}

bool SynthEngine::setParameter(int parameterId, float value) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Update parameter cache
        {
            std::lock_guard<std::mutex> lock(parameterMutex);
            parameterCache[parameterId] = value;
        }
        
        // Handle parameter based on ID
        switch (parameterId) {
            // Master parameters
            case SynthParameterId::masterVolume:
                masterVolume = value;
                return true;
                
            case SynthParameterId::masterMute:
                masterMute = (value >= 0.5f);
                return true;
                
            // Filter parameters
            case SynthParameterId::filterCutoff:
                if (filter) {
                    filter->setCutoff(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::filterResonance:
                if (filter) {
                    filter->setResonance(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::filterType:
                if (filter) {
                    filter->setType(static_cast<int>(value));
                    return true;
                }
                return false;
                
            // Envelope parameters
            case SynthParameterId::attackTime:
                if (envelope) {
                    envelope->setAttack(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::decayTime:
                if (envelope) {
                    envelope->setDecay(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::sustainLevel:
                if (envelope) {
                    envelope->setSustain(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::releaseTime:
                if (envelope) {
                    envelope->setRelease(value);
                    return true;
                }
                return false;
                
            // Effect parameters
            case SynthParameterId::reverbMix:
                if (reverb) {
                    reverb->setMix(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::delayTime:
                if (delay) {
                    delay->setTime(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::delayFeedback:
                if (delay) {
                    delay->setFeedback(value);
                    return true;
                }
                return false;
                
            // Granular parameters
            case SynthParameterId::granularGrainRate:
                if (granularSynth) {
                    granularSynth->setGrainRate(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularGrainDuration:
                if (granularSynth) {
                    granularSynth->setGrainDuration(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPosition:
                if (granularSynth) {
                    granularSynth->setPosition(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPitch:
                if (granularSynth) {
                    granularSynth->setPitch(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularAmplitude:
                if (granularSynth) {
                    granularSynth->setAmplitude(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPositionVar:
                if (granularSynth) {
                    granularSynth->setPositionVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPitchVar:
                if (granularSynth) {
                    granularSynth->setPitchVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularDurationVar:
                if (granularSynth) {
                    granularSynth->setGrainDurationVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPan:
                if (granularSynth) {
                    granularSynth->setPan(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPanVar:
                if (granularSynth) {
                    granularSynth->setPanVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularWindowType:
                if (granularSynth) {
                    granularSynth->setWindowType(static_cast<synth::Grain::WindowType>(static_cast<int>(value)));
                    return true;
                }
                return false;
                
            default:
                // Check if this is an oscillator parameter
                if (parameterId >= SynthParameterId::oscillatorType && parameterId < SynthParameterId::oscillatorType + 1000) {
                    int oscIndex = (parameterId - SynthParameterId::oscillatorType) / 10;
                    int paramOffset = (parameterId - SynthParameterId::oscillatorType) % 10;
                    
                    if (oscIndex >= 0 && oscIndex < oscillators.size()) {
                        switch (paramOffset) {
                            case 0: // Type
                                oscillators[oscIndex]->setType(static_cast<int>(value));
                                return true;
                            case 1: // Frequency
                                oscillators[oscIndex]->setFrequency(value);
                                return true;
                            case 2: // Detune
                                oscillators[oscIndex]->setDetune(value);
                                return true;
                            case 3: // Volume
                                oscillators[oscIndex]->setVolume(value);
                                return true;
                            case 4: // Pan
                                oscillators[oscIndex]->setPan(value);
                                return true;
                            case 5: // Wavetable Index
                                if (auto wtOsc = dynamic_cast<synth::WavetableOscillatorImpl*>(oscillators[oscIndex].get())) {
                                    auto tableNames = wavetableManager->getTableNames();
                                    int tableIndex = static_cast<int>(value);
                                    if (tableIndex >= 0 && tableIndex < tableNames.size()) {
                                        wtOsc->selectWavetable(tableNames[tableIndex]);
                                    }
                                }
                                return true;
                            case 6: // Wavetable Position
                                if (auto wtOsc = dynamic_cast<synth::WavetableOscillatorImpl*>(oscillators[oscIndex].get())) {
                                    wtOsc->setWavetablePosition(value);
                                }
                                return true;
                            default:
                                return false;
                        }
                    }
                }
                
                // Unhandled parameter ID
                return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::setParameter: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::setParameter" << std::endl;
        return false;
    }
}

float SynthEngine::getParameter(int parameterId) {
    if (!initialized) {
        return 0.0f;
    }
    
    try {
        // Check cache first
        {
            std::lock_guard<std::mutex> lock(parameterMutex);
            auto it = parameterCache.find(parameterId);
            if (it != parameterCache.end()) {
                return it->second;
            }
        }
        
        // If not in cache, get the parameter directly
        switch (parameterId) {
            // Master parameters
            case SynthParameterId::masterVolume:
                return masterVolume;
                
            case SynthParameterId::masterMute:
                return masterMute ? 1.0f : 0.0f;
                
            // Filter parameters
            case SynthParameterId::filterCutoff:
                return filter ? static_cast<float>(filter->getCutoff()) : 1000.0f;
                
            case SynthParameterId::filterResonance:
                return filter ? filter->getResonance() : 0.5f;
                
            // Add other parameter getters as needed
                
            default:
                return 0.0f; // Unhandled parameter ID
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::getParameter: " << e.what() << std::endl;
        return 0.0f;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::getParameter" << std::endl;
        return 0.0f;
    }
}

void SynthEngine::initializeDefaultModules() {
    // Create default oscillators with wavetable support
    oscillators.clear();
    auto osc = std::make_unique<synth::WavetableOscillatorImpl>();
    osc->setSampleRate(sampleRate);
    osc->setType(static_cast<int>(Oscillator::WaveformType::Sine));
    osc->setVolume(0.5f);
    osc->setWavetableManager(wavetableManager.get());
    oscillators.push_back(std::move(osc));
    
    // Add a second oscillator
    auto osc2 = std::make_unique<synth::WavetableOscillatorImpl>();
    osc2->setSampleRate(sampleRate);
    osc2->setType(static_cast<int>(Oscillator::WaveformType::Square));
    osc2->setVolume(0.3f);
    osc2->setDetune(5.0f); // Slight detune for width
    osc2->setWavetableManager(wavetableManager.get());
    oscillators.push_back(std::move(osc2));
    
    // Create filter
    filter = std::make_unique<Filter>();
    filter->setSampleRate(sampleRate);
    filter->setCutoff(1000.0f);
    filter->setResonance(0.5f);
    filter->setType(static_cast<int>(Filter::FilterType::LowPass));
    
    // Create envelope
    envelope = std::make_unique<Envelope>();
    envelope->setSampleRate(sampleRate);
    envelope->setAttack(0.01f);
    envelope->setDecay(0.1f);
    envelope->setSustain(0.7f);
    envelope->setRelease(0.5f);
    
    // Create effects
    delay = std::make_unique<Delay>();
    delay->setSampleRate(sampleRate);
    delay->setTime(0.5f);
    delay->setFeedback(0.3f);
    delay->setMix(0.2f);
    
    reverb = std::make_unique<Reverb>();
    reverb->setSampleRate(sampleRate);
    reverb->setRoomSize(0.5f);
    reverb->setDamping(0.5f);
    reverb->setMix(0.2f);
}

float SynthEngine::noteToFrequency(int note) const {
    // A4 = MIDI note 69 = 440 Hz
    return 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

bool SynthEngine::loadGranularBuffer(const std::vector<float>& buffer) {
    if (!initialized || !granularSynth) {
        return false;
    }
    
    try {
        granularSynth->setBuffer(buffer);
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::loadGranularBuffer: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::loadGranularBuffer" << std::endl;
        return false;
    }
}

// Audio analysis functions for visualization
double SynthEngine::getBassLevel() const {
    return bassLevel.load();
}

double SynthEngine::getMidLevel() const {
    return midLevel.load();
}

double SynthEngine::getHighLevel() const {
    return highLevel.load();
}

double SynthEngine::getAmplitudeLevel() const {
    return amplitudeLevel.load();
}

double SynthEngine::getDominantFrequency() const {
    return dominantFrequency.load();
}

void SynthEngine::updateAudioAnalysis(const float* buffer, int numFrames, int numChannels) {
    if (!buffer || numFrames <= 0) {
        return;
    }
    
    // Simple frequency band analysis using basic filtering
    double bassSum = 0.0, midSum = 0.0, highSum = 0.0, totalSum = 0.0;
    double maxAmplitude = 0.0;
    
    // Process samples (mix down to mono if stereo)
    for (int frame = 0; frame < numFrames; ++frame) {
        float sample = 0.0f;
        if (numChannels == 1) {
            sample = buffer[frame];
        } else {
            // Mix stereo to mono
            sample = (buffer[frame * numChannels] + buffer[frame * numChannels + 1]) * 0.5f;
        }
        
        float absSample = std::abs(sample);
        totalSum += absSample;
        maxAmplitude = std::max(maxAmplitude, static_cast<double>(absSample));
        
        // Simple frequency band separation using sample analysis
        // This is a simplified approach - in practice, you'd use FFT
        
        // Bass: Low frequency emphasis (slower changes)
        bassFilterState = bassFilterState * 0.95f + sample * 0.05f;
        bassSum += std::abs(bassFilterState);
        
        // Mid: Medium frequency emphasis
        midFilterState = midFilterState * 0.8f + sample * 0.2f;
        midSum += std::abs(midFilterState);
        
        // High: High frequency emphasis (faster changes)
        float highPass = sample - (midFilterState * 0.7f);
        highFilterState = highFilterState * 0.3f + highPass * 0.7f;
        highSum += std::abs(highFilterState);
    }
    
    // Normalize and update atomic values
    if (numFrames > 0) {
        bassLevel.store(bassSum / numFrames);
        midLevel.store(midSum / numFrames);
        highLevel.store(highSum / numFrames);
        amplitudeLevel.store(maxAmplitude);
        
        // Simple dominant frequency estimation based on which band is strongest
        double maxBand = std::max({bassSum, midSum, highSum});
        if (maxBand == bassSum) {
            dominantFrequency.store(100.0); // Approximate bass frequency
        } else if (maxBand == midSum) {
            dominantFrequency.store(1000.0); // Approximate mid frequency
        } else {
            dominantFrequency.store(5000.0); // Approximate high frequency
        }
    }
}