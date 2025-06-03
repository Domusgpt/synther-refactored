import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../core/synth_parameters.dart';
import '../../core/firebase_manager.dart';

/// Enhanced LLM preset generation with multiple AI providers and advanced algorithms
class EnhancedLLMService {
  static final EnhancedLLMService _instance = EnhancedLLMService._internal();
  factory EnhancedLLMService() => _instance;
  EnhancedLLMService._internal();

  // API endpoints and configurations
  static const String _huggingFaceUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1';
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _togetherUrl = 'https://api.together.xyz/v1/chat/completions';
  static const String _cohereUrl = 'https://api.cohere.ai/v1/generate';
  static const String _mistralUrl = 'https://api.mistral.ai/v1/chat/completions';
  
  // API keys (these should be stored securely in production)
  String? _huggingFaceKey;
  String? _groqKey;
  String? _togetherKey;
  String? _cohereKey;
  String? _mistralKey;
  
  // Provider reliability tracking
  final Map<String, double> _providerReliability = {
    'huggingface': 0.9,
    'groq': 0.95,
    'together': 0.85,
    'cohere': 0.88,
    'mistral': 0.92,
    'local': 1.0,
  };
  
  final Map<String, int> _providerUsage = {};
  final Map<String, DateTime> _lastProviderUse = {};

  /// Initialize with API keys
  void initialize({
    String? huggingFaceKey,
    String? groqKey,
    String? togetherKey,
    String? cohereKey,
    String? mistralKey,
  }) {
    _huggingFaceKey = huggingFaceKey;
    _groqKey = groqKey;
    _togetherKey = togetherKey;
    _cohereKey = cohereKey;
    _mistralKey = mistralKey;
    
    print('Enhanced LLM Service initialized with ${_getAvailableProviders().length} providers');
  }

  /// Get list of available providers
  List<String> _getAvailableProviders() {
    final providers = <String>['local']; // Always available
    
    if (_huggingFaceKey != null) providers.add('huggingface');
    if (_groqKey != null) providers.add('groq');
    if (_togetherKey != null) providers.add('together');
    if (_cohereKey != null) providers.add('cohere');
    if (_mistralKey != null) providers.add('mistral');
    
    return providers;
  }

  /// Select best provider based on reliability and usage
  String _selectBestProvider() {
    final available = _getAvailableProviders();
    
    // Sort by reliability and recent usage
    available.sort((a, b) {
      final reliabilityA = _providerReliability[a] ?? 0.0;
      final reliabilityB = _providerReliability[b] ?? 0.0;
      
      final usageA = _providerUsage[a] ?? 0;
      final usageB = _providerUsage[b] ?? 0;
      
      // Prefer higher reliability and lower recent usage
      final scoreA = reliabilityA - (usageA * 0.1);
      final scoreB = reliabilityB - (usageB * 0.1);
      
      return scoreB.compareTo(scoreA);
    });
    
    return available.first;
  }

  /// Generate preset with AI assistance
  Future<Map<String, dynamic>> generatePreset(String description, {
    String? mood,
    String? genre,
    String? energy,
    List<String>? tags,
  }) async {
    final provider = _selectBestProvider();
    
    try {
      // Track usage
      _providerUsage[provider] = (_providerUsage[provider] ?? 0) + 1;
      _lastProviderUse[provider] = DateTime.now();
      
      final preset = await _generateWithProvider(provider, description, 
        mood: mood, genre: genre, energy: energy, tags: tags);
      
      // Log successful generation
      await FirebaseManager().logEvent('llm_preset_generated', parameters: {
        'provider': provider,
        'description_length': description.length,
        'has_mood': mood != null,
        'has_genre': genre != null,
        'has_energy': energy != null,
        'tags_count': tags?.length ?? 0,
      });
      
      return preset;
    } catch (e) {
      print('Provider $provider failed: $e');
      
      // Reduce reliability score
      _providerReliability[provider] = 
        (_providerReliability[provider] ?? 0.5) * 0.9;
      
      // Try fallback providers
      final fallbacks = _getAvailableProviders()
        ..remove(provider)
        ..sort((a, b) => (_providerReliability[b] ?? 0.0)
            .compareTo(_providerReliability[a] ?? 0.0));
      
      for (final fallback in fallbacks) {
        try {
          final preset = await _generateWithProvider(fallback, description,
            mood: mood, genre: genre, energy: energy, tags: tags);
          
          await FirebaseManager().logEvent('llm_preset_fallback_success', parameters: {
            'failed_provider': provider,
            'success_provider': fallback,
          });
          
          return preset;
        } catch (fallbackError) {
          print('Fallback provider $fallback also failed: $fallbackError');
          continue;
        }
      }
      
      // All providers failed, use enhanced local generation
      return _generateLocalPreset(description, mood: mood, genre: genre, energy: energy, tags: tags);
    }
  }

