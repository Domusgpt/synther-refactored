import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';
import '../../config/api_config.dart';

/// Web-specific implementation that uses local preset generation
/// instead of API calls for true free functionality
class LlmPresetService {
  // API keys (not used in web version)
  String? _geminiApiKey;
  String? _huggingFaceApiKey;
  
  // Current API type
  ApiType _apiType = ApiType.huggingFace;
  
  // Singleton pattern
  static final LlmPresetService _instance = LlmPresetService._internal();
  
  factory LlmPresetService() {
    return _instance;
  }
  
  LlmPresetService._internal();
  
  /// Initialize the service
  Future<void> initialize() async {
    debugPrint('[LLM Web] Service initialized with local generation');
  }
  
  /// Set the API key for the specified API type
  void setApiKey(ApiType type, String apiKey) {
    // Not used in web version
    debugPrint('[LLM Web] API keys not used in web version');
  }
  
  /// Get the current API key for the specified API type
  String? getApiKey(ApiType type) {
    // Not used in web version
    return null;
  }
  
  /// Set the current API type
  void setApiType(ApiType type) {
    _apiType = type;
    debugPrint('[LLM Web] API type set to: $type (using local generation)');
  }
  
  /// Get the current API type
  ApiType get apiType => _apiType;
  
  /// Generate a preset based on the description
  Future<SynthParametersModel?> generatePreset(String description) async {
    debugPrint('[LLM Web] Generating preset locally for: $description');
    
    try {
      // Use local rule-based generation
      final preset = _generateLocalPreset(description);
      debugPrint('[LLM Web] Generated preset: $preset');
      
      return _parsePresetJson(preset);
    } catch (e, stackTrace) {
      debugPrint('[LLM Web] Error generating preset: $e');
      debugPrint('[LLM Web] Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Generate preset using local rules
  Map<String, dynamic> _generateLocalPreset(String description) {
    final random = Random();
    final desc = description.toLowerCase();
    
    // Default preset
    var preset = {
      "name": "Generated Preset",
      "description": description,
      "masterVolume": 0.7,
      "filterCutoff": 5000.0,
      "filterResonance": 0.3,
      "filterType": 0,
      "reverbMix": 0.2,
      "delayTime": 0.25,
      "delayFeedback": 0.3,
      "oscillators": [
        {
          "type": 3, // sawtooth
          "frequency": 440.0,
          "volume": 0.5,
          "detune": 0.0
        }
      ],
      "envelope": {
        "attackTime": 0.01,
        "decayTime": 0.1,
        "sustainLevel": 0.7,
        "releaseTime": 0.5
      }
    };
    
    // Apply rules based on description keywords
    if (desc.contains('bass') || desc.contains('sub')) {
      preset['filterCutoff'] = 200.0;
      preset['filterResonance'] = 0.7;
      (preset['oscillators'] as List)[0]['type'] = 0; // sine
      (preset['oscillators'] as List)[0]['frequency'] = 110.0;
    } else if (desc.contains('lead') || desc.contains('melody')) {
      preset['filterCutoff'] = 8000.0;
      preset['filterResonance'] = 0.5;
      (preset['oscillators'] as List)[0]['type'] = 2; // square
      preset['reverbMix'] = 0.3;
    } else if (desc.contains('pad') || desc.contains('ambient')) {
      (preset['envelope'] as Map)['attackTime'] = 0.5;
      (preset['envelope'] as Map)['releaseTime'] = 2.0;
      preset['reverbMix'] = 0.6;
      (preset['oscillators'] as List)[0]['type'] = 1; // triangle
    } else if (desc.contains('pluck') || desc.contains('string')) {
      (preset['envelope'] as Map)['attackTime'] = 0.001;
      (preset['envelope'] as Map)['decayTime'] = 0.3;
      (preset['envelope'] as Map)['sustainLevel'] = 0.3;
      preset['filterCutoff'] = 3000.0;
    }
    
    // Add some randomization
    preset['filterCutoff'] = (preset['filterCutoff'] as double) * (0.8 + random.nextDouble() * 0.4);
    preset['reverbMix'] = (preset['reverbMix'] as double) * (0.8 + random.nextDouble() * 0.4);
    
    return preset;
  }
  
  /// Parse the preset JSON and create a SynthParametersModel
  SynthParametersModel? _parsePresetJson(Map<String, dynamic> presetJson) {
    try {
      final model = SynthParametersModel();
      
      // Parse master parameters
      if (presetJson['masterVolume'] != null) {
        model.setMasterVolume(presetJson['masterVolume'].toDouble());
      }
      
      // Parse filter parameters
      if (presetJson['filterCutoff'] != null) {
        model.setFilterCutoff(presetJson['filterCutoff'].toDouble());
      }
      if (presetJson['filterResonance'] != null) {
        model.setFilterResonance(presetJson['filterResonance'].toDouble());
      }
      
      // Parse effects
      if (presetJson['reverbMix'] != null) {
        model.setReverbMix(presetJson['reverbMix'].toDouble());
      }
      if (presetJson['delayTime'] != null) {
        model.setDelayTime(presetJson['delayTime'].toDouble());
      }
      if (presetJson['delayFeedback'] != null) {
        model.setDelayFeedback(presetJson['delayFeedback'].toDouble());
      }
      
      // Parse envelope
      if (presetJson['envelope'] != null) {
        final env = presetJson['envelope'];
        if (env['attackTime'] != null) {
          model.setAttackTime(env['attackTime'].toDouble());
        }
        if (env['decayTime'] != null) {
          model.setDecayTime(env['decayTime'].toDouble());
        }
        if (env['sustainLevel'] != null) {
          model.setSustainLevel(env['sustainLevel'].toDouble());
        }
        if (env['releaseTime'] != null) {
          model.setReleaseTime(env['releaseTime'].toDouble());
        }
      }
      
      return model;
    } catch (e) {
      debugPrint('[LLM Web] Error parsing preset JSON: $e');
      return null;
    }
  }
  
  /// Check if API key is set (not used in web version)
  bool isApiKeySet(ApiType type) {
    return true; // Always return true for web version
  }
  
  /// Clear API keys (not used in web version)
  void clearApiKeys() {
    // No-op for web version
  }
}