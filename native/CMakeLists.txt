cmake_minimum_required(VERSION 3.16)
project(SynthEngine VERSION 0.1.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Define source files
set(SOURCE_FILES
    src/ffi_bridge.cpp
    src/synth_engine.cpp
    src/audio_platform/audio_platform.cpp
    src/audio_platform/audio_platform_rtaudio.cpp
)

# Set include directories
include_directories(src)
include_directories(src/synthesis)
include_directories(src/wavetable)
include_directories(src/audio_platform)
include_directories(include)

# Find or download RTAudio
option(USE_SYSTEM_RTAUDIO "Use system-installed RTAudio" OFF)

if(USE_SYSTEM_RTAUDIO)
    find_package(RTAudio REQUIRED)
else()
    # Add RTAudio as a subproject
    include(FetchContent)
    FetchContent_Declare(
        rtaudio
        GIT_REPOSITORY https://github.com/thestk/rtaudio.git
        GIT_TAG master  # Or specify a specific tag/commit
    )
    set(RTAUDIO_BUILD_TESTING OFF CACHE BOOL "Build RTAudio tests")
    set(RTAUDIO_API_ALSA OFF CACHE BOOL "Build ALSA API")
    set(RTAUDIO_API_PULSE OFF CACHE BOOL "Build PulseAudio API")
    set(RTAUDIO_API_JACK OFF CACHE BOOL "Build JACK API")
    FetchContent_MakeAvailable(rtaudio)
endif()

# Platform-specific settings
if(ANDROID)
    # Android settings
    add_library(synthengine SHARED ${SOURCE_FILES})
    set_target_properties(synthengine PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../android/app/src/main/jniLibs/${ANDROID_ABI}")
elseif(IOS)
    # iOS settings
    add_library(synthengine STATIC ${SOURCE_FILES})
    set_target_properties(synthengine PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.domusgpt.soundsynthesizer
        MACOSX_FRAMEWORK_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    )
elseif(APPLE)
    # macOS settings
    add_library(synthengine SHARED ${SOURCE_FILES})
    set_target_properties(synthengine PROPERTIES
        INSTALL_RPATH "@executable_path/../Frameworks"
        BUILD_WITH_INSTALL_NAME_DIR ON
        INSTALL_NAME_DIR "@rpath"
    )
elseif(WIN32)
    # Windows settings
    add_library(synthengine SHARED ${SOURCE_FILES})
    set_target_properties(synthengine PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
else()
    # Linux and others
    add_library(synthengine SHARED ${SOURCE_FILES})
endif()

# Link with necessary libraries
if(USE_SYSTEM_RTAUDIO)
    target_link_libraries(synthengine PRIVATE RTAudio::rtaudio)
else()
    target_link_libraries(synthengine PRIVATE rtaudio)
endif()

# Audio API-specific dependencies
if(APPLE)
    # CoreAudio on macOS
    target_link_libraries(synthengine PRIVATE "-framework CoreAudio" "-framework CoreFoundation")
elseif(WIN32)
    # WASAPI/DirectSound on Windows
    target_link_libraries(synthengine PRIVATE winmm ole32)
elseif(UNIX AND NOT ANDROID)
    # ALSA/PulseAudio/JACK on Linux
    find_package(ALSA)
    if(ALSA_FOUND)
        target_link_libraries(synthengine PRIVATE ${ALSA_LIBRARIES})
    endif()
    
    # Optional: PulseAudio
    find_package(PulseAudio)
    if(PulseAudio_FOUND)
        target_link_libraries(synthengine PRIVATE ${PULSEAUDIO_LIBRARIES})
    endif()
endif()

# Install rules
install(TARGETS synthengine
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        FRAMEWORK DESTINATION lib
        RUNTIME DESTINATION bin)

# Export all symbols for the shared library
set_target_properties(synthengine PROPERTIES
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN 1
)

# Compile definitions
target_compile_definitions(synthengine PRIVATE
    $<$<CONFIG:Debug>:DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
)

# Set optimization flags for Release build
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    if(MSVC)
        target_compile_options(synthengine PRIVATE /O2)
    else()
        target_compile_options(synthengine PRIVATE -O3)
    endif()
endif()

# Enable warnings
if(MSVC)
    target_compile_options(synthengine PRIVATE /W4)
else()
    target_compile_options(synthengine PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Print some information
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Output directory: ${CMAKE_BINARY_DIR}")