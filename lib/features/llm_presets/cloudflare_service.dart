import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';

/// Service for generating synthesizer presets using Cloudflare Workers AI
/// Free tier available with account
class CloudflareAIService {
  // Use the REST API endpoint
  static const String apiEndpoint = 'https://api.cloudflare.com/client/v4/accounts';
  
  String? _accountId;
  String? _apiToken;
  
  void initialize({String? accountId, String? apiToken}) {
    _accountId = accountId;
    _apiToken = apiToken;
  }
  
  bool get isInitialized => _accountId != null && _apiToken != null;
  
  Future<Map<String, dynamic>> generatePreset(String description) async {
    if (!isInitialized) {
      throw Exception('Cloudflare AI not initialized. Need account ID and API token.');
    }
    
    try {
      debugPrint('[Cloudflare AI] Generating preset for: $description');
      
      // Create the prompt
      final prompt = _createPrompt(description);
      
      // Use the Llama 2 7B model (available in free tier)
      final url = '$apiEndpoint/$_accountId/ai/run/@cf/meta/llama-2-7b-chat-int8';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': 256,
          'temperature': 0.3,
        }),
      );
      
      debugPrint('[Cloudflare AI] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final output = data['result']['response'] ?? '';
        
        debugPrint('[Cloudflare AI] Generated output: $output');
        
        // Extract JSON from output
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(output);
        if (jsonMatch != null) {
          try {
            final preset = jsonDecode(jsonMatch.group(0)!);
            return _formatPreset(preset);
          } catch (e) {
            debugPrint('[Cloudflare AI] Failed to parse JSON: $e');
          }
        }
      } else {
        debugPrint('[Cloudflare AI] Error: ${response.body}');
      }
      
      // Fallback to rule-based
      return _generateFallbackPreset(description);
      
    } catch (e) {
      debugPrint('[Cloudflare AI] Exception: $e');
      return _generateFallbackPreset(description);
    }
  }
  
  String _createPrompt(String description) {
    return '''<s>[INST] You are a synthesizer preset generator. Generate a JSON object for this sound: "$description"

The JSON must have exactly these fields:
{
  "frequency": (20-20000),
  "oscillator_type": (0=sine, 1=square, 2=triangle, 3=sawtooth),
  "filter_cutoff": (20-20000),
  "resonance": (0-1),
  "attack": (0.001-5),
  "reverb_mix": (0-1)
}

Example: "warm pad" = {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "resonance": 0.2, "attack": 0.8, "reverb_mix": 0.6}

Generate JSON for "$description", respond with only the JSON object:
[/INST]''';
  }
  
  Map<String, dynamic> _formatPreset(Map<String, dynamic> rawPreset) {
    return {
      'preset_name': 'AI Generated',
      'parameters': {
        'oscillators': [{
          'type': rawPreset['oscillator_type'] ?? 0,
          'frequency': (rawPreset['frequency'] ?? 440).toDouble(),
          'volume': 0.8,
        }],
        'filter': {
          'cutoff': (rawPreset['filter_cutoff'] ?? 1000).toDouble(),
          'resonance': (rawPreset['resonance'] ?? 0.5).toDouble(),
          'type': 0,
        },
        'envelope': {
          'attack': (rawPreset['attack'] ?? 0.1).toDouble(),
          'decay': 0.2,
          'sustain': 0.7,
          'release': 0.5,
        },
        'effects': {
          'reverb_mix': (rawPreset['reverb_mix'] ?? 0.3).toDouble(),
          'delay_time': 0.25,
          'delay_feedback': 0.3,
        }
      }
    };
  }
  
  Map<String, dynamic> _generateFallbackPreset(String description) {
    // Same rule-based fallback
    debugPrint('[Cloudflare AI] Using fallback preset');
    
    final lowerDesc = description.toLowerCase();
    double frequency = 440.0;
    int oscType = 0;
    double filterCutoff = 1000.0;
    double reverb = 0.3;
    double attack = 0.1;
    
    if (lowerDesc.contains('bass')) {
      frequency = 110.0;
      oscType = 3;
    } else if (lowerDesc.contains('pad')) {
      frequency = 330.0;
      attack = 0.8;
    }
    
    if (lowerDesc.contains('warm')) {
      filterCutoff = 800.0;
      oscType = 2;
    } else if (lowerDesc.contains('bright')) {
      filterCutoff = 3000.0;
    }
    
    if (lowerDesc.contains('reverb')) {
      reverb = 0.7;
    }
    
    return _formatPreset({
      'frequency': frequency,
      'oscillator_type': oscType,
      'filter_cutoff': filterCutoff,
      'resonance': 0.5,
      'attack': attack,
      'reverb_mix': reverb,
    });
  }
}