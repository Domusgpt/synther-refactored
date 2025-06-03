import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';

/// Service for generating synthesizer presets using OpenRouter API
/// OpenRouter provides access to multiple models including free options
class OpenRouterService {
  static const String apiEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  
  String? _apiKey;
  
  // Singleton pattern
  static final OpenRouterService _instance = OpenRouterService._internal();
  
  factory OpenRouterService() {
    return _instance;
  }
  
  OpenRouterService._internal();
  
  void initialize({String? apiKey}) {
    _apiKey = apiKey;
  }
  
  bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;
  
  Future<SynthParametersModel?> generatePreset(String description) async {
    // OpenRouter has some free models that don't require API key
    try {
      debugPrint('[OpenRouter] Generating preset for: $description');
      
      final headers = {
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://flutter-synth.web.app',
        'X-Title': 'Flutter Synthesizer',
      };
      
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_apiKey';
      }
      
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: headers,
        body: jsonEncode({
          'model': 'mistralai/mistral-7b-instruct:free', // Free model
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
      
      debugPrint('[OpenRouter] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        debugPrint('[OpenRouter] Generated content: $content');
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          try {
            final preset = jsonDecode(jsonMatch.group(0)!);
            return _parseToSynthParameters(preset);
          } catch (e) {
            debugPrint('[OpenRouter] Failed to parse JSON: $e');
          }
        }
      } else {
        debugPrint('[OpenRouter] Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('[OpenRouter] Exception: $e');
    }
    
    return null;
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
- "warm pad": {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "resonance": 0.2, "attack": 0.8, "decay": 0.3, "sustain": 0.8, "release": 2.0, "reverb_mix": 0.6, "delay_time": 0.3, "delay_feedback": 0.2}
- "bright lead": {"frequency": 880, "oscillator_type": 1, "filter_cutoff": 3000, "resonance": 0.5, "attack": 0.01, "decay": 0.1, "sustain": 0.5, "release": 0.3, "reverb_mix": 0.2, "delay_time": 0.1, "delay_feedback": 0.1}

Generate JSON for: "$description"
Respond with ONLY the JSON object, no explanation.''';
  }
  
  SynthParametersModel _parseToSynthParameters(Map<String, dynamic> data) {
    final model = SynthParametersModel();
    
    // Clear existing oscillators
    while (model.oscillators.length > 0) {
      model.removeOscillator(0);
    }
    
    // Add new oscillator
    model.addOscillator();
    model.updateOscillator(
      0,
      OscillatorParameters(
        type: _parseOscillatorType(data['oscillator_type'] ?? 0),
        frequency: (data['frequency'] ?? 440).toDouble(),
        detune: 0.0,
        volume: 0.8,
        pan: 0.0,
        wavetableIndex: 0,
        wavetablePosition: 0.5,
      ),
    );
    
    // Set filter
    model.setFilterCutoff((data['filter_cutoff'] ?? 1000).toDouble());
    model.setFilterResonance((data['resonance'] ?? 0.5).toDouble());
    
    // Set envelope
    model.setAttackTime((data['attack'] ?? 0.1).toDouble());
    model.setDecayTime((data['decay'] ?? 0.2).toDouble());
    model.setSustainLevel((data['sustain'] ?? 0.7).toDouble());
    model.setReleaseTime((data['release'] ?? 0.5).toDouble());
    
    // Set effects
    model.setReverbMix((data['reverb_mix'] ?? 0.3).toDouble());
    model.setDelayTime((data['delay_time'] ?? 0.25).toDouble());
    model.setDelayFeedback((data['delay_feedback'] ?? 0.3).toDouble());
    
    return model;
  }
  
  OscillatorType _parseOscillatorType(dynamic value) {
    final intValue = (value as num?)?.toInt() ?? 0;
    if (intValue >= 0 && intValue < OscillatorType.values.length) {
      return OscillatorType.values[intValue];
    }
    return OscillatorType.sine;
  }
}