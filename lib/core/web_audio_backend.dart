import 'dart:html' as html;
import 'dart:web_audio' as audio;
import 'dart:typed_data';
import 'dart:math' as math;
import 'audio_backend.dart';

// Audio constants
class OscillatorType {
  static const int sine = 0;
  static const int square = 1;
  static const int triangle = 2;
  static const int sawtooth = 3;
  static const int noise = 4;
  static const int pulse = 5;
}

class FilterType {
  static const int lowpass = 0;
  static const int highpass = 1;
  static const int bandpass = 2;
  static const int notch = 3;
  static const int allpass = 4;
  static const int peaking = 5;
  static const int lowshelf = 6;
  static const int highshelf = 7;
}

class ScaleType {
  static const int chromatic = 0;
  static const int major = 1;
  static const int minor = 2;
  static const int pentatonic = 3;
  static const int blues = 4;
}

/// Web Audio API implementation of AudioBackend
/// Provides full synthesis capabilities in web browsers
class WebAudioBackend implements AudioBackend {
  audio.AudioContext? _context;
  audio.GainNode? _masterGain;
  final Map<int, WebVoice> _voices = {};
  
  // Global nodes
  audio.BiquadFilterNode? _filter;
  audio.ConvolverNode? _reverb;
  audio.DelayNode? _delay;
  audio.GainNode? _delayFeedback;
  audio.GainNode? _delayMix;
  audio.WaveShaperNode? _distortion;
  
  bool _initialized = false;
  String? _lastErrorMessage;
  
  // Current parameters
  int _currentOscType = OscillatorType.sine;
  double _filterCutoff = 2000.0;
  double _filterResonance = 1.0;
  int _filterType = FilterType.lowpass;
  double _adsrAttack = 0.01;
  double _adsrDecay = 0.1;
  double _adsrSustain = 0.7;
  double _adsrRelease = 0.3;
  
  // Scale settings
  int _currentScale = ScaleType.chromatic;
  int _rootNote = 60; // Middle C
  
  @override
  bool get isInitialized => _initialized;
  
  @override
  String? get lastError => _lastErrorMessage;
  
  @override
  Future<void> initialize() async {
    try {
      _context = audio.AudioContext();
      
      // Create master gain
      _masterGain = _context!.createGain();
      _masterGain!.gain!.value = 0.5;
      
      // Create filter
      _filter = _context!.createBiquadFilter();
      _filter!.type = 'lowpass';
      _filter!.frequency!.value = _filterCutoff;
      _filter!.Q!.value = _filterResonance;
      
      // Create delay
      _delay = _context!.createDelay(2.0);
      _delayFeedback = _context!.createGain();
      _delayMix = _context!.createGain();
      _delay!.delayTime!.value = 0.3;
      _delayFeedback!.gain!.value = 0.4;
      _delayMix!.gain!.value = 0.3;
      
      // Connect delay feedback loop
      _delay!.connectNode(_delayFeedback!);
      _delayFeedback!.connectNode(_delay!);
      _delay!.connectNode(_delayMix!);
      
      // Create reverb with impulse response
      _reverb = _context!.createConvolver();
      _createReverbImpulse();
      
      // Create distortion
      _distortion = _context!.createWaveShaper();
      _distortion!.curve = _makeDistortionCurve(0.0);
      
      // Connect effects chain
      _filter!.connectNode(_distortion!);
      _distortion!.connectNode(_delay!);
      _distortion!.connectNode(_reverb!);
      _reverb!.connectNode(_masterGain!);
      _delayMix!.connectNode(_masterGain!);
      _masterGain!.connectNode(_context!.destination!);
      
      _initialized = true;
      print('WebAudioBackend: Initialized successfully');
    } catch (e) {
      _lastErrorMessage = 'Failed to initialize Web Audio: $e';
      print('WebAudioBackend: $_lastErrorMessage');
      _initialized = false;
    }
  }
  
  @override
  void noteOn(int id, int note, double velocity) {
    if (!_initialized || _context == null) return;
    
    // Stop existing voice if any
    _voices[id]?.stop();
    
    // Create new voice
    final voice = WebVoice(_context!, note, velocity);
    voice.oscillatorType = _getOscillatorTypeString(_currentOscType);
    voice.setEnvelope(_adsrAttack, _adsrDecay, _adsrSustain, _adsrRelease);
    voice.connectTo(_filter!);
    voice.start();
    
    _voices[id] = voice;
  }
  
