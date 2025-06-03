import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';
import '../../config/api_config.dart';

/// Unified LLM service that supports multiple providers
class UnifiedLLMService {
  // Singleton pattern
  static final UnifiedLLMService _instance = UnifiedLLMService._internal();
  
  factory UnifiedLLMService() {
    return _instance;
  }
  
  UnifiedLLMService._internal();
  
  // Provider types
  enum Provider {
    cloudflare,
    replicate,
    groq,
    local,
  }
  
  Provider _currentProvider = Provider.local;
  String? _apiKey;
  String? _accountId;
  
  void initialize({Provider? provider, String? apiKey, String? accountId}) {
    if (provider != null) {
      _currentProvider = provider;
    }
    _apiKey = apiKey;
    _accountId = accountId;
  }
  
  bool get isInitialized {
    switch (_currentProvider) {
      case Provider.cloudflare:
        return _apiKey != null && _accountId != null;
      case Provider.replicate:
      case Provider.groq:
        return _apiKey != null;
      case Provider.local:
        return true; // Always ready
    }
  }
  
  Future<SynthParametersModel?> generatePreset(String description) async {
    debugPrint('[Unified LLM] Generating with provider: $_currentProvider');
    
    try {
      Map<String, dynamic> result;
      
      switch (_currentProvider) {
        case Provider.cloudflare:
          result = await _generateWithCloudflare(description);
          break;
        case Provider.replicate:
          result = await _generateWithReplicate(description);
          break;
        case Provider.groq:
          result = await _generateWithGroq(description);
          break;
        case Provider.local:
        default:
          result = _generateLocalPreset(description);
          break;
      }
      
      return _parseToSynthParameters(result);
      
    } catch (e) {
      debugPrint('[Unified LLM] Error: $e');
      // Fallback to local generation
      final fallback = _generateLocalPreset(description);
      return _parseToSynthParameters(fallback);
    }
  }
  
  /// Generate with Groq (offers free tier)
  Future<Map<String, dynamic>> _generateWithGroq(String description) async {
    final url = 'https://api.groq.com/openai/v1/chat/completions';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'mixtral-8x7b-32768',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a synthesizer preset generator. Generate only valid JSON.'
          },
          {
            'role': 'user', 
            'content': _createPrompt(description)
          }
        ],
        'temperature': 0.3,
        'max_tokens': 256,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      
      // Extract JSON
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
    }
    
    throw Exception('Groq API failed: ${response.body}');
  }
  
  /// Generate with Cloudflare Workers AI
  Future<Map<String, dynamic>> _generateWithCloudflare(String description) async {
    final url = 'https://api.cloudflare.com/client/v4/accounts/$_accountId/ai/run/@cf/meta/llama-2-7b-chat-int8';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prompt': _createPrompt(description),
        'max_tokens': 256,
        'temperature': 0.3,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final output = data['result']['response'];
      
      // Extract JSON
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(output);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
    }
    
    throw Exception('Cloudflare API failed: ${response.body}');
  }
  
  /// Generate with Replicate
  Future<Map<String, dynamic>> _generateWithReplicate(String description) async {
    // Implementation similar to the replicate_service.dart
    throw UnimplementedError('Replicate implementation pending');
  }
  
  /// Local generation (no API needed)
  Map<String, dynamic> _generateLocalPreset(String description) {
    debugPrint('[Local] Generating preset for: $description');
    
    final desc = description.toLowerCase();
    
    // Defaults
    double frequency = 440.0;
    int oscType = 0;
    double filterCutoff = 1000.0;
    double resonance = 0.5;
    double attack = 0.1;
    double reverb = 0.3;
    
    // Analyze description
    if (desc.contains('bass') || desc.contains('sub')) {
      frequency = 110.0;
      oscType = 3; // sawtooth
      filterCutoff = 500.0;
    } else if (desc.contains('lead')) {
      frequency = 660.0;
      oscType = 1; // square
      filterCutoff = 2000.0;
      attack = 0.01;
    } else if (desc.contains('pad')) {
      frequency = 330.0;
      oscType = 2; // triangle
      attack = 0.8;
    }
    
    // Character adjustments
    if (desc.contains('warm')) {
      filterCutoff = 800.0;
      oscType = 2; // triangle
    } else if (desc.contains('bright')) {
      filterCutoff = 3000.0;
      resonance = 0.7;
    } else if (desc.contains('dark')) {
      filterCutoff = 400.0;
    }
    
    // Effects
    if (desc.contains('reverb') || desc.contains('wet')) {
      reverb = 0.7;
    } else if (desc.contains('dry')) {
      reverb = 0.0;
    }
    
    // Envelope
    if (desc.contains('pluck')) {
      attack = 0.001;
    } else if (desc.contains('swell')) {
      attack = 2.0;
    }
    
    return {
      'frequency': frequency,
      'oscillator_type': oscType,
      'filter_cutoff': filterCutoff,
      'resonance': resonance,
      'attack': attack,
      'reverb_mix': reverb,
    };
  }
  
  /// Convert generated data to SynthParametersModel
  SynthParametersModel _parseToSynthParameters(Map<String, dynamic> data) {
    final model = SynthParametersModel();
    
    // Clear existing oscillators
    while (model.oscillators.length > 0) {
      model.removeOscillator(0);
    }
    
    // Add new oscillator with generated parameters
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
  
  String _createPrompt(String description) {
    return '''Generate a JSON object for a synthesizer preset: "$description"

Required fields:
{
  "frequency": 20-20000,
  "oscillator_type": 0-3 (0=sine, 1=square, 2=triangle, 3=sawtooth),
  "filter_cutoff": 20-20000,
  "resonance": 0-1,
  "attack": 0.001-5,
  "reverb_mix": 0-1
}

Example: warm pad = {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "resonance": 0.2, "attack": 0.8, "reverb_mix": 0.6}

JSON for "$description":''';
  }
}