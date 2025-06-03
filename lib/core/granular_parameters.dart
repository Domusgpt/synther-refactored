import 'package:flutter/foundation.dart';
import 'audio_backend.dart';
import 'platform_audio_backend.dart';
import 'parameter_definitions.dart';

/// Granular synthesis parameter model
class GranularParameters extends ChangeNotifier {
  final AudioBackend _engine;
  
  // Constructor
  GranularParameters(this._engine);
  
  // Granular parameters
  bool _isActive = false;
  double _grainRate = 10.0;        // Grains per second
  double _grainDuration = 0.05;    // Duration in seconds
  double _position = 0.0;          // Position in source buffer (0-1)
  double _pitch = 1.0;             // Pitch shift
  double _amplitude = 1.0;         // Amplitude
  double _positionVariation = 0.0;
  double _pitchVariation = 0.0;
  double _durationVariation = 0.0;
  double _pan = 0.0;
  double _panVariation = 0.0;
  GrainWindowType _windowType = GrainWindowType.hann;
  
  // Getters
  bool get isActive => _isActive;
  double get grainRate => _grainRate;
  double get grainDuration => _grainDuration;
  double get position => _position;
  double get pitch => _pitch;
  double get amplitude => _amplitude;
  double get positionVariation => _positionVariation;
  double get pitchVariation => _pitchVariation;
  double get durationVariation => _durationVariation;
  double get pan => _pan;
  double get panVariation => _panVariation;
  GrainWindowType get windowType => _windowType;
  
  // Setters
  void setActive(bool value) {
    _isActive = value;
    _engine.setParameter(SynthParameterId.granularActive, value ? 1.0 : 0.0);
    notifyListeners();
  }
  
  void setGrainRate(double value) {
    _grainRate = value.clamp(0.1, 100.0);
    _engine.setParameter(SynthParameterId.granularGrainRate, _grainRate);
    notifyListeners();
  }
  
  void setGrainDuration(double value) {
    _grainDuration = value.clamp(0.001, 1.0);
    _engine.setParameter(SynthParameterId.granularGrainDuration, _grainDuration);
    notifyListeners();
  }
  
  void setPosition(double value) {
    _position = value.clamp(0.0, 1.0);
    _engine.setParameter(SynthParameterId.granularPosition, _position);
    notifyListeners();
  }
  
  void setPitch(double value) {
    _pitch = value.clamp(0.1, 4.0);
    _engine.setParameter(SynthParameterId.granularPitch, _pitch);
    notifyListeners();
  }
  
  void setAmplitude(double value) {
    _amplitude = value.clamp(0.0, 1.0);
    _engine.setParameter(SynthParameterId.granularAmplitude, _amplitude);
    notifyListeners();
  }
  
  void setPositionVariation(double value) {
    _positionVariation = value.clamp(0.0, 1.0);
    _engine.setParameter(SynthParameterId.granularPositionVar, _positionVariation);
    notifyListeners();
  }
  
  void setPitchVariation(double value) {
    _pitchVariation = value.clamp(0.0, 2.0);
    _engine.setParameter(SynthParameterId.granularPitchVar, _pitchVariation);
    notifyListeners();
  }
  
  void setDurationVariation(double value) {
    _durationVariation = value.clamp(0.0, 1.0);
    _engine.setParameter(SynthParameterId.granularDurationVar, _durationVariation);
    notifyListeners();
  }
  
  void setPan(double value) {
    _pan = value.clamp(-1.0, 1.0);
    _engine.setParameter(SynthParameterId.granularPan, _pan);
    notifyListeners();
  }
  
  void setPanVariation(double value) {
    _panVariation = value.clamp(0.0, 1.0);
    _engine.setParameter(SynthParameterId.granularPanVar, _panVariation);
    notifyListeners();
  }
  
  void setWindowType(GrainWindowType type) {
    _windowType = type;
    _engine.setParameter(SynthParameterId.granularWindowType, type.index.toDouble());
    notifyListeners();
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isActive': _isActive,
      'grainRate': _grainRate,
      'grainDuration': _grainDuration,
      'position': _position,
      'pitch': _pitch,
      'amplitude': _amplitude,
      'positionVariation': _positionVariation,
      'pitchVariation': _pitchVariation,
      'durationVariation': _durationVariation,
      'pan': _pan,
      'panVariation': _panVariation,
      'windowType': _windowType.index,
    };
  }
  
  // Load from JSON
  void loadFromJson(Map<String, dynamic> json) {
    _isActive = json['isActive'] ?? false;
    _grainRate = json['grainRate'] ?? 10.0;
    _grainDuration = json['grainDuration'] ?? 0.05;
    _position = json['position'] ?? 0.0;
    _pitch = json['pitch'] ?? 1.0;
    _amplitude = json['amplitude'] ?? 1.0;
    _positionVariation = json['positionVariation'] ?? 0.0;
    _pitchVariation = json['pitchVariation'] ?? 0.0;
    _durationVariation = json['durationVariation'] ?? 0.0;
    _pan = json['pan'] ?? 0.0;
    _panVariation = json['panVariation'] ?? 0.0;
    _windowType = GrainWindowType.values[json['windowType'] ?? 0];
    
    // Sync all parameters to engine
    setActive(_isActive);
    setGrainRate(_grainRate);
    setGrainDuration(_grainDuration);
    setPosition(_position);
    setPitch(_pitch);
    setAmplitude(_amplitude);
    setPositionVariation(_positionVariation);
    setPitchVariation(_pitchVariation);
    setDurationVariation(_durationVariation);
    setPan(_pan);
    setPanVariation(_panVariation);
    setWindowType(_windowType);
  }
}