  /// Generate preset with specific provider
  Future<Map<String, dynamic>> _generateWithProvider(String provider, String description, {
    String? mood,
    String? genre,
    String? energy,
    List<String>? tags,
  }) async {
    switch (provider) {
      case 'huggingface':
        return await _generateWithHuggingFace(description, mood: mood, genre: genre, energy: energy, tags: tags);
      case 'groq':
        return await _generateWithGroq(description, mood: mood, genre: genre, energy: energy, tags: tags);
      case 'together':
        return await _generateWithTogether(description, mood: mood, genre: genre, energy: energy, tags: tags);
      case 'cohere':
        return await _generateWithCohere(description, mood: mood, genre: genre, energy: energy, tags: tags);
      case 'mistral':
        return await _generateWithMistral(description, mood: mood, genre: genre, energy: energy, tags: tags);
      case 'local':
        return _generateLocalPreset(description, mood: mood, genre: genre, energy: energy, tags: tags);
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  /// Generate preset with Hugging Face
  Future<Map<String, dynamic>> _generateWithHuggingFace(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) async {
    final prompt = _buildPrompt(description, mood: mood, genre: genre, energy: energy, tags: tags);
    
    final response = await http.post(
      Uri.parse(_huggingFaceUrl),
      headers: {
        'Authorization': 'Bearer $_huggingFaceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': 500,
          'temperature': 0.7,
          'return_full_text': false,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText = data[0]['generated_text'] as String;
      return _parseAIResponse(generatedText, description);
    } else {
      throw Exception('Hugging Face API error: ${response.statusCode}');
    }
  }

  /// Generate preset with Groq
  Future<Map<String, dynamic>> _generateWithGroq(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) async {
    final prompt = _buildPrompt(description, mood: mood, genre: genre, energy: energy, tags: tags);
    
    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Authorization': 'Bearer $_groqKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'mixtral-8x7b-32768',
        'messages': [
          {'role': 'system', 'content': 'You are a professional sound designer and synthesizer expert.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText = data['choices'][0]['message']['content'] as String;
      return _parseAIResponse(generatedText, description);
    } else {
      throw Exception('Groq API error: ${response.statusCode}');
    }
  }

  /// Generate preset with Together AI
  Future<Map<String, dynamic>> _generateWithTogether(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) async {
    final prompt = _buildPrompt(description, mood: mood, genre: genre, energy: energy, tags: tags);
    
    final response = await http.post(
      Uri.parse(_togetherUrl),
      headers: {
        'Authorization': 'Bearer $_togetherKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'mistralai/Mixtral-8x7B-Instruct-v0.1',
        'messages': [
          {'role': 'system', 'content': 'You are an expert synthesizer programmer and sound designer.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText = data['choices'][0]['message']['content'] as String;
      return _parseAIResponse(generatedText, description);
    } else {
      throw Exception('Together AI API error: ${response.statusCode}');
    }
  }

  /// Generate preset with Cohere
  Future<Map<String, dynamic>> _generateWithCohere(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) async {
    final prompt = _buildPrompt(description, mood: mood, genre: genre, energy: energy, tags: tags);
    
    final response = await http.post(
      Uri.parse(_cohereUrl),
      headers: {
        'Authorization': 'Bearer $_cohereKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'command',
        'prompt': prompt,
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText = data['generations'][0]['text'] as String;
      return _parseAIResponse(generatedText, description);
    } else {
      throw Exception('Cohere API error: ${response.statusCode}');
    }
  }

  /// Generate preset with Mistral AI
  Future<Map<String, dynamic>> _generateWithMistral(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) async {
    final prompt = _buildPrompt(description, mood: mood, genre: genre, energy: energy, tags: tags);
    
    final response = await http.post(
      Uri.parse(_mistralUrl),
      headers: {
        'Authorization': 'Bearer $_mistralKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'mistral-medium',
        'messages': [
          {'role': 'system', 'content': 'You are a master synthesizer programmer with deep knowledge of electronic music production.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText = data['choices'][0]['message']['content'] as String;
      return _parseAIResponse(generatedText, description);
    } else {
      throw Exception('Mistral AI API error: ${response.statusCode}');
    }
  }

  /// Build comprehensive prompt for AI models
  String _buildPrompt(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) {
    final context = StringBuffer();
    context.writeln('Create a synthesizer preset for: "$description"');
    
    if (mood != null) context.writeln('Mood: $mood');
    if (genre != null) context.writeln('Genre: $genre');
    if (energy != null) context.writeln('Energy level: $energy');
    if (tags != null && tags.isNotEmpty) context.writeln('Tags: ${tags.join(", ")}');
    
    context.writeln('''
Return a JSON object with these synthesizer parameters:

{
  "name": "preset name",
  "description": "brief description",
  "masterVolume": 0.0-1.0,
  "oscillators": [
    {
      "type": 0-4 (0=sine, 1=square, 2=sawtooth, 3=triangle, 4=noise),
      "volume": 0.0-1.0,
      "detune": -1200 to 1200 cents,
      "phase": 0.0-1.0
    }
  ],
  "filter": {
    "cutoff": 20-20000 Hz,
    "resonance": 0.1-30.0,
    "type": 0-3 (0=lowpass, 1=highpass, 2=bandpass, 3=notch)
  },
  "envelope": {
    "attack": 0.001-5.0 seconds,
    "decay": 0.001-5.0 seconds,
    "sustain": 0.0-1.0,
    "release": 0.001-10.0 seconds
  },
  "effects": {
    "reverb": 0.0-1.0,
    "delay": 0.0-2.0 seconds,
    "distortion": 0.0-1.0
  }
}

Make the preset musically appropriate for the description. Use realistic parameter values.''');

    return context.toString();
  }

  /// Enhanced local preset generation with advanced algorithms
  Map<String, dynamic> _generateLocalPreset(String description, {
    String? mood, String? genre, String? energy, List<String>? tags,
  }) {
    final analyzer = PresetAnalyzer(description, mood: mood, genre: genre, energy: energy, tags: tags);
    return analyzer.generatePreset();
  }

  /// Parse AI response and extract preset parameters
  Map<String, dynamic> _parseAIResponse(String response, String originalDescription) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr);
        
        // Validate and sanitize parameters
        return _sanitizePreset(parsed, originalDescription);
      }
    } catch (e) {
      print('Error parsing AI response: $e');
    }
    
    // Fallback to enhanced local generation
    return _generateLocalPreset(originalDescription);
  }

  /// Sanitize and validate preset parameters
  Map<String, dynamic> _sanitizePreset(Map<String, dynamic> preset, String description) {
    final sanitized = <String, dynamic>{
      'name': preset['name']?.toString() ?? 'AI Generated Preset',
      'description': preset['description']?.toString() ?? description,
      'masterVolume': _clampDouble(preset['masterVolume'], 0.0, 1.0, 0.8),
    };

    // Sanitize oscillators
    final oscillators = preset['oscillators'] as List?;
    if (oscillators != null && oscillators.isNotEmpty) {
      sanitized['oscillators'] = oscillators.take(3).map((osc) => {
        'type': _clampInt(osc['type'], 0, 4, 0),
        'volume': _clampDouble(osc['volume'], 0.0, 1.0, 0.8),
        'detune': _clampDouble(osc['detune'], -1200, 1200, 0),
        'phase': _clampDouble(osc['phase'], 0.0, 1.0, 0),
      }).toList();
    } else {
      sanitized['oscillators'] = [
        {'type': 0, 'volume': 0.8, 'detune': 0, 'phase': 0},
      ];
    }

    // Sanitize filter
    final filter = preset['filter'] as Map?;
    sanitized['filter'] = {
      'cutoff': _clampDouble(filter?['cutoff'], 20, 20000, 1000),
      'resonance': _clampDouble(filter?['resonance'], 0.1, 30, 1),
      'type': _clampInt(filter?['type'], 0, 3, 0),
    };

    // Sanitize envelope
    final envelope = preset['envelope'] as Map?;
    sanitized['envelope'] = {
      'attack': _clampDouble(envelope?['attack'], 0.001, 5, 0.01),
      'decay': _clampDouble(envelope?['decay'], 0.001, 5, 0.1),
      'sustain': _clampDouble(envelope?['sustain'], 0.0, 1, 0.7),
      'release': _clampDouble(envelope?['release'], 0.001, 10, 0.3),
    };

    // Sanitize effects
    final effects = preset['effects'] as Map?;
    sanitized['effects'] = {
      'reverb': _clampDouble(effects?['reverb'], 0.0, 1, 0),
      'delay': _clampDouble(effects?['delay'], 0.0, 2, 0),
      'distortion': _clampDouble(effects?['distortion'], 0.0, 1, 0),
    };

    return sanitized;
  }

  /// Utility methods
  double _clampDouble(dynamic value, double min, double max, double defaultValue) {
    if (value is num) {
      return math.max(min, math.min(max, value.toDouble()));
    }
    return defaultValue;
  }

  int _clampInt(dynamic value, int min, int max, int defaultValue) {
    if (value is num) {
      return math.max(min, math.min(max, value.toInt()));
    }
    return defaultValue;
  }

  /// Get provider statistics for debugging
  Map<String, dynamic> getProviderStats() {
    return {
      'reliability': Map.from(_providerReliability),
      'usage': Map.from(_providerUsage),
      'lastUse': _lastProviderUse.map((k, v) => MapEntry(k, v.toIso8601String())),
      'available': _getAvailableProviders(),
    };
  }
}

/// Advanced preset analysis for local generation
class PresetAnalyzer {
  final String description;
  final String? mood;
  final String? genre;
  final String? energy;
  final List<String>? tags;

  PresetAnalyzer(this.description, {this.mood, this.genre, this.energy, this.tags});

  Map<String, dynamic> generatePreset() {
    // Analyze description for keywords
    final keywords = _extractKeywords();
    
    // Generate base preset based on analysis
    final preset = _generateBasePreset(keywords);
    
    // Apply mood modifiers
    if (mood != null) _applyMoodModifiers(preset, mood!);
    
    // Apply genre modifiers
    if (genre != null) _applyGenreModifiers(preset, genre!);
    
    // Apply energy modifiers
    if (energy != null) _applyEnergyModifiers(preset, energy!);
    
    // Apply tag modifiers
    if (tags != null) _applyTagModifiers(preset, tags!);
    
    return preset;
  }

  Set<String> _extractKeywords() {
    final text = [description, mood, genre, energy, ...(tags ?? [])].join(' ').toLowerCase();
    
    return {
      // Musical terms
      if (text.contains(RegExp(r'\b(bass|low|sub)\b'))) 'bass',
      if (text.contains(RegExp(r'\b(lead|high|bright)\b'))) 'lead',
      if (text.contains(RegExp(r'\b(pad|warm|ambient)\b'))) 'pad',
      if (text.contains(RegExp(r'\b(pluck|stab|short)\b'))) 'pluck',
      if (text.contains(RegExp(r'\b(sweep|filter|moving)\b'))) 'sweep',
      
      // Timbral qualities
      if (text.contains(RegExp(r'\b(harsh|distorted|gritty)\b'))) 'harsh',
      if (text.contains(RegExp(r'\b(soft|gentle|smooth)\b'))) 'soft',
      if (text.contains(RegExp(r'\b(metallic|bell|ring)\b'))) 'metallic',
      if (text.contains(RegExp(r'\b(organic|natural|acoustic)\b'))) 'organic',
      
      // Genres
      if (text.contains(RegExp(r'\b(techno|electronic|edm)\b'))) 'electronic',
      if (text.contains(RegExp(r'\b(ambient|drone|atmospheric)\b'))) 'ambient',
      if (text.contains(RegExp(r'\b(rock|guitar|distortion)\b'))) 'rock',
      if (text.contains(RegExp(r'\b(jazz|smooth|complex)\b'))) 'jazz',
    };
  }

  Map<String, dynamic> _generateBasePreset(Set<String> keywords) {
    // Base preset template
    final preset = <String, dynamic>{
      'name': _generateName(keywords),
      'description': description,
      'masterVolume': 0.8,
      'oscillators': [_generateOscillator(keywords, 0)],
      'filter': _generateFilter(keywords),
      'envelope': _generateEnvelope(keywords),
      'effects': _generateEffects(keywords),
    };

    // Add additional oscillators based on keywords
    if (keywords.contains('thick') || keywords.contains('rich')) {
      preset['oscillators'].add(_generateOscillator(keywords, 1));
    }
    
    if (keywords.contains('complex') || keywords.contains('layered')) {
      preset['oscillators'].add(_generateOscillator(keywords, 2));
    }

    return preset;
  }

  String _generateName(Set<String> keywords) {
    final adjectives = ['Warm', 'Bright', 'Deep', 'Ethereal', 'Punchy', 'Smooth'];
    final nouns = ['Bass', 'Lead', 'Pad', 'Pluck', 'Sweep', 'Bell'];
    
    final adjective = adjectives[math.Random().nextInt(adjectives.length)];
    final noun = nouns[math.Random().nextInt(nouns.length)];
    
    return '$adjective $noun';
  }

  Map<String, dynamic> _generateOscillator(Set<String> keywords, int index) {
    int type = 0; // Default to sine
    double volume = index == 0 ? 0.8 : 0.5;
    double detune = 0;
    
    if (keywords.contains('bass')) {
      type = 0; // Sine for bass
      if (index > 0) type = 2; // Add sawtooth for richness
    } else if (keywords.contains('lead')) {
      type = 2; // Sawtooth for lead
      if (index > 0) type = 1; // Add square for bite
    } else if (keywords.contains('pad')) {
      type = 2; // Sawtooth
      if (index > 0) {
        type = 0; // Add sine for smoothness
        detune = 7; // Slight detune for width
      }
    } else if (keywords.contains('pluck')) {
      type = 1; // Square for percussive attack
    }
    
    return {
      'type': type,
      'volume': volume,
      'detune': detune,
      'phase': 0,
    };
  }

  Map<String, dynamic> _generateFilter(Set<String> keywords) {
    double cutoff = 1000;
    double resonance = 1;
    int type = 0; // Lowpass
    
    if (keywords.contains('bright') || keywords.contains('lead')) {
      cutoff = 5000;
      resonance = 2;
    } else if (keywords.contains('bass')) {
      cutoff = 300;
      resonance = 0.5;
    } else if (keywords.contains('sweep')) {
      cutoff = 2000;
      resonance = 5;
    }
    
    return {
      'cutoff': cutoff,
      'resonance': resonance,
      'type': type,
    };
  }

  Map<String, dynamic> _generateEnvelope(Set<String> keywords) {
    double attack = 0.01;
    double decay = 0.1;
    double sustain = 0.7;
    double release = 0.3;
    
    if (keywords.contains('pluck') || keywords.contains('stab')) {
      attack = 0.001;
      decay = 0.3;
      sustain = 0.1;
      release = 0.5;
    } else if (keywords.contains('pad') || keywords.contains('ambient')) {
      attack = 0.5;
      decay = 0.2;
      sustain = 0.8;
      release = 2.0;
    } else if (keywords.contains('bass')) {
      attack = 0.001;
      decay = 0.1;
      sustain = 0.9;
      release = 0.3;
    }
    
    return {
      'attack': attack,
      'decay': decay,
      'sustain': sustain,
      'release': release,
    };
  }

  Map<String, dynamic> _generateEffects(Set<String> keywords) {
    double reverb = 0;
    double delay = 0;
    double distortion = 0;
    
    if (keywords.contains('ambient') || keywords.contains('pad')) {
      reverb = 0.4;
      delay = 0.3;
    } else if (keywords.contains('harsh') || keywords.contains('distorted')) {
      distortion = 0.6;
    } else if (keywords.contains('space') || keywords.contains('echo')) {
      delay = 0.5;
      reverb = 0.2;
    }
    
    return {
      'reverb': reverb,
      'delay': delay,
      'distortion': distortion,
    };
  }

  void _applyMoodModifiers(Map<String, dynamic> preset, String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'uplifting':
        preset['filter']['cutoff'] *= 1.5;
        preset['envelope']['attack'] *= 0.5;
        break;
      case 'sad':
      case 'melancholy':
        preset['filter']['cutoff'] *= 0.7;
        preset['effects']['reverb'] += 0.3;
        break;
      case 'aggressive':
      case 'angry':
        preset['effects']['distortion'] += 0.4;
        preset['filter']['resonance'] *= 2;
        break;
      case 'calm':
      case 'peaceful':
        preset['envelope']['attack'] *= 2;
        preset['effects']['reverb'] += 0.2;
        break;
    }
  }

  void _applyGenreModifiers(Map<String, dynamic> preset, String genre) {
    switch (genre.toLowerCase()) {
      case 'techno':
      case 'house':
        preset['envelope']['attack'] = 0.001;
        preset['filter']['resonance'] *= 1.5;
        break;
      case 'ambient':
      case 'chillout':
        preset['envelope']['attack'] *= 3;
        preset['effects']['reverb'] = 0.5;
        break;
      case 'dubstep':
      case 'bass':
        preset['filter']['cutoff'] *= 0.5;
        preset['effects']['distortion'] += 0.3;
        break;
      case 'trance':
        preset['filter']['cutoff'] *= 1.2;
        preset['envelope']['release'] *= 1.5;
        break;
    }
  }

  void _applyEnergyModifiers(Map<String, dynamic> preset, String energy) {
    switch (energy.toLowerCase()) {
      case 'high':
      case 'energetic':
        preset['filter']['cutoff'] *= 1.3;
        preset['envelope']['attack'] *= 0.5;
        preset['masterVolume'] *= 1.1;
        break;
      case 'low':
      case 'mellow':
        preset['filter']['cutoff'] *= 0.8;
        preset['envelope']['attack'] *= 1.5;
        preset['masterVolume'] *= 0.9;
        break;
      case 'medium':
        // Keep defaults
        break;
    }
  }

  void _applyTagModifiers(Map<String, dynamic> preset, List<String> tags) {
    for (final tag in tags) {
      switch (tag.toLowerCase()) {
        case 'vintage':
        case 'retro':
          preset['effects']['distortion'] += 0.2;
          preset['filter']['cutoff'] *= 0.9;
          break;
        case 'modern':
        case 'digital':
          preset['filter']['cutoff'] *= 1.2;
          break;
        case 'organic':
        case 'natural':
          preset['envelope']['attack'] *= 1.5;
          preset['effects']['reverb'] += 0.1;
          break;
        case 'synthetic':
        case 'artificial':
          preset['filter']['resonance'] *= 1.5;
          break;
      }
    }
  }
}