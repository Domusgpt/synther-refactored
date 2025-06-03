/**
 * Fallback implementation for Synther Holographic Pro
 * 
 * This provides basic stub implementations of the professional audio engine
 * functions to prevent crashes while the full engine is being integrated.
 */

#include <jni.h>
#include <android/log.h>
#include <map>
#include <random>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "SyntherHolographic", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "SyntherHolographic", __VA_ARGS__)

// Audio state
static bool isInitialized = false;
static std::map<int, bool> activeNotes;
static float masterVolume = 0.75f;
static float filterCutoff = 1000.0f;
static float filterResonance = 0.5f;
static float attackTime = 0.01f;
static float decayTime = 0.3f;
static float reverbMix = 0.2f;

// Random generator for simulated data
static std::random_device rd;
static std::mt19937 gen(rd());
static std::uniform_real_distribution<float> dist(0.0f, 1.0f);

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeInitialize(
    JNIEnv *env, jobject thiz, jint sampleRate, jint bufferSize, jfloat initialVolume) {
    
    LOGI("🎵 Fallback audio engine initializing... SR:%d BS:%d Vol:%.2f", 
         sampleRate, bufferSize, initialVolume);
    
    masterVolume = initialVolume;
    isInitialized = true;
    
    LOGI("✅ Fallback audio engine ready (UI testing mode)");
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeNoteOn(
    JNIEnv *env, jobject thiz, jint note, jfloat velocity) {
    
    if (!isInitialized) return JNI_FALSE;
    
    activeNotes[note] = true;
    LOGI("🎵 Note ON: %d (vel: %.2f)", note, velocity);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeNoteOff(
    JNIEnv *env, jobject thiz, jint note) {
    
    if (!isInitialized) return JNI_FALSE;
    
    activeNotes.erase(note);
    LOGI("🎵 Note OFF: %d", note);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeSetMasterVolume(
    JNIEnv *env, jobject thiz, jfloat volume) {
    
    if (!isInitialized) return JNI_FALSE;
    
    masterVolume = volume;
    LOGI("🎵 Master Volume: %.2f", volume);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeSetFilterCutoff(
    JNIEnv *env, jobject thiz, jfloat cutoff) {
    
    if (!isInitialized) return JNI_FALSE;
    
    filterCutoff = cutoff;
    LOGI("🎵 Filter Cutoff: %.1f Hz", cutoff);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeSetFilterResonance(
    JNIEnv *env, jobject thiz, jfloat resonance) {
    
    if (!isInitialized) return JNI_FALSE;
    
    filterResonance = resonance;
    LOGI("🎵 Filter Resonance: %.2f", resonance);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeSetAttackTime(
    JNIEnv *env, jobject thiz, jfloat attack) {
    
    if (!isInitialized) return JNI_FALSE;
    
    attackTime = attack;
    LOGI("🎵 Attack Time: %.3f s", attack);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeSetDecayTime(
    JNIEnv *env, jobject thiz, jfloat decay) {
    
    if (!isInitialized) return JNI_FALSE;
    
    decayTime = decay;
    LOGI("🎵 Decay Time: %.3f s", decay);
    
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeSetReverbMix(
    JNIEnv *env, jobject thiz, jfloat reverb) {
    
    if (!isInitialized) return JNI_FALSE;
    
    reverbMix = reverb;
    LOGI("🎵 Reverb Mix: %.2f", reverb);
    
    return JNI_TRUE;
}

JNIEXPORT jobject JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeGetVisualizerData(
    JNIEnv *env, jobject thiz) {
    
    if (!isInitialized) return nullptr;
    
    // Create HashMap for visualizer data
    jclass hashMapClass = env->FindClass("java/util/HashMap");
    jmethodID hashMapConstructor = env->GetMethodID(hashMapClass, "<init>", "()V");
    jmethodID putMethod = env->GetMethodID(hashMapClass, "put", 
        "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    
    jobject hashMap = env->NewObject(hashMapClass, hashMapConstructor);
    
    // Simulate audio-reactive data
    float amplitude = activeNotes.empty() ? 0.0f : (0.3f + dist(gen) * 0.4f);
    float frequency = 440.0f; // Base frequency
    
    // Convert to Java objects
    jclass doubleClass = env->FindClass("java/lang/Double");
    jmethodID doubleConstructor = env->GetMethodID(doubleClass, "<init>", "(D)V");
    
    auto putDouble = [&](const char* key, double value) {
        jstring keyStr = env->NewStringUTF(key);
        jobject valueObj = env->NewObject(doubleClass, doubleConstructor, value);
        env->CallObjectMethod(hashMap, putMethod, keyStr, valueObj);
        env->DeleteLocalRef(keyStr);
        env->DeleteLocalRef(valueObj);
    };
    
    putDouble("amplitude", amplitude);
    putDouble("frequency", frequency);
    putDouble("filterCutoff", filterCutoff);
    putDouble("filterResonance", filterResonance);
    
    return hashMap;
}

JNIEXPORT void JNICALL
Java_com_domusgpt_synther_1holographic_1pro_HolographicAudioHandler_nativeDispose(
    JNIEnv *env, jobject thiz) {
    
    LOGI("🛑 Fallback audio engine disposing...");
    
    activeNotes.clear();
    isInitialized = false;
    
    LOGI("✅ Fallback audio engine disposed");
}

} // extern "C"