# CMakeLists for Synther Holographic Pro
# Fallback implementation for professional audio engine

cmake_minimum_required(VERSION 3.22.1)

project("synth_engine_professional")

# Fallback audio implementation
add_library(synth_engine_professional SHARED
    synth_engine_fallback.cpp
)

# Configure library
target_compile_definitions(synth_engine_professional PRIVATE
    ANDROID_STL=c++_shared
)

target_compile_options(synth_engine_professional PRIVATE
    -std=c++17
    -Wall
    -Wextra
    -O3
)

# Link libraries
find_library(log-lib log)
find_library(android-lib android)

target_link_libraries(synth_engine_professional
    ${log-lib}
    ${android-lib}
)