package com.domusgpt.synther_holographic_pro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.content.Context
import androidx.annotation.NonNull

class MainActivity : FlutterActivity() {
    private val CHANNEL = "synther_holographic/audio"
    private lateinit var audioHandler: HolographicAudioHandler
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("MainActivity", "🎵 Configuring Holographic Audio Engine...")
        
        // Initialize professional audio handler
        audioHandler = HolographicAudioHandler(this)
        
        // Set up method channel for Flutter communication
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                    val bufferSize = call.argument<Int>("bufferSize") ?: 256
                    val initialVolume = call.argument<Double>("initialVolume")?.toFloat() ?: 0.75f
                    
                    Log.d("MainActivity", "🎵 Initializing with SR:$sampleRate BS:$bufferSize Vol:$initialVolume")
                    
                    val success = audioHandler.initialize(sampleRate, bufferSize, initialVolume)
                    result.success(success)
                }
                
                "noteOn" -> {
                    val note = call.argument<Int>("note") ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing note", null)
                    val velocity = call.argument<Double>("velocity")?.toFloat() ?: 0.8f
                    
                    val success = audioHandler.noteOn(note, velocity)
                    result.success(success)
                }
                
                "noteOff" -> {
                    val note = call.argument<Int>("note") ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing note", null)
                    
                    val success = audioHandler.noteOff(note)
                    result.success(success)
                }
                
                "setMasterVolume" -> {
                    val volume = call.argument<Double>("volume")?.toFloat() ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing volume", null)
                    
                    val success = audioHandler.setMasterVolume(volume)
                    result.success(success)
                }
                
                "setFilterCutoff" -> {
                    val cutoff = call.argument<Double>("cutoff")?.toFloat() ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing cutoff", null)
                    
                    val success = audioHandler.setFilterCutoff(cutoff)
                    result.success(success)
                }
                
                "setFilterResonance" -> {
                    val resonance = call.argument<Double>("resonance")?.toFloat() ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing resonance", null)
                    
                    val success = audioHandler.setFilterResonance(resonance)
                    result.success(success)
                }
                
                "setAttackTime" -> {
                    val attack = call.argument<Double>("attack")?.toFloat() ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing attack", null)
                    
                    val success = audioHandler.setAttackTime(attack)
                    result.success(success)
                }
                
                "setDecayTime" -> {
                    val decay = call.argument<Double>("decay")?.toFloat() ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing decay", null)
                    
                    val success = audioHandler.setDecayTime(decay)
                    result.success(success)
                }
                
                "setReverbMix" -> {
                    val reverb = call.argument<Double>("reverb")?.toFloat() ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing reverb", null)
                    
                    val success = audioHandler.setReverbMix(reverb)
                    result.success(success)
                }
                
                "getVisualizerData" -> {
                    val data = audioHandler.getVisualizerData()
                    result.success(data)
                }
                
                "dispose" -> {
                    audioHandler.dispose()
                    result.success(true)
                }
                
                else -> {
                    Log.w("MainActivity", "⚠️ Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        Log.d("MainActivity", "✅ Holographic Audio Engine configured!")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (::audioHandler.isInitialized) {
            audioHandler.dispose()
        }
    }
}

/**
 * Professional Audio Handler for Holographic Synthesizer
 * Interfaces with the native C++ audio engine
 */
class HolographicAudioHandler(private val context: Context) {
    
