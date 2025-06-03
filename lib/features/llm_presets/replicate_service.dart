import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';

/// Service for generating synthesizer presets using Replicate's free tier
/// Replicate offers $0.50 free credit which is enough for testing
class ReplicateService {
  static const String apiEndpoint = 'https://api.replicate.com/v1/predictions';
  
  // Free model that can generate JSON
  static const String modelVersion = 'meta/llama-2-7b-chat:13c3cdee13ee059ab779f0291d29054dab00a47dad8261375654de5540165fb0';
  
  String? _apiToken;
  
  void initialize({String? apiToken}) {
    _apiToken = apiToken;
  }
  
  bool get isInitialized => _apiToken != null && _apiToken!.isNotEmpty;
  
  Future<Map<String, dynamic>> generatePreset(String description) async {
    if (!isInitialized) {
      throw Exception('Replicate API token not set');
    }
    
    try {
      // Create the prompt
      final prompt = _createPrompt(description);
      
      // Create prediction
      final createResponse = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': modelVersion,
          'input': {
            'prompt': prompt,
            'max_new_tokens': 500,
            'temperature': 0.3,
            'top_p': 0.95,
          }
        }),
      );
      
      if (createResponse.statusCode != 201) {
        throw Exception('Failed to create prediction: ${createResponse.body}');
      }
      
      final prediction = jsonDecode(createResponse.body);
      final predictionId = prediction['id'];
      
      // Poll for result
      String? output;
      int attempts = 0;
      while (attempts < 30) {
        await Future.delayed(Duration(seconds: 1));
        
        final getResponse = await http.get(
          Uri.parse('$apiEndpoint/$predictionId'),
          headers: {
            'Authorization': 'Token $_apiToken',
          },
        );
        
        if (getResponse.statusCode == 200) {
          final result = jsonDecode(getResponse.body);
          
          if (result['status'] == 'succeeded') {
            output = result['output']?.join('') ?? '';
            break;
          } else if (result['status'] == 'failed') {
            throw Exception('Prediction failed');
          }
        }
        
        attempts++;
      }
      
      if (output == null) {
        throw Exception('Timeout waiting for prediction');
      }
      
      // Extract JSON from output
      final jsonMatch = RegExp(r'\{[^}]*\}').firstMatch(output);
      if (jsonMatch != null) {
        try {
          return jsonDecode(jsonMatch.group(0)!);
        } catch (e) {
          debugPrint('Failed to parse JSON: $e');
        }
      }
      
      // Fallback
      return _generateFallbackPreset(description);
      
    } catch (e) {
      debugPrint('Replicate error: $e');
      return _generateFallbackPreset(description);
    }
  }
  
  String _createPrompt(String description) {
    return '''You are a synthesizer preset generator. Generate a JSON object for the following sound description: "$description"

The JSON must include these exact fields:
{
  "frequency": (number between 20-20000),
  "oscillator_type": (0=sine, 1=square, 2=triangle, 3=sawtooth),
  "filter_cutoff": (number between 20-20000),
  "resonance": (number between 0-1),
  "attack": (number between 0.001-5),
  "decay": (number between 0.001-5),
  "sustain": (number between 0-1),
  "release": (number between 0.001-10),
  "reverb_mix": (number between 0-1),
  "delay_time": (number between 0-2),
  "delay_feedback": (number between 0-0.95)
}

Examples:
- "warm pad": {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "attack": 0.8, "reverb_mix": 0.6}
- "bright lead": {"frequency": 880, "oscillator_type": 1, "filter_cutoff": 3000, "attack": 0.01}

Now generate JSON for: "$description"
JSON:''';
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