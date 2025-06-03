#include "include/synth_engine_api.h"
#include <iostream>
#include <thread>
#include <chrono>

int main() {
    std::cout << "Testing Synther Audio Engine..." << std::endl;
    
    // Initialize the engine
    int result = InitializeSynthEngine(44100, 512, 0.5f);
    if (result != 0) {
        std::cerr << "Failed to initialize synthesizer engine!" << std::endl;
        return 1;
    }
    
    std::cout << "Engine initialized successfully." << std::endl;
    
    // Test parameter setting
    result = SetParameter(SYNTH_PARAM_MASTER_VOLUME, 0.8f);
    if (result != 0) {
        std::cerr << "Failed to set master volume!" << std::endl;
    } else {
        std::cout << "Master volume set to 0.8" << std::endl;
    }
    
    // Test note on/off
    std::cout << "Playing note C4 (60) for 2 seconds..." << std::endl;
    result = NoteOn(60, 127);  // C4, max velocity
    if (result != 0) {
        std::cerr << "Failed to trigger note on!" << std::endl;
    } else {
        std::cout << "Note on successful." << std::endl;
    }
    
    // Hold note for 2 seconds
    std::this_thread::sleep_for(std::chrono::seconds(2));
    
    // Note off
    result = NoteOff(60);
    if (result != 0) {
        std::cerr << "Failed to trigger note off!" << std::endl;
    } else {
        std::cout << "Note off successful." << std::endl;
    }
    
    // Hold for envelope to release
    std::this_thread::sleep_for(std::chrono::seconds(1));
    
    // Shutdown
    ShutdownSynthEngine();
    std::cout << "Engine shut down successfully." << std::endl;
    
    std::cout << "Audio test completed!" << std::endl;
    return 0;
}