    companion object {
        private const val TAG = "HolographicAudioHandler"
        
        init {
            try {
                System.loadLibrary("synth_engine_professional")
                Log.d(TAG, "✅ Professional audio engine loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "❌ Failed to load professional audio engine: ${e.message}")
                Log.e(TAG, "🔧 Falling back to basic audio implementation")
            }
        }
    }
    
    // Native function declarations (Professional C++ Engine)
    private external fun nativeInitialize(sampleRate: Int, bufferSize: Int, initialVolume: Float): Boolean
    private external fun nativeNoteOn(note: Int, velocity: Float): Boolean  
    private external fun nativeNoteOff(note: Int): Boolean
    private external fun nativeSetMasterVolume(volume: Float): Boolean
    private external fun nativeSetFilterCutoff(cutoff: Float): Boolean
    private external fun nativeSetFilterResonance(resonance: Float): Boolean
    private external fun nativeSetAttackTime(attack: Float): Boolean
    private external fun nativeSetDecayTime(decay: Float): Boolean
    private external fun nativeSetReverbMix(reverb: Float): Boolean
    private external fun nativeGetVisualizerData(): Map<String, Any>
    private external fun nativeDispose()
    
    private var isInitialized = false
    
    fun initialize(sampleRate: Int, bufferSize: Int, initialVolume: Float): Boolean {
        return try {
            Log.d(TAG, "🎵 Initializing professional audio engine...")
            val success = nativeInitialize(sampleRate, bufferSize, initialVolume)
            isInitialized = success
            
            if (success) {
                Log.d(TAG, "✅ Professional audio engine initialized successfully")
            } else {
                Log.e(TAG, "❌ Professional audio engine initialization failed")
            }
            
            success
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "❌ Native library not available: ${e.message}")
            false
        } catch (e: Exception) {
            Log.e(TAG, "❌ Audio engine initialization error: ${e.message}")
            false
        }
    }
    
    fun noteOn(note: Int, velocity: Float): Boolean {
        if (!isInitialized) {
            Log.w(TAG, "⚠️ Audio engine not initialized")
            return false
        }
        
        return try {
            nativeNoteOn(note, velocity)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Note on error: ${e.message}")
            false
        }
    }
    
    fun noteOff(note: Int): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeNoteOff(note)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Note off error: ${e.message}")
            false
        }
    }
    
    fun setMasterVolume(volume: Float): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeSetMasterVolume(volume.coerceIn(0f, 1f))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Set master volume error: ${e.message}")
            false
        }
    }
    
    fun setFilterCutoff(cutoff: Float): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeSetFilterCutoff(cutoff.coerceIn(20f, 20000f))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Set filter cutoff error: ${e.message}")
            false
        }
    }
    
    fun setFilterResonance(resonance: Float): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeSetFilterResonance(resonance.coerceIn(0f, 1f))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Set filter resonance error: ${e.message}")
            false
        }
    }
    
    fun setAttackTime(attack: Float): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeSetAttackTime(attack.coerceIn(0.001f, 5f))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Set attack time error: ${e.message}")
            false
        }
    }
    
    fun setDecayTime(decay: Float): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeSetDecayTime(decay.coerceIn(0.001f, 5f))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Set decay time error: ${e.message}")
            false
        }
    }
    
    fun setReverbMix(reverb: Float): Boolean {
        if (!isInitialized) return false
        
        return try {
            nativeSetReverbMix(reverb.coerceIn(0f, 1f))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Set reverb mix error: ${e.message}")
            false
        }
    }
    
    fun getVisualizerData(): Map<String, Any> {
        if (!isInitialized) {
            return mapOf(
                "amplitude" to 0.0,
                "frequency" to 440.0,
                "filterCutoff" to 1000.0,
                "filterResonance" to 0.0
            )
        }
        
        return try {
            nativeGetVisualizerData()
        } catch (e: Exception) {
            Log.e(TAG, "❌ Get visualizer data error: ${e.message}")
            mapOf(
                "amplitude" to 0.0,
                "frequency" to 440.0,
                "filterCutoff" to 1000.0,
                "filterResonance" to 0.0
            )
        }
    }
    
    fun dispose() {
        if (isInitialized) {
            try {
                nativeDispose()
                isInitialized = false
                Log.d(TAG, "🎵 Professional audio engine disposed")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Audio engine disposal error: ${e.message}")
            }
        }
    }
}