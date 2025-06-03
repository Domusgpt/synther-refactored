import 'package:flutter/foundation.dart';
import 'audio_backend.dart';
import 'platform_audio_backend.dart';
import 'granular_parameters.dart';
import 'parameter_definitions.dart';
import '../utils/audio_ui_sync.dart';

/// The main model class for synth parameters
/// 
/// This class holds all parameters controlling the synthesizer and notifies
/// listeners when any parameter changes. It serves as the bridge between the UI
/// and the audio engine (native or web).
class SynthParametersModel extends ChangeNotifier {
  // Reference to the platform-specific audio backend
  late final AudioBackend _engine;
  
  // Master parameters
  double _masterVolume = 0.75;
  bool _isMasterMuted = false;
  
  // Oscillator parameters
  final List<OscillatorParameters> _oscillators = [
    OscillatorParameters(), // Default oscillator
  ];
  
  // Filter parameters
  double _filterCutoff = 1000.0; // Hz
  double _filterResonance = 0.5; // Q
  FilterType _filterType = FilterType.lowPass;
  
  // Envelope parameters
  double _attackTime = 0.01; // seconds
  double _decayTime = 0.1; // seconds
  double _sustainLevel = 0.7; // 0-1
  double _releaseTime = 0.5; // seconds
  
  // Effects parameters
  double _reverbMix = 0.2; // 0-1
  double _delayTime = 0.5; // seconds
  double _delayFeedback = 0.3; // 0-1
  
  // XY Pad parameters
  double _xyPadX = 0.5; // 0-1
  double _xyPadY = 0.5; // 0-1
  XYPadAssignment _xAxisAssignment = XYPadAssignment.filterCutoff;
  XYPadAssignment _yAxisAssignment = XYPadAssignment.filterResonance;
  
  // Granular parameters
  late final GranularParameters _granularParameters;
  
  // Constructor
  SynthParametersModel() {
    // Create platform-specific audio backend
    _engine = createAudioBackend();
    // Initialize granular parameters
    _granularParameters = GranularParameters(_engine);
    // Initialize the engine asynchronously
    _initEngine();
  }
  
  // Initialize the synth engine
  Future<void> _initEngine() async {
    try {
      await _engine.initialize();
      
      // Set initial volume
      _engine.setParameter(AudioParameters.masterVolume, _masterVolume);
      
      // Sync all parameters to the engine
      _syncAllParametersToEngine();
      
      // Initialize audio-UI sync manager
      AudioUISyncManager.instance.initialize(_engine);
      AudioUISyncManager.instance.clearError();
    } catch (e) {
      print('Error initializing synth engine: $e');
      AudioUISyncManager.instance.setError(e.toString());
    }
  }
  
  // Sync all parameters to the C++ engine
  void _syncAllParametersToEngine() {
    if (!_engine.isInitialized) return;
    
    // Master parameters
    _engine.setParameter(SynthParameterId.masterVolume, _masterVolume);
    _engine.setParameter(SynthParameterId.masterMute, _isMasterMuted ? 1.0 : 0.0);
    
    // Filter parameters
    _engine.setParameter(SynthParameterId.filterCutoff, _filterCutoff);
    _engine.setParameter(SynthParameterId.filterResonance, _filterResonance);
    _engine.setParameter(SynthParameterId.filterType, _filterType.index.toDouble());
    
    // Envelope parameters
    _engine.setParameter(SynthParameterId.attackTime, _attackTime);
    _engine.setParameter(SynthParameterId.decayTime, _decayTime);
    _engine.setParameter(SynthParameterId.sustainLevel, _sustainLevel);
    _engine.setParameter(SynthParameterId.releaseTime, _releaseTime);
    
    // Effects parameters
    _engine.setParameter(SynthParameterId.reverbMix, _reverbMix);
    _engine.setParameter(SynthParameterId.delayTime, _delayTime);
    _engine.setParameter(SynthParameterId.delayFeedback, _delayFeedback);
    
    // Oscillator parameters
    for (int i = 0; i < _oscillators.length; i++) {
      final osc = _oscillators[i];
      final baseId = SynthParameterId.oscillatorType + (i * 10);
      
      _engine.setParameter(baseId, osc.type.index.toDouble());
      _engine.setParameter(baseId + 1, osc.frequency);
      _engine.setParameter(baseId + 2, osc.detune);
      _engine.setParameter(baseId + 3, osc.volume);
      _engine.setParameter(baseId + 4, osc.pan);
      _engine.setParameter(baseId + 5, osc.wavetableIndex.toDouble());
      _engine.setParameter(baseId + 6, osc.wavetablePosition);
    }
  }
  
