import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';

/// Service for generating synthesizer presets using Mistral AI
class MistralService {
  static const String apiEndpoint = 'https://api.mistral.ai/v1/chat/completions';
  
  String? _apiKey;
  
  void initialize({String? apiKey}) {
    _apiKey = apiKey;
  }
  
  bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;
  
  Future<Map<String, dynamic>> generatePreset(String description) async {
    if (!isInitialized) {
      throw Exception('Mistral API key not set');
    }
    
    try {
      debugPrint('[Mistral] Generating preset for: $description');
      
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mistral-tiny', // or 'mistral-small' for better results
          'messages': [
            {
              'role': 'system',
              'content': 'You are a synthesizer preset generator. Always respond with valid JSON only, no extra text.'
            },
            {
              'role': 'user',
              'content': _createPrompt(description)
            }
          ],
          'temperature': 0.3,
          'max_tokens': 300,
        }),
      );
      
      debugPrint('[Mistral] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        debugPrint('[Mistral] Generated content: $content');
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          try {
            return jsonDecode(jsonMatch.group(0)!);
          } catch (e) {
            debugPrint('[Mistral] Failed to parse JSON: $e');
          }
        }
      } else {
        debugPrint('[Mistral] Error: ${response.body}');
        throw Exception('Mistral API error: ${response.statusCode}');
      }
      
      // Fallback
      return _generateFallbackPreset(description);
      
    } catch (e) {
      debugPrint('[Mistral] Exception: $e');
      return _generateFallbackPreset(description);
    }
  }
  
  String _createPrompt(String description) {
    return '''Generate a synthesizer preset as JSON for: "$description"

Required fields:
{
  "frequency": (20-20000),
  "oscillator_type": (0=sine, 1=square, 2=triangle, 3=sawtooth),
  "filter_cutoff": (20-20000),
  "resonance": (0-1),
  "attack": (0.001-5),
  "decay": (0.001-5),
  "sustain": (0-1),
  "release": (0.001-10),
  "reverb_mix": (0-1),
  "delay_time": (0-2),
  "delay_feedback": (0-0.95)
}

Examples:
- "warm pad": {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "resonance": 0.2, "attack": 0.8, "reverb_mix": 0.6}
- "bright lead": {"frequency": 880, "oscillator_type": 1, "filter_cutoff": 3000, "attack": 0.01}

Generate JSON for: "$description"''';
  }
  
  Map<String, dynamic> _generateFallbackPreset(String description) {
    return {
      'frequency': 440.0,
      'oscillator_type': 0,
      'filter_cutoff': 1000.0,
      'resonance': 0.5,
      'attack': 0.1,
      'decay': 0.2,
      'sustain': 0.7,
      'release': 0.5,
      'reverb_mix': 0.3,
      'delay_time': 0.25,
      'delay_feedback': 0.3,
    };
  }
}