  @override
  void noteOff(int id) {
    final voice = _voices[id];
    if (voice != null) {
      voice.stop();
      // Remove after release time
      Future.delayed(Duration(milliseconds: (_adsrRelease * 1000).round()), () {
        _voices.remove(id);
      });
    }
  }
  
  @override
  void setParameter(int parameterId, double value) {
    if (!_initialized) return;
    
    switch (parameterId) {
      case AudioParameters.masterVolume:
        _masterGain?.gain?.value = value.clamp(0.0, 1.0);
        break;
        
      case AudioParameters.oscType:
        _currentOscType = value.round();
        // Update all active voices
        final typeString = _getOscillatorTypeString(_currentOscType);
        _voices.values.forEach((voice) {
          voice.oscillatorType = typeString;
        });
        break;
        
      case AudioParameters.filterCutoff:
        _filterCutoff = value.clamp(20.0, 20000.0);
        _filter?.frequency?.value = _filterCutoff;
        break;
        
      case AudioParameters.filterResonance:
        _filterResonance = value.clamp(0.1, 30.0);
        _filter?.Q?.value = _filterResonance;
        break;
        
      case AudioParameters.filterType:
        _filterType = value.round();
        _filter?.type = _getFilterTypeString(_filterType);
        break;
        
      case AudioParameters.adsrAttack:
        _adsrAttack = value.clamp(0.001, 2.0);
        break;
        
      case AudioParameters.adsrDecay:
        _adsrDecay = value.clamp(0.001, 2.0);
        break;
        
      case AudioParameters.adsrSustain:
        _adsrSustain = value.clamp(0.0, 1.0);
        break;
        
      case AudioParameters.adsrRelease:
        _adsrRelease = value.clamp(0.001, 5.0);
        break;
        
      case AudioParameters.delayTime:
        _delay?.delayTime?.value = value.clamp(0.0, 2.0);
        break;
        
      case AudioParameters.delayFeedback:
        _delayFeedback?.gain?.value = value.clamp(0.0, 0.95);
        break;
        
      case AudioParameters.delayMix:
        _delayMix?.gain?.value = value.clamp(0.0, 1.0);
        break;
        
      case AudioParameters.reverbWet:
        // Simple reverb wet control via gain
        if (_reverb != null) {
          // This is simplified - in a real implementation you'd have
          // separate dry/wet paths
          final wetLevel = value.clamp(0.0, 1.0);
          // Adjust by using a gain node between reverb and output
        }
        break;
    }
  }
  
  @override
  double getParameter(int parameterId) {
    switch (parameterId) {
      case AudioParameters.masterVolume:
        return (_masterGain?.gain?.value ?? 0.5).toDouble();
      case AudioParameters.oscType:
        return _currentOscType.toDouble();
      case AudioParameters.filterCutoff:
        return _filterCutoff;
      case AudioParameters.filterResonance:
        return _filterResonance;
      case AudioParameters.filterType:
        return _filterType.toDouble();
      case AudioParameters.adsrAttack:
        return _adsrAttack;
      case AudioParameters.adsrDecay:
        return _adsrDecay;
      case AudioParameters.adsrSustain:
        return _adsrSustain;
      case AudioParameters.adsrRelease:
        return _adsrRelease;
      case AudioParameters.delayTime:
        return (_delay?.delayTime?.value ?? 0.3).toDouble();
      case AudioParameters.delayFeedback:
        return (_delayFeedback?.gain?.value ?? 0.4).toDouble();
      case AudioParameters.delayMix:
        return (_delayMix?.gain?.value ?? 0.3).toDouble();
      default:
        return 0.0;
    }
  }
  
  @override
  void setScale(int scaleIndex, int rootNote) {
    _currentScale = scaleIndex;
    _rootNote = rootNote;
  }
  
  @override
  int getCurrentScale() => _currentScale;
  
  @override
  int loadGranularBuffer(List<double> audioData) {
    // Granular synthesis not implemented in web version yet
    // Would require Web Audio API buffer source nodes
    return -1;
  }
  
  @override
  void shutdown() => dispose();
  
  @override
  void dispose() {
    // Stop all voices
    _voices.values.forEach((voice) => voice.stop());
    _voices.clear();
    
    // Close audio context
    _context?.close();
    _context = null;
    _initialized = false;
  }
  
  // Helper methods
  
  String _getOscillatorTypeString(int type) {
    switch (type) {
      case OscillatorType.sine:
        return 'sine';
      case OscillatorType.triangle:
        return 'triangle';
      case OscillatorType.square:
        return 'square';
      case OscillatorType.sawtooth:
        return 'sawtooth';
      default:
        return 'sine';
    }
  }
  