  // Getters
  double get masterVolume => _masterVolume;
  bool get isMasterMuted => _isMasterMuted;
  AudioBackend get engine => _engine;
  List<OscillatorParameters> get oscillators => List.unmodifiable(_oscillators);
  double get filterCutoff => _filterCutoff;
  double get filterResonance => _filterResonance;
  FilterType get filterType => _filterType;
  double get attackTime => _attackTime;
  double get decayTime => _decayTime;
  double get sustainLevel => _sustainLevel;
  double get releaseTime => _releaseTime;
  double get reverbMix => _reverbMix;
  double get delayTime => _delayTime;
  double get delayFeedback => _delayFeedback;
  double get xyPadX => _xyPadX;
  double get xyPadY => _xyPadY;
  XYPadAssignment get xAxisAssignment => _xAxisAssignment;
  XYPadAssignment get yAxisAssignment => _yAxisAssignment;
  GranularParameters get granularParameters => _granularParameters;
  
  
  // Setters
  void setMasterVolume(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _masterVolume = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.masterVolume, value);
    
    notifyListeners();
  }
  
  void setMasterMuted(bool value) {
    _isMasterMuted = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.masterMute, value ? 1.0 : 0.0);
    
    notifyListeners();
  }
  
  void setFilterCutoff(double value) {
    if (value < 20) value = 20;
    if (value > 20000) value = 20000;
    _filterCutoff = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.filterCutoff, value);
    
    notifyListeners();
  }
  
  void setFilterResonance(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _filterResonance = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.filterResonance, value);
    
    notifyListeners();
  }
  
  void setFilterType(FilterType value) {
    _filterType = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.filterType, value.index.toDouble());
    
    notifyListeners();
  }
  
  void setAttackTime(double value) {
    if (value < 0.001) value = 0.001;
    if (value > 5) value = 5;
    _attackTime = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.attackTime, value);
    
    notifyListeners();
  }
  
  void setDecayTime(double value) {
    if (value < 0.001) value = 0.001;
    if (value > 5) value = 5;
    _decayTime = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.decayTime, value);
    
    notifyListeners();
  }
  
  void setSustainLevel(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _sustainLevel = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.sustainLevel, value);
    
    notifyListeners();
  }
  
  void setReleaseTime(double value) {
    if (value < 0.001) value = 0.001;
    if (value > 10) value = 10;
    _releaseTime = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.releaseTime, value);
    
    notifyListeners();
  }
  
  void setReverbMix(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _reverbMix = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.reverbMix, value);
    
    notifyListeners();
  }
  
  void setDelayTime(double value) {
    if (value < 0.01) value = 0.01;
    if (value > 2) value = 2;
    _delayTime = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.delayTime, value);
    
    notifyListeners();
  }
  
  void setDelayFeedback(double value) {
    if (value < 0) value = 0;
    if (value > 0.95) value = 0.95; // Prevent endless feedback loops
    _delayFeedback = value;
    
    // Update engine
    _engine.setParameter(SynthParameterId.delayFeedback, value);
    
    notifyListeners();
  }
  
  void setXYPadPosition(double x, double y) {
    _xyPadX = x.clamp(0, 1);
    _xyPadY = y.clamp(0, 1);
    
    // Apply XY pad mapping to target parameters
    _applyXYPadMapping();
    
    notifyListeners();
  }
  
  void setXAxisAssignment(XYPadAssignment assignment) {
    _xAxisAssignment = assignment;
    _applyXYPadMapping();
    notifyListeners();
  }
  
  void setYAxisAssignment(XYPadAssignment assignment) {
    _yAxisAssignment = assignment;
    _applyXYPadMapping();
    notifyListeners();
  }
  
  // Oscillator management
  void addOscillator() {
    _oscillators.add(OscillatorParameters());
    
    // Update oscillator in the engine
    _syncOscillatorsToEngine();
    
    notifyListeners();
  }
  
  void removeOscillator(int index) {
    if (_oscillators.length > 1 && index >= 0 && index < _oscillators.length) {
      _oscillators.removeAt(index);
      
      // Update oscillator in the engine
      _syncOscillatorsToEngine();
      
      notifyListeners();
    }
  }
  
  void updateOscillator(int index, OscillatorParameters params) {
    if (index >= 0 && index < _oscillators.length) {
      _oscillators[index] = params;
      
      // Update oscillator in the engine
      _syncOscillatorToEngine(index);
      
      notifyListeners();
    }
  }
  
  // Sync a specific oscillator to the engine
  void _syncOscillatorToEngine(int index) {
    if (!_engine.isInitialized || index >= _oscillators.length) return;
    
    final osc = _oscillators[index];
    final baseId = SynthParameterId.oscillatorType + (index * 10);
    
    _engine.setParameter(baseId, osc.type.index.toDouble());
    _engine.setParameter(baseId + 1, osc.frequency);
    _engine.setParameter(baseId + 2, osc.detune);
    _engine.setParameter(baseId + 3, osc.volume);
    _engine.setParameter(baseId + 4, osc.pan);
    _engine.setParameter(baseId + 5, osc.wavetableIndex.toDouble());
    _engine.setParameter(baseId + 6, osc.wavetablePosition);
  }
  
  // Sync all oscillators to the engine
  void _syncOscillatorsToEngine() {
    if (!_engine.isInitialized) return;
    
    for (int i = 0; i < _oscillators.length; i++) {
      _syncOscillatorToEngine(i);
    }
  }
  
  // Internal methods
  void _applyXYPadMapping() {
    // Map X axis parameter based on assignment
    switch (_xAxisAssignment) {
      case XYPadAssignment.filterCutoff:
        // Exponential mapping for filter cutoff (20Hz - 20kHz)
        setFilterCutoff(20 * pow(1000, _xyPadX));
        break;
      case XYPadAssignment.filterResonance:
        setFilterResonance(_xyPadX);
        break;
      case XYPadAssignment.oscillatorMix:
        if (_oscillators.length >= 2) {
          // Adjust mix between oscillators 0 and 1
          final osc0 = _oscillators[0];
          final osc1 = _oscillators[1];
          _oscillators[0] = osc0.copyWith(volume: 1 - _xyPadX);
          _oscillators[1] = osc1.copyWith(volume: _xyPadX);
          
          // Update oscillators in the engine
          _syncOscillatorToEngine(0);
          _syncOscillatorToEngine(1);
        }
        break;
      case XYPadAssignment.reverbMix:
        setReverbMix(_xyPadX);
        break;
    }
    
    // Map Y axis parameter based on assignment
    switch (_yAxisAssignment) {
      case XYPadAssignment.filterCutoff:
        // Exponential mapping for filter cutoff (20Hz - 20kHz) 
        setFilterCutoff(20 * pow(1000, _xyPadY));
        break;
      case XYPadAssignment.filterResonance:
        setFilterResonance(_xyPadY);
        break;
      case XYPadAssignment.oscillatorMix:
        if (_oscillators.length >= 2) {
          // Adjust mix between oscillators 0 and 1
          final osc0 = _oscillators[0];
          final osc1 = _oscillators[1];
          _oscillators[0] = osc0.copyWith(volume: 1 - _xyPadY);
          _oscillators[1] = osc1.copyWith(volume: _xyPadY);
          
          // Update oscillators in the engine
          _syncOscillatorToEngine(0);
          _syncOscillatorToEngine(1);
        }
        break;
      case XYPadAssignment.reverbMix:
        setReverbMix(_xyPadY);
        break;
    }
  }
  
  // MIDI note handling
  void noteOn(int note, int velocity) {
    if (_engine.isInitialized) {
      _engine.noteOn(0, note, velocity / 127.0);
    }
  }
  
  void noteOff(int note) {
    if (_engine.isInitialized) {
      _engine.noteOff(0);
    }
  }
  
  // Convert to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'masterVolume': _masterVolume,
      'isMasterMuted': _isMasterMuted,
      'oscillators': _oscillators.map((o) => o.toJson()).toList(),
      'filterCutoff': _filterCutoff,
      'filterResonance': _filterResonance,
      'filterType': _filterType.index,
      'attackTime': _attackTime,
      'decayTime': _decayTime,
      'sustainLevel': _sustainLevel,
      'releaseTime': _releaseTime,
      'reverbMix': _reverbMix,
      'delayTime': _delayTime,
      'delayFeedback': _delayFeedback,
      'xyPadX': _xyPadX,
      'xyPadY': _xyPadY,
      'xAxisAssignment': _xAxisAssignment.index,
      'yAxisAssignment': _yAxisAssignment.index,
      'granular': _granularParameters.toJson(),
    };
  }
  
  // Load from a JSON representation
  void loadFromJson(Map<String, dynamic> json) {
    // Load envelope if nested
    if (json['envelope'] != null) {
      final env = json['envelope'];
      _attackTime = env['attack'] ?? env['attackTime'] ?? 0.01;
      _decayTime = env['decay'] ?? env['decayTime'] ?? 0.1;
      _sustainLevel = env['sustain'] ?? env['sustainLevel'] ?? 0.7;
      _releaseTime = env['release'] ?? env['releaseTime'] ?? 0.5;
    } else {
      _attackTime = json['attackTime'] ?? 0.01;
      _decayTime = json['decayTime'] ?? 0.1;
      _sustainLevel = json['sustainLevel'] ?? 0.7;
      _releaseTime = json['releaseTime'] ?? 0.5;
    }
    
    // Load filter if nested
    if (json['filter'] != null) {
      final filter = json['filter'];
      _filterCutoff = filter['cutoff'] ?? filter['filterCutoff'] ?? 1000.0;
      _filterResonance = filter['resonance'] ?? filter['filterResonance'] ?? 0.5;
      _filterType = FilterType.values[filter['type'] ?? filter['filterType'] ?? 0];
    } else {
      _filterCutoff = json['filterCutoff'] ?? 1000.0;
      _filterResonance = json['filterResonance'] ?? 0.5;
      _filterType = FilterType.values[json['filterType'] ?? 0];
    }
    
    // Load effects if nested
    if (json['effects'] != null) {
      final effects = json['effects'];
      _reverbMix = effects['reverb'] ?? effects['reverbMix'] ?? 0.2;
      _delayTime = effects['delayTime'] ?? 0.5;
      _delayFeedback = effects['delayFeedback'] ?? 0.3;
    } else {
      _reverbMix = json['reverbMix'] ?? 0.2;
      _delayTime = json['delayTime'] ?? 0.5;
      _delayFeedback = json['delayFeedback'] ?? 0.3;
    }
    
    _masterVolume = json['masterVolume'] ?? 0.75;
    _isMasterMuted = json['isMasterMuted'] ?? false;
    
    _xyPadX = json['xyPadX'] ?? 0.5;
    _xyPadY = json['xyPadY'] ?? 0.5;
    _xAxisAssignment = XYPadAssignment.values[json['xAxisAssignment'] ?? 0];
    _yAxisAssignment = XYPadAssignment.values[json['yAxisAssignment'] ?? 1];
    
    // Load oscillators
    _oscillators.clear();
    final oscillatorsJson = json['oscillators'] as List<dynamic>?;
    if (oscillatorsJson != null && oscillatorsJson.isNotEmpty) {
      for (final oscJson in oscillatorsJson) {
        _oscillators.add(OscillatorParameters.fromJson(oscJson));
      }
    } else {
      _oscillators.add(OscillatorParameters()); // Default oscillator
    }
    
    // Load granular parameters
    if (json['granular'] != null) {
      _granularParameters.loadFromJson(json['granular']);
    }
    
    // Sync all parameters to the engine
    _syncAllParametersToEngine();
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Shut down the engine
    _engine.dispose();
    super.dispose();
  }
}

