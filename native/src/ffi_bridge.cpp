#include "ffi_bridge.h"
#include "synth_engine.h"
#include <iostream>

// Implementation of the FFI bridge functions

int InitializeSynthEngine(int sampleRate, int bufferSize, float initialVolume) {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (engine.initialize(sampleRate, bufferSize, initialVolume)) {
            return 0; // Success
        } else {
            return -1; // Failed to initialize
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in InitializeSynthEngine: " << e.what() << std::endl;
        return -2; // Exception occurred
    } catch (...) {
        std::cerr << "Unknown exception in InitializeSynthEngine" << std::endl;
        return -3; // Unknown exception
    }
}

void ShutdownSynthEngine() {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        engine.shutdown();
    } catch (const std::exception& e) {
        std::cerr << "Exception in ShutdownSynthEngine: " << e.what() << std::endl;
    } catch (...) {
        std::cerr << "Unknown exception in ShutdownSynthEngine" << std::endl;
    }
}

int ProcessMidiEvent(unsigned char status, unsigned char data1, unsigned char data2) {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return -1; // Engine not initialized
        }
        
        if (engine.processMidiEvent(status, data1, data2)) {
            return 0; // Success
        } else {
            return -2; // Failed to process event
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in ProcessMidiEvent: " << e.what() << std::endl;
        return -3; // Exception occurred
    } catch (...) {
        std::cerr << "Unknown exception in ProcessMidiEvent" << std::endl;
        return -4; // Unknown exception
    }
}

int SetParameter(int parameterId, float value) {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return -1; // Engine not initialized
        }
        
        if (engine.setParameter(parameterId, value)) {
            return 0; // Success
        } else {
            return -2; // Failed to set parameter
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SetParameter: " << e.what() << std::endl;
        return -3; // Exception occurred
    } catch (...) {
        std::cerr << "Unknown exception in SetParameter" << std::endl;
        return -4; // Unknown exception
    }
}

float GetParameter(int parameterId) {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return 0.0f; // Engine not initialized, return default
        }
        
        return engine.getParameter(parameterId);
    } catch (const std::exception& e) {
        std::cerr << "Exception in GetParameter: " << e.what() << std::endl;
        return 0.0f; // Exception occurred, return default
    } catch (...) {
        std::cerr << "Unknown exception in GetParameter" << std::endl;
        return 0.0f; // Unknown exception, return default
    }
}

int NoteOn(int note, int velocity) {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return -1; // Engine not initialized
        }
        
        if (engine.noteOn(note, velocity)) {
            return 0; // Success
        } else {
            return -2; // Failed to process note-on
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in NoteOn: " << e.what() << std::endl;
        return -3; // Exception occurred
    } catch (...) {
        std::cerr << "Unknown exception in NoteOn" << std::endl;
        return -4; // Unknown exception
    }
}

int NoteOff(int note) {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return -1; // Engine not initialized
        }
        
        if (engine.noteOff(note)) {
            return 0; // Success
        } else {
            return -2; // Failed to process note-off
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in NoteOff: " << e.what() << std::endl;
        return -3; // Exception occurred
    } catch (...) {
        std::cerr << "Unknown exception in NoteOff" << std::endl;
        return -4; // Unknown exception
    }
}

int LoadGranularBuffer(const float* buffer, int length) {
    try {
        if (!buffer || length <= 0) {
            return -1; // Invalid parameters
        }
        
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return -2; // Engine not initialized
        }
        
        // Copy buffer data to a vector
        std::vector<float> audioData(buffer, buffer + length);
        
        // Load into granular synth through engine
        if (engine.loadGranularBuffer(audioData)) {
            return 0; // Success
        } else {
            return -3; // Failed to load buffer
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in LoadGranularBuffer: " << e.what() << std::endl;
        return -4; // Exception occurred
    } catch (...) {
        std::cerr << "Unknown exception in LoadGranularBuffer" << std::endl;
        return -5; // Unknown exception
    }
}

// Audio analysis functions for visualization
double GetBassLevel() {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return 0.0; // Engine not initialized
        }
        return engine.getBassLevel();
    } catch (const std::exception& e) {
        std::cerr << "Exception in GetBassLevel: " << e.what() << std::endl;
        return 0.0;
    } catch (...) {
        std::cerr << "Unknown exception in GetBassLevel" << std::endl;
        return 0.0;
    }
}

double GetMidLevel() {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return 0.0; // Engine not initialized
        }
        return engine.getMidLevel();
    } catch (const std::exception& e) {
        std::cerr << "Exception in GetMidLevel: " << e.what() << std::endl;
        return 0.0;
    } catch (...) {
        std::cerr << "Unknown exception in GetMidLevel" << std::endl;
        return 0.0;
    }
}

double GetHighLevel() {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return 0.0; // Engine not initialized
        }
        return engine.getHighLevel();
    } catch (const std::exception& e) {
        std::cerr << "Exception in GetHighLevel: " << e.what() << std::endl;
        return 0.0;
    } catch (...) {
        std::cerr << "Unknown exception in GetHighLevel" << std::endl;
        return 0.0;
    }
}

double GetAmplitudeLevel() {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return 0.0; // Engine not initialized
        }
        return engine.getAmplitudeLevel();
    } catch (const std::exception& e) {
        std::cerr << "Exception in GetAmplitudeLevel: " << e.what() << std::endl;
        return 0.0;
    } catch (...) {
        std::cerr << "Unknown exception in GetAmplitudeLevel" << std::endl;
        return 0.0;
    }
}

double GetDominantFrequency() {
    try {
        SynthEngine& engine = SynthEngine::getInstance();
        if (!engine.isInitialized()) {
            return 0.0; // Engine not initialized
        }
        return engine.getDominantFrequency();
    } catch (const std::exception& e) {
        std::cerr << "Exception in GetDominantFrequency: " << e.what() << std::endl;
        return 0.0;
    } catch (...) {
        std::cerr << "Unknown exception in GetDominantFrequency" << std::endl;
        return 0.0;
    }
}