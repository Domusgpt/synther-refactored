#include "audio_platform.h"
#include "audio_platform_rtaudio.h"

#if defined(__ANDROID__)
// #include "audio_platform_android.h"
#endif

#if defined(__APPLE__)
// For future iOS-specific implementation
// #include "audio_platform_ios.h"
#endif

// Factory method to create a platform-specific audio implementation
std::unique_ptr<AudioPlatform> AudioPlatform::createForCurrentPlatform() {
#if defined(__ANDROID__)
    // Return Android implementation when we have it
    // return std::make_unique<AndroidAudioPlatform>();
    return std::make_unique<RTAudioPlatform>();
#elif defined(__APPLE__) && TARGET_OS_IPHONE
    // Return iOS implementation when we have it
    // return std::make_unique<IOSAudioPlatform>();
    return std::make_unique<RTAudioPlatform>();
#else
    // For desktop platforms (Windows, macOS, Linux), use RTAudio
    return std::make_unique<RTAudioPlatform>();
#endif
}