/// Parameters for a single oscillator
class OscillatorParameters {
  final OscillatorType type;
  final double frequency; // Hz
  final double detune; // cents
  final double volume; // 0-1
  final double pan; // -1 to 1
  final int wavetableIndex; // Index of current wavetable
  final double wavetablePosition; // Position within the wavetable (0-1)
  
  OscillatorParameters({
    this.type = OscillatorType.sine,
    this.frequency = 440.0, // A4
    this.detune = 0.0,
    this.volume = 0.5,
    this.pan = 0.0,
    this.wavetableIndex = 0,
    this.wavetablePosition = 0.0,
  });
  
  // Copy with new values
  OscillatorParameters copyWith({
    OscillatorType? type,
    double? frequency,
    double? detune,
    double? volume,
    double? pan,
    int? wavetableIndex,
    double? wavetablePosition,
  }) {
    return OscillatorParameters(
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      detune: detune ?? this.detune,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      wavetableIndex: wavetableIndex ?? this.wavetableIndex,
      wavetablePosition: wavetablePosition ?? this.wavetablePosition,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'frequency': frequency,
      'detune': detune,
      'volume': volume,
      'pan': pan,
      'wavetableIndex': wavetableIndex,
      'wavetablePosition': wavetablePosition,
    };
  }
  
  // Create from JSON
  factory OscillatorParameters.fromJson(Map<String, dynamic> json) {
    return OscillatorParameters(
      type: OscillatorType.values[json['type'] ?? 0],
      frequency: json['frequency'] ?? 440.0,
      detune: json['detune'] ?? 0.0,
      volume: json['volume'] ?? 0.5,
      pan: json['pan'] ?? 0.0,
      wavetableIndex: json['wavetableIndex'] ?? 0,
      wavetablePosition: json['wavetablePosition'] ?? 0.0,
    );
  }
}

/// Possible oscillator waveform types
enum OscillatorType {
  sine,
  square,
  triangle,
  sawtooth,
  noise,
  pulse,
  wavetable,
}

/// Types of filters
enum FilterType {
  lowPass,
  highPass,
  bandPass,
  notch,
  lowShelf,
  highShelf,
}

/// Possible XY pad parameter assignments
enum XYPadAssignment {
  filterCutoff,
  filterResonance,
  oscillatorMix,
  reverbMix,
}

// Helper method to avoid importing dart:math
double pow(double x, double exponent) {
  return x * exponent;
}