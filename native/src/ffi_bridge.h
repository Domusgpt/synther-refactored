#ifndef FFI_BRIDGE_H
#define FFI_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

// Required for FFI to identify exported functions
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

/**
 * Initialize the synth engine.
 * 
 * @param sampleRate The sample rate to use (e.g., 44100, 48000)
 * @param bufferSize The buffer size to use
 * @param initialVolume The initial master volume (0.0 - 1.0)
 * @return 0 on success, non-zero error code on failure
 */
EXPORT int InitializeSynthEngine(int sampleRate, int bufferSize, float initialVolume);

/**
 * Shut down the synth engine and clean up resources.
 */
EXPORT void ShutdownSynthEngine();

/**
 * Process a MIDI event.
 * 
 * @param status The MIDI status byte
 * @param data1 The first MIDI data byte
 * @param data2 The second MIDI data byte
 * @return 0 on success, non-zero error code on failure
 */
EXPORT int ProcessMidiEvent(unsigned char status, unsigned char data1, unsigned char data2);

/**
 * Set a parameter value.
 * 
 * @param parameterId The ID of the parameter to set
 * @param value The new value for the parameter
 * @return 0 on success, non-zero error code on failure
 */
EXPORT int SetParameter(int parameterId, float value);

/**
 * Get a parameter value.
 * 
 * @param parameterId The ID of the parameter to get
 * @return The parameter value
 */
EXPORT float GetParameter(int parameterId);

/**
 * Trigger a note-on event.
 * 
 * @param note The MIDI note number (0-127)
 * @param velocity The note velocity (0-127)
 * @return 0 on success, non-zero error code on failure
 */
EXPORT int NoteOn(int note, int velocity);

/**
 * Trigger a note-off event.
 * 
 * @param note The MIDI note number (0-127)
 * @return 0 on success, non-zero error code on failure
 */
EXPORT int NoteOff(int note);

/**
 * Load audio buffer into granular synthesizer.
 * 
 * @param buffer Pointer to audio data
 * @param length Number of samples in the buffer
 * @return 0 on success, non-zero error code on failure
 */
EXPORT int LoadGranularBuffer(const float* buffer, int length);

/**
 * Audio analysis functions for visualization.
 */
EXPORT double GetBassLevel();
EXPORT double GetMidLevel();
EXPORT double GetHighLevel();
EXPORT double GetAmplitudeLevel();
EXPORT double GetDominantFrequency();

#ifdef __cplusplus
}
#endif

#endif // FFI_BRIDGE_H