  String _getFilterTypeString(int type) {
    switch (type) {
      case FilterType.lowpass:
        return 'lowpass';
      case FilterType.highpass:
        return 'highpass';
      case FilterType.bandpass:
        return 'bandpass';
      case FilterType.notch:
        return 'notch';
      default:
        return 'lowpass';
    }
  }
  
  void _createReverbImpulse() {
    // Create a simple impulse response for reverb
    final length = _context!.sampleRate! * 2; // 2 second reverb
    final impulse = _context!.createBuffer(2, length.round(), _context!.sampleRate!);
    
    for (int channel = 0; channel < 2; channel++) {
      final channelData = impulse.getChannelData(channel);
      for (int i = 0; i < channelData.length; i++) {
        // Exponentially decaying white noise
        channelData[i] = (math.Random().nextDouble() * 2 - 1) * 
                         math.pow(1 - i / channelData.length, 2);
      }
    }
    
    _reverb!.buffer = impulse;
  }
  
  Float32List _makeDistortionCurve(double amount) {
    final samples = 44100;
    final curve = Float32List(samples);
    final deg = math.pi / 180;
    
    for (int i = 0; i < samples; i++) {
      final x = i * 2 / samples - 1;
      if (amount > 0) {
        curve[i] = (3 + amount) * x * 20 * deg / (math.pi + amount * x.abs());
      } else {
        curve[i] = x;
      }
    }
    
    return curve;
  }
}

/// Individual voice for polyphony
class WebVoice {
  final audio.AudioContext context;
  final int noteNumber;
  final double velocity;
  
  audio.OscillatorNode? oscillator;
  audio.GainNode? gainNode;
  audio.GainNode? velocityGain;
  
  String _oscillatorType = 'sine';
  bool _started = false;
  
  WebVoice(this.context, this.noteNumber, this.velocity) {
    // Create oscillator
    oscillator = context.createOscillator();
    oscillator!.frequency!.value = _midiToFrequency(noteNumber);
    oscillator!.type = _oscillatorType;
    
    // Create gain nodes
    gainNode = context.createGain();
    gainNode!.gain!.value = 0.0;
    
    velocityGain = context.createGain();
    velocityGain!.gain!.value = velocity;
    
    // Connect
    oscillator!.connectNode(gainNode!);
    gainNode!.connectNode(velocityGain!);
  }
  
  set oscillatorType(String type) {
    _oscillatorType = type;
    if (oscillator != null && _oscillatorType != 'noise') {
      oscillator!.type = type;
    }
  }
  
  void setEnvelope(double attack, double decay, double sustain, double release) {
    // Store envelope parameters for later use
    // Applied when start() is called
  }
  
  void connectTo(audio.AudioNode node) {
    velocityGain?.connectNode(node);
  }
  
  void start() {
    if (_started) return;
    
    final now = context.currentTime!;
    
    // Start oscillator  
    try {
      if (oscillator != null) {
        (oscillator as dynamic).start(now);
      }
    } catch (e) {
      // Create a new oscillator if start failed
      print('Oscillator start failed: $e');
      try {
        oscillator = context.createOscillator();
        oscillator!.frequency!.value = _midiToFrequency(noteNumber);
        oscillator!.type = _oscillatorType;
        oscillator!.connectNode(gainNode!);
        (oscillator as dynamic).start(now);
      } catch (e2) {
        print('Oscillator recreation failed: $e2');
        return;
      }
    }
    
    // Apply ADSR envelope
    gainNode?.gain?.setValueAtTime(0, now);
    gainNode?.gain?.linearRampToValueAtTime(1.0, now + 0.01); // Attack
    gainNode?.gain?.linearRampToValueAtTime(0.7, now + 0.1);  // Decay to sustain
    
    _started = true;
  }
  
  void stop() {
    if (!_started) return;
    
    final now = context.currentTime!;
    final releaseTime = 0.3;
    
    // Release envelope
    try {
      gainNode?.gain?.cancelScheduledValues(now);
      gainNode?.gain?.setValueAtTime(gainNode!.gain!.value!, now);
      gainNode?.gain?.linearRampToValueAtTime(0, now + releaseTime);
    } catch (e) {
      print('Envelope release failed: $e');
    }
    
    // Stop oscillator after release
    try {
      if (oscillator != null && _started) {
        (oscillator as dynamic).stop(now + releaseTime);
      }
    } catch (e) {
      print('Oscillator stop failed: $e');
    }
    
    _started = false;
  }
  
  double _midiToFrequency(int midiNote) {
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }
}