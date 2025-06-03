import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';

/// Service for generating synthesizer presets using Together AI's free tier
class TogetherAIService {
  // Together AI offers $25 free credit which is enough for testing
  static const String apiEndpoint = 'https://api.together.xyz/inference';
  
  // Free models available on Together AI
  static const String defaultModel = 'togethercomputer/RedPajama-INCITE-Base-3B-v1';
  
  // Alternative free models
  static const List<String> freeModels = [
    'togethercomputer/RedPajama-INCITE-Base-3B-v1',
    'togethercomputer/RedPajama-INCITE-Chat-3B-v1',
    'togethercomputer/GPT-NeoXT-Chat-Base-20B',
  ];
  
  String? _apiKey;
  
  void initialize({String? apiKey}) {
    _apiKey = apiKey;
  }
  
  bool get isInitialized => _apiKey == null || _apiKey!.isEmpty;
  
  Future<Map<String, dynamic>> generatePreset(String description) async {
    try {
      // Create an optimized prompt for the model
      final prompt = _createPrompt(description);
      
      final requestBody = {
        'model': defaultModel,
        'prompt': prompt,
        'max_tokens': 200,
        'temperature': 0.5,
        'top_p': 0.9,
        'stop': ['}'],
      };
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Only add auth if API key is provided
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_apiKey';
      }
      
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['output']['choices'][0]['text'];
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[^}]*\}').firstMatch(text);
        if (jsonMatch != null) {
          try {
            return jsonDecode(jsonMatch.group(0)!);
          } catch (e) {
            debugPrint('Failed to parse JSON: $e');
          }
        }
      }
      
      // Fallback to rule-based generation
      return _generateFallbackPreset(description);
      
    } catch (e) {
      debugPrint('Together AI error: $e');
      return _generateFallbackPreset(description);
    }
  }
  
  String _createPrompt(String description) {
    return '''
Generate a synthesizer preset as a JSON object for the following description: "$description"

Examples:
Description: "warm pad"
JSON: {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "reverb_mix": 0.6}

Description: "bright lead"
JSON: {"frequency": 880, "oscillator_type": 1, "filter_cutoff": 3000, "attack": 0.01}

Description: "$description"
JSON:''';
  }
  
  Map<String, dynamic> _generateFallbackPreset(String description) {
    // Simple rule-based fallback
    return {
      'preset_name': 'Generated Preset',
      'parameters': {
        'oscillators': [{
          'type': 0,
          'frequency': 440.0,
          'volume': 0.8,
        }],
        'filter': {
          'cutoff': 1000.0,
          'resonance': 0.5,
          'type': 0,
        },
        'envelope': {
          'attack': 0.1,
          'decay': 0.2,
          'sustain': 0.7,
          'release': 0.5,
        },
        'effects': {
          'reverb_mix': 0.3,
          'delay_time': 0.25,
          'delay_feedback': 0.3,
        }
      }
    };
  }
}