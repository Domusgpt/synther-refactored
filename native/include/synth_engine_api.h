#ifndef SYNTH_ENGINE_API_H
#define SYNTH_ENGINE_API_H

#ifdef __cplusplus
extern "C" {
#endif

// Export macros for cross-platform compatibility
#ifdef _WIN32
#define SYNTH_API __declspec(dllexport)
#else
#define SYNTH_API __attribute__((visibility("default"))) __attribute__((used))
#endif

/**
 * Synther Audio Engine - Public FFI API
 * 
 * This header defines the C API for the Synther audio engine,
 * designed for use with Flutter FFI bindings.
 */

// Engine lifecycle
SYNTH_API int InitializeSynthEngine(int sampleRate, int bufferSize, float initialVolume);
SYNTH_API void ShutdownSynthEngine();

// Note control
SYNTH_API int NoteOn(int note, int velocity);
SYNTH_API int NoteOff(int note);
SYNTH_API int ProcessMidiEvent(unsigned char status, unsigned char data1, unsigned char data2);

// Parameter control
SYNTH_API int SetParameter(int parameterId, float value);
SYNTH_API float GetParameter(int parameterId);

// Granular synthesis
SYNTH_API int LoadGranularBuffer(const float* buffer, int length);

// Audio analysis for visualization
SYNTH_API double GetBassLevel();
SYNTH_API double GetMidLevel();
SYNTH_API double GetHighLevel();
SYNTH_API double GetAmplitudeLevel();
SYNTH_API double GetDominantFrequency();

// Parameter IDs (must match Dart parameter_definitions.dart)
#define SYNTH_PARAM_MASTER_VOLUME        0
#define SYNTH_PARAM_MASTER_MUTE          1
#define SYNTH_PARAM_FILTER_CUTOFF        10
#define SYNTH_PARAM_FILTER_RESONANCE     11
#define SYNTH_PARAM_FILTER_TYPE          12
#define SYNTH_PARAM_ATTACK_TIME          20
#define SYNTH_PARAM_DECAY_TIME           21
#define SYNTH_PARAM_SUSTAIN_LEVEL        22
#define SYNTH_PARAM_RELEASE_TIME         23
#define SYNTH_PARAM_REVERB_MIX           30
#define SYNTH_PARAM_DELAY_TIME           31
#define SYNTH_PARAM_DELAY_FEEDBACK       32
#define SYNTH_PARAM_GRANULAR_ACTIVE      40
#define SYNTH_PARAM_GRANULAR_GRAIN_RATE  41
#define SYNTH_PARAM_GRANULAR_GRAIN_DURATION 42
#define SYNTH_PARAM_GRANULAR_POSITION    43
#define SYNTH_PARAM_GRANULAR_PITCH       44
#define SYNTH_PARAM_GRANULAR_AMPLITUDE   45

#ifdef __cplusplus
}
#endif

#endif // SYNTH_ENGINE_API_H