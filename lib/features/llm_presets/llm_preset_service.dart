import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';
import '../../config/api_config.dart';
import 'groq_service.dart';

/// Service for generating synthesizer presets using LLM APIs (Hugging Face or Gemini)
class LlmPresetService {
  // API keys (for services that require them)
  String? _geminiApiKey;
  String? _huggingFaceApiKey;
  String? _groqApiKey;
  
  // Current API type
  ApiType _apiType = ApiConfig.defaultApiType;
  
  // Groq service instance
  final GroqService _groqService = GroqService();
  
  // Singleton pattern
  static final LlmPresetService _instance = LlmPresetService._internal();
  
  factory LlmPresetService() {
    return _instance;
  }
  
  LlmPresetService._internal() {
    // Set default API keys from config
    _geminiApiKey = ApiConfig.geminiApiKey;
    _huggingFaceApiKey = ApiConfig.huggingFaceApiKey;
  }
  
  /// Initialize the service with API keys
  void initialize({String? geminiApiKey, String? huggingFaceApiKey, String? groqApiKey, ApiType? apiType}) {
    if (geminiApiKey != null) {
      _geminiApiKey = geminiApiKey;
    }
    
    if (huggingFaceApiKey != null) {
      _huggingFaceApiKey = huggingFaceApiKey;
    }
    
    if (groqApiKey != null) {
      _groqService.initialize(apiKey: groqApiKey);
    }
    
    if (apiType != null) {
      _apiType = apiType;
    }
  }
  
  /// Check if the service is initialized properly
  bool get isInitialized {
    switch (_apiType) {
      case ApiType.gemini:
        return _geminiApiKey != null && _geminiApiKey!.isNotEmpty && _geminiApiKey != 'YOUR_GEMINI_API_KEY';
      case ApiType.huggingFace:
        // Hugging Face can work without an API key for some models (with rate limits)
        return true;
      case ApiType.groq:
        // Groq requires API key
        return _groqApiKey != null && _groqApiKey!.isNotEmpty;
    }
  }
  
  /// Set which API to use
  void setApiType(ApiType apiType) {
    _apiType = apiType;
  }
  
  /// Get current API type
  ApiType get apiType => _apiType;
  
  /// Generate a synthesizer preset based on the user's text description
  /// 
  /// [description] is the user's natural language description of the desired sound
  /// Returns a [Future] that completes with a [SynthParametersModel] or null if generation fails
  Future<SynthParametersModel?> generatePreset(String description) async {
    try {
      // Debug logging
      debugPrint('[LLM Service] Generating preset for: "$description"');
      debugPrint('[LLM Service] Current API type: $_apiType');
      
      // Try Hugging Face first if we're not specifically using another API
      if (_apiType == ApiType.huggingFace || _apiType == ApiType.groq) {
        if (_huggingFaceApiKey != null && _huggingFaceApiKey!.isNotEmpty && _huggingFaceApiKey != 'YOUR_HF_TOKEN_HERE') {
          debugPrint('[LLM Service] Trying Hugging Face API first (preferred)...');
          try {
            final hfResult = await _callHuggingFaceApi(_constructPrompt(description));
            final preset = _parseResponse(hfResult);
            debugPrint('[LLM Service] Hugging Face API succeeded');
            return preset;
          } catch (e) {
            debugPrint('[LLM Service] Hugging Face failed: $e');
          }
        }
      }
      
      // Only try Groq as a backup
      if (_groqService.isInitialized && _apiType == ApiType.groq) {
        debugPrint('[LLM Service] Trying Groq API as backup...');
        final groqResult = await _groqService.generatePreset(description);
        if (groqResult != null) {
          debugPrint('[LLM Service] Groq API succeeded');
          return groqResult;
        }
        debugPrint('[LLM Service] Groq API returned null');
      }
      // Try primary API first
      Map<String, dynamic> jsonResponse;
      switch (_apiType) {
        case ApiType.gemini:
          if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty && _geminiApiKey != 'YOUR_GEMINI_API_KEY') {
            final prompt = _constructPrompt(description);
            jsonResponse = await _callGeminiApi(prompt);
            break;
          }
          // Fall through to rule-based if no key
          debugPrint('[LLM Service] No Gemini API key, using rule-based system');
          jsonResponse = _generateRuleBasedPreset(description);
          break;
          
        case ApiType.huggingFace:
          // Check if we have a valid API key
          if (_huggingFaceApiKey != null && _huggingFaceApiKey!.isNotEmpty && _huggingFaceApiKey != 'YOUR_HF_TOKEN_HERE') {
            try {
              debugPrint('[LLM Service] Attempting HF API with key: ${_huggingFaceApiKey!.substring(0, 8)}...');
              final prompt = _constructPrompt(description);
              jsonResponse = await _callHuggingFaceApi(prompt);
              break;
            } catch (e) {
              debugPrint('[LLM Service] Hugging Face API call failed: $e');
              // Check if it's an authentication error
              if (e.toString().contains('401') || e.toString().contains('403')) {
                debugPrint('[LLM Service] Authentication error - please check your Hugging Face API token');
              }
              debugPrint('[LLM Service] Using rule-based fallback');
            }
          } else {
            debugPrint('[LLM Service] No valid HF API key configured');
            if (_huggingFaceApiKey == 'YOUR_HF_TOKEN_HERE') {
              debugPrint('[LLM Service] Please update the API key in api_config.dart');
            }
          }
          // Use rule-based as fallback
          debugPrint('[LLM Service] Using rule-based system as fallback');
          jsonResponse = _generateRuleBasedPreset(description);
          break;
          
        case ApiType.groq:
          // Already tried Groq above, use rule-based
          debugPrint('[LLM Service] Using rule-based system for Groq fallback');
          jsonResponse = _generateRuleBasedPreset(description);
          break;
      }
      
      // Parse the response to extract parameter values
      final preset = _parseResponse(jsonResponse);
      
      return preset;
    } catch (e) {
      debugPrint('Error generating preset: $e');
      // Return a basic preset as fallback
      return _parseResponse(_generateRuleBasedPreset(description));
    }
  }
  
  /// Construct the prompt for the LLM to generate a synthesizer preset
  String _constructPrompt(String userDescription) {
    return '''
Create a synthesizer preset based on this description: "${userDescription}"

I need the result as a JSON object with the following structure (all values should be numbers within the specified ranges):

{
  "preset_name": "Name of the preset",
  "preset_description": "A brief description of how the sound would be characterized",
  "parameters": {
    "oscillators": [
      {
        "type": 0-6 (0:sine, 1:square, 2:triangle, 3:sawtooth, 4:noise, 5:pulse, 6:wavetable),
        "frequency": 20-20000,
        "detune": -100 to 100,
        "volume": 0-1,
        "pan": -1 to 1,
        "wavetableIndex": 0-4 (0:Basic Shapes, 1:PWM, 2:Harmonic Series, 3:Vocal Formants, 4:Bell),
        "wavetablePosition": 0-1
      },
      {
        // Second oscillator (same structure)
      }
    ],
    "filter": {
      "cutoff": 20-20000,
      "resonance": 0-1,
      "type": 0-5 (0:lowPass, 1:highPass, 2:bandPass, 3:notch, 4:lowShelf, 5:highShelf)
    },
    "envelope": {
      "attack": 0.001-5,
      "decay": 0.001-5,
      "sustain": 0-1,
      "release": 0.001-10
    },
    "effects": {
      "reverb_mix": 0-1,
      "delay_time": 0.01-2,
      "delay_feedback": 0-0.95
    }
  }
}

Only respond with the JSON. Do not include any explanations or markdown formatting.
    ''';
  }
  
  /// Call the Gemini API with the constructed prompt
  Future<Map<String, dynamic>> _callGeminiApi(String prompt) async {
    // Prepare the request body
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'topK': 32,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      }
    };
    
    // Make the API call
    final response = await http.post(
      Uri.parse('${ApiConfig.geminiEndpoint}?key=$_geminiApiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Gemini API request failed with status: ${response.statusCode}, body: ${response.body}');
    }
    
    // Parse the response
    final Map<String, dynamic> data = jsonDecode(response.body);
    
    // Extract the generated text (JSON string)
    try {
      final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
      // Parse the generated text as JSON
      return jsonDecode(generatedText);
    } catch (e) {
      throw Exception('Failed to parse Gemini response: $e');
    }
  }
  
  /// Call the Hugging Face API with the constructed prompt
  Future<Map<String, dynamic>> _callHuggingFaceApi(String prompt) async {
    // Use a specific prompt format that works better with GPT-2
    final gpt2Prompt = _createGPT2Prompt(prompt);
    
    // Prepare headers with authentication
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // Add API key if available
    if (_huggingFaceApiKey != null && _huggingFaceApiKey!.isNotEmpty && _huggingFaceApiKey != 'YOUR_HF_TOKEN_HERE') {
      headers['Authorization'] = 'Bearer $_huggingFaceApiKey';
      debugPrint('[HF API] Using authenticated request');
    } else {
      debugPrint('[HF API] Warning: No API key provided');
    }
    
    // Prepare the request body for GPT-2
    final requestBody = {
      'inputs': gpt2Prompt,
      'parameters': {
        'temperature': 0.7,
        'max_new_tokens': 300,
        'return_full_text': false,
      },
      'options': {
        'wait_for_model': true,
      }
    };
    
    // Make the API call
    final response = await http.post(
      Uri.parse(ApiConfig.huggingFaceEndpoint),
      headers: headers,
      body: jsonEncode(requestBody),
    );
    
    debugPrint('Hugging Face API response status: ${response.statusCode}');
    
    if (response.statusCode == 503) {
      // Model is loading, wait and retry
      debugPrint('[HF API] Model is loading, waiting 20 seconds...');
      await Future.delayed(Duration(seconds: 20));
      return _callHuggingFaceApi(prompt);
    }
    
    if (response.statusCode == 401 || response.statusCode == 403) {
      final error = 'Authentication error (${response.statusCode}): ${response.body}';
      debugPrint('[HF API] $error');
      throw Exception(error);
    }
    
    if (response.statusCode != 200) {
      debugPrint('[HF API] Error response (${response.statusCode}): ${response.body}');
      // Parse error message if possible
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? errorData['message'] ?? response.body;
        throw Exception('Hugging Face API error: $errorMessage');
      } catch (e) {
        throw Exception('Hugging Face API request failed with status: ${response.statusCode}');
      }
    }
    
    // Parse the response
    try {
      final data = jsonDecode(response.body);
      String generatedText;
      
      // Handle different response formats
      if (data is List && data.isNotEmpty) {
        generatedText = data[0]['generated_text'] ?? '';
      } else if (data is Map) {
        generatedText = data['generated_text'] ?? data['text'] ?? '';
      } else {
        throw Exception('Unexpected response format');
      }
      
      debugPrint('Generated text: $generatedText');
      
      // Try to extract JSON from the generated text
      // Look for JSON object that might span multiple lines
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', dotAll: true).firstMatch(generatedText);
      if (jsonMatch != null) {
        try {
          final jsonString = jsonMatch.group(0)!;
          debugPrint('Extracted JSON: $jsonString');
          return jsonDecode(jsonString);
        } catch (e) {
          debugPrint('Failed to parse extracted JSON: $e');
        }
      }
      
      // If no JSON found, use the rule-based generator
      debugPrint('No valid JSON found, using rule-based fallback');
      return _generateRuleBasedPreset(prompt);
    } catch (e) {
      debugPrint('Error parsing Hugging Face response: $e');
      debugPrint('Response body: ${response.body}');
      
      // As fallback, create a simple preset with default values
      return {
        'preset_name': 'Fallback Preset',
        'preset_description': 'A simple preset with default values',
        'parameters': {
          'oscillators': [
            {
              'type': 0,  // sine
              'frequency': 440.0,
              'detune': 0.0,
              'volume': 0.8,
              'pan': 0.0,
              'wavetableIndex': 0,
              'wavetablePosition': 0.0
            }
          ],
          'filter': {
            'cutoff': 1000.0,
            'resonance': 0.5,
            'type': 0  // lowpass
          },
          'envelope': {
            'attack': 0.01,
            'decay': 0.1,
            'sustain': 0.7,
            'release': 0.3
          },
          'effects': {
            'reverb_mix': 0.3,
            'delay_time': 0.5,
            'delay_feedback': 0.2
          }
        }
      };
    }
  }
  
  /// Parse the LLM response and create a SynthParametersModel
  SynthParametersModel _parseResponse(Map<String, dynamic> jsonResponse) {
    // Create a new parameters model
    final model = SynthParametersModel();
    
    try {
      final parameters = jsonResponse['parameters'];
      
      // Parse oscillators
      if (parameters['oscillators'] != null) {
        final oscillators = parameters['oscillators'] as List;
        
        // Clear existing oscillators
        while (model.oscillators.length > 0) {
          model.removeOscillator(0);
        }
        
        // Add new oscillators
        for (final osc in oscillators) {
          final oscType = _parseOscillatorType(osc['type']);
          final frequency = osc['frequency']?.toDouble() ?? 440.0;
          final detune = osc['detune']?.toDouble() ?? 0.0;
          final volume = osc['volume']?.toDouble() ?? 0.5;
          final pan = osc['pan']?.toDouble() ?? 0.0;
          final wavetableIndex = osc['wavetableIndex']?.toInt() ?? 0;
          final wavetablePosition = osc['wavetablePosition']?.toDouble() ?? 0.0;
          
          model.addOscillator();
          model.updateOscillator(
            model.oscillators.length - 1,
            OscillatorParameters(
              type: oscType,
              frequency: frequency.clamp(20.0, 20000.0),
              detune: detune.clamp(-100.0, 100.0),
              volume: volume.clamp(0.0, 1.0),
              pan: pan.clamp(-1.0, 1.0),
              wavetableIndex: wavetableIndex.clamp(0, 4),
              wavetablePosition: wavetablePosition.clamp(0.0, 1.0),
            ),
          );
        }
      }
      
      // Parse filter
      if (parameters['filter'] != null) {
        final filter = parameters['filter'];
        model.setFilterCutoff(filter['cutoff']?.toDouble() ?? 1000.0);
        model.setFilterResonance(filter['resonance']?.toDouble() ?? 0.5);
        model.setFilterType(_parseFilterType(filter['type']));
      }
      
      // Parse envelope
      if (parameters['envelope'] != null) {
        final envelope = parameters['envelope'];
        model.setAttackTime(envelope['attack']?.toDouble() ?? 0.01);
        model.setDecayTime(envelope['decay']?.toDouble() ?? 0.1);
        model.setSustainLevel(envelope['sustain']?.toDouble() ?? 0.7);
        model.setReleaseTime(envelope['release']?.toDouble() ?? 0.5);
      }
      
      // Parse effects
      if (parameters['effects'] != null) {
        final effects = parameters['effects'];
        model.setReverbMix(effects['reverb_mix']?.toDouble() ?? 0.2);
        model.setDelayTime(effects['delay_time']?.toDouble() ?? 0.5);
        model.setDelayFeedback(effects['delay_feedback']?.toDouble() ?? 0.3);
      }
      
      return model;
    } catch (e) {
      print('Error parsing LLM response: $e');
      throw Exception('Failed to parse preset parameters: $e');
    }
  }
  
  /// Parse oscillator type from integer
  OscillatorType _parseOscillatorType(dynamic value) {
    final intValue = (value as num?)?.toInt() ?? 0;
    if (intValue >= 0 && intValue < OscillatorType.values.length) {
      return OscillatorType.values[intValue];
    }
    return OscillatorType.sine;
  }
  
  /// Parse filter type from integer
  FilterType _parseFilterType(dynamic value) {
    final intValue = (value as num?)?.toInt() ?? 0;
    if (intValue >= 0 && intValue < FilterType.values.length) {
      return FilterType.values[intValue];
    }
    return FilterType.lowPass;
  }
  
  /// Create a prompt optimized for Mistral models
  String _createGPT2Prompt(String userDescription) {
    // Mistral models work better with clear instructions
    return '''[INST] Generate a JSON object for a synthesizer preset based on this description: "$userDescription"

The JSON must have these exact fields:
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
- "warm pad": {"frequency": 220, "oscillator_type": 2, "filter_cutoff": 800, "resonance": 0.2, "attack": 0.8, "reverb_mix": 0.6}
- "bright lead": {"frequency": 880, "oscillator_type": 1, "filter_cutoff": 3000, "attack": 0.01}

Generate JSON for "$userDescription", respond with only the JSON object:
[/INST]''';
  }
  
  /// Generate a preset based on simple rules without API calls
  Map<String, dynamic> _generateRuleBasedPreset(String description) {
    debugPrint('[Rule-Based] Generating preset for: $description');
    // Convert description to lowercase for easier pattern matching
    final lowerDesc = description.toLowerCase();
    debugPrint('[Rule-Based] Lowercase description: $lowerDesc');
    
    // Initialize default values
    double frequency = 440.0;
    int oscType = 0; // sine
    double filterCutoff = 1000.0;
    double resonance = 0.1;
    int filterType = 0; // lowpass
    double attack = 0.1;
    double decay = 0.2;
    double sustain = 0.7;
    double release = 0.5;
    double reverbMix = 0.3;
    double delayTime = 0.25;
    double delayFeedback = 0.3;
    
    // Adjust parameters based on keywords in the description
    
    // Frequency/pitch keywords
    if (lowerDesc.contains('bass') || lowerDesc.contains('low')) {
      debugPrint('[Rule-Based] Detected bass/low - setting frequency to 110Hz');
      frequency = 110.0;
      oscType = 3; // sawtooth for bass
    } else if (lowerDesc.contains('high') || lowerDesc.contains('treble')) {
      debugPrint('[Rule-Based] Detected high/treble - setting frequency to 880Hz');
      frequency = 880.0;
    } else if (lowerDesc.contains('mid')) {
      debugPrint('[Rule-Based] Detected mid - setting frequency to 440Hz');
      frequency = 440.0;
    }
    
    // Oscillator type keywords
    if (lowerDesc.contains('sine')) {
      oscType = 0;
    } else if (lowerDesc.contains('square')) {
      oscType = 1;
    } else if (lowerDesc.contains('triangle')) {
      oscType = 2;
    } else if (lowerDesc.contains('saw')) {
      oscType = 3;
    } else if (lowerDesc.contains('noise')) {
      oscType = 4;
    }
    
    // Sound character keywords
    if (lowerDesc.contains('bright') || lowerDesc.contains('sharp')) {
      debugPrint('[Rule-Based] Detected bright/sharp - setting filter to 3000Hz');
      filterCutoff = 3000.0;
      resonance = 0.3;
    } else if (lowerDesc.contains('warm') || lowerDesc.contains('mellow')) {
      debugPrint('[Rule-Based] Detected warm/mellow - setting filter to 800Hz, triangle wave');
      filterCutoff = 800.0;
      oscType = 2; // triangle for warmth
    } else if (lowerDesc.contains('harsh') || lowerDesc.contains('aggressive')) {
      debugPrint('[Rule-Based] Detected harsh/aggressive - square wave, high resonance');
      oscType = 1; // square
      resonance = 0.7;
      filterCutoff = 2000.0;
    }
    
    // Envelope keywords
    if (lowerDesc.contains('pluck') || lowerDesc.contains('short') || lowerDesc.contains('staccato')) {
      debugPrint('[Rule-Based] Detected pluck/short - fast attack, no sustain');
      attack = 0.001;
      decay = 0.05;
      sustain = 0.0;
      release = 0.1;
    } else if (lowerDesc.contains('pad') || lowerDesc.contains('long') || lowerDesc.contains('sustained')) {
      debugPrint('[Rule-Based] Detected pad/long - slow attack, high sustain');
      attack = 0.5;
      decay = 0.3;
      sustain = 0.8;
      release = 2.0;
    } else if (lowerDesc.contains('lead')) {
      debugPrint('[Rule-Based] Detected lead - medium envelope');
      attack = 0.01;
      decay = 0.1;
      sustain = 0.5;
      release = 0.3;
    }
    
    // Effects keywords
    if (lowerDesc.contains('dry')) {
      debugPrint('[Rule-Based] Detected dry - no effects');
      reverbMix = 0.0;
      delayTime = 0.0;
      delayFeedback = 0.0;
    } else if (lowerDesc.contains('wet') || lowerDesc.contains('reverb')) {
      debugPrint('[Rule-Based] Detected wet/reverb - setting reverb to 0.7');
      reverbMix = 0.7;
    }
    
    if (lowerDesc.contains('echo') || lowerDesc.contains('delay')) {
      debugPrint('[Rule-Based] Detected echo/delay - setting delay to 0.5');
      delayTime = 0.5;
      delayFeedback = 0.4;
    }
    
    // Generate a name based on the description
    String presetName = "Custom Preset";
    if (lowerDesc.contains('bass')) presetName = "Bass Sound";
    else if (lowerDesc.contains('lead')) presetName = "Lead Synth";
    else if (lowerDesc.contains('pad')) presetName = "Pad Sound";
    else if (lowerDesc.contains('pluck')) presetName = "Plucked String";
    else if (lowerDesc.contains('noise')) presetName = "Noise Texture";
    
    // Log final values
    debugPrint('[Rule-Based] Final values:');
    debugPrint('  - Frequency: $frequency Hz');
    debugPrint('  - Oscillator Type: $oscType');
    debugPrint('  - Filter Cutoff: $filterCutoff Hz');
    debugPrint('  - Reverb Mix: $reverbMix');
    debugPrint('  - Attack Time: ${attack}s');
    
    // Return the generated preset
    return {
      'preset_name': presetName,
      'preset_description': 'Rule-based preset generated from: $description',
      'parameters': {
        'oscillators': [
          {
            'type': oscType,
            'frequency': frequency,
            'detune': 0.0,
            'volume': 0.8,
            'pan': 0.0,
            'wavetableIndex': 0,
            'wavetablePosition': 0.5
          }
        ],
        'filter': {
          'cutoff': filterCutoff,
          'resonance': resonance,
          'type': filterType
        },
        'envelope': {
          'attack': attack,
          'decay': decay,
          'sustain': sustain,
          'release': release
        },
        'effects': {
          'reverb_mix': reverbMix,
          'delay_time': delayTime,
          'delay_feedback': delayFeedback
        }
      }
    };
  }
}