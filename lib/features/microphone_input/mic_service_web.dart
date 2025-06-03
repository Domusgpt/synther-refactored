import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/synth_parameters.dart';
import '../../core/parameter_definitions.dart';
import 'dart:html' as html;
import 'dart:js' as js;

/// Web-specific implementation of microphone service
class MicrophoneService extends ChangeNotifier {
  // Audio context and analyzer
  dynamic _audioContext;
  dynamic _analyserNode;
  dynamic _sourceNode;
  final SynthParametersModel? _parametersModel;
  
  // Controls for auto parameters
  bool _autoControlFilter = false;
  bool _autoControlOscillator = false;
  
  // State
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _hasPermission = false;
  
  // Audio features
  double _volume = 0.0;
  double _pitch = 0.0;
  
  // FFT data
  List<int>? _fftData;
  Uint8List? _timeData;
  
  // Animation frame
  int? _animationFrameId;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  double get volume => _volume;
  double get pitch => _pitch;
  List<int>? get fftData => _fftData;
  
  // Constructor
  MicrophoneService({SynthParametersModel? parametersModel}) 
      : _parametersModel = parametersModel {
    _initializeWebAudio();
  }
  
  // Getters for auto-control properties
  bool get autoControlFilter => _autoControlFilter;
  bool get autoControlOscillator => _autoControlOscillator;
  
  // Methods to toggle auto-control properties
  void toggleAutoControlFilter() {
    _autoControlFilter = !_autoControlFilter;
    notifyListeners();
  }
  
  void toggleAutoControlOscillator() {
    _autoControlOscillator = !_autoControlOscillator;
    notifyListeners();
  }
  
  Future<void> _initializeWebAudio() async {
    try {
      // Create audio context
      final audioContextClass = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioContextClass != null) {
        _audioContext = js.JsObject(audioContextClass);
        _isInitialized = true;
        notifyListeners();
      } else {
        debugPrint('AudioContext not supported in this browser');
      }
    } catch (e) {
      debugPrint('Error initializing web audio: $e');
    }
  }
  
  Future<bool> requestPermission() async {
    try {
      // Request microphone permission using navigator.mediaDevices.getUserMedia via JS interop
      final mediaDevices = js.context['navigator']?['mediaDevices'];
      if (mediaDevices == null) {
        debugPrint('mediaDevices not available in this browser');
        return false;
      }
      
      final getUserMedia = mediaDevices.callMethod('getUserMedia', [
        js.JsObject.jsify({'audio': true, 'video': false}),
      ]);
      
      // Convert Promise to Future
      final completer = Completer<dynamic>();
      getUserMedia.callMethod('then', [
        js.allowInterop((stream) => completer.complete(stream)),
        js.allowInterop((error) => completer.completeError(error)),
      ]);
      
      final mediaStream = await completer.future;
      
      if (mediaStream != null) {
        _hasPermission = true;
        // Clean up the stream since we're just checking permissions
        final tracks = mediaStream['getTracks'].callMethod('call', [mediaStream]);
        if (tracks != null) {
          for (var i = 0; i < tracks['length']; i++) {
            final track = tracks[i];
            track.callMethod('stop');
          }
        }
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> startRecording() async {
    if (!_isInitialized || _isRecording) {
      return false;
    }
    
    // Check/request permission
    if (!_hasPermission) {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        return false;
      }
    }
    
    try {
      // Get microphone stream using JS interop
      final mediaDevices = js.context['navigator']?['mediaDevices'];
      if (mediaDevices == null) {
        debugPrint('mediaDevices not available in this browser');
        return false;
      }
      
      final getUserMedia = mediaDevices.callMethod('getUserMedia', [
        js.JsObject.jsify({'audio': true, 'video': false}),
      ]);
      
      // Convert Promise to Future
      final completer = Completer<dynamic>();
      getUserMedia.callMethod('then', [
        js.allowInterop((stream) => completer.complete(stream)),
        js.allowInterop((error) => completer.completeError(error)),
      ]);
      
      final mediaStream = await completer.future;
      
      if (mediaStream == null) {
        return false;
      }
      
      // Create source node
      _sourceNode = _audioContext.callMethod('createMediaStreamSource', [mediaStream]);
      
      // Create analyzer node
      _analyserNode = _audioContext.callMethod('createAnalyser');
      _analyserNode['fftSize'] = 2048;
      _analyserNode['smoothingTimeConstant'] = 0.8;
      
      // Connect nodes
      _sourceNode.callMethod('connect', [_analyserNode]);
      
      // Create buffers for analysis
      final frequencyBinCount = _analyserNode['frequencyBinCount'];
      _fftData = List<int>.filled(frequencyBinCount, 0);
      _timeData = Uint8List(_analyserNode['fftSize']);
      
      // Start analysis loop
      _startAnalysis();
      
      _isRecording = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }
  
  void _startAnalysis() {
    _animationFrameId = js.context['window'].callMethod('requestAnimationFrame', 
        [js.allowInterop((timestamp) => _analyzeAudio(timestamp))]);
  }
  
  void _analyzeAudio(num timestamp) {
    if (!_isRecording || _analyserNode == null) {
      return;
    }
    
    // Get frequency data
    final frequencyBinCount = _analyserNode['frequencyBinCount'];
    final uint8FrequencyData = Uint8List(frequencyBinCount);
    final frequencyDataArray = js.JsObject(js.context['Uint8Array'], [frequencyBinCount]);
    _analyserNode.callMethod('getByteFrequencyData', [frequencyDataArray]);
    
    // Copy data from JS array to Dart Uint8List
    for (var i = 0; i < frequencyBinCount; i++) {
      uint8FrequencyData[i] = frequencyDataArray[i];
    }
    
    // Get time domain data
    final fftSize = _analyserNode['fftSize'];
    _timeData = Uint8List(fftSize);
    final timeDataArray = js.JsObject(js.context['Uint8Array'], [fftSize]);
    _analyserNode.callMethod('getByteTimeDomainData', [timeDataArray]);
    
    // Copy data from JS array to Dart Uint8List
    for (var i = 0; i < fftSize; i++) {
      _timeData![i] = timeDataArray[i];
    }
    
    // Calculate volume (RMS)
    double sum = 0;
    for (int i = 0; i < uint8FrequencyData.length; i++) {
      sum += uint8FrequencyData[i] * uint8FrequencyData[i];
    }
    _volume = math.sqrt(sum / uint8FrequencyData.length) / 255.0;
    
    // Estimate pitch using zero crossings (simple approach)
    int zeroCrossings = 0;
    for (int i = 1; i < _timeData!.length; i++) {
      if ((_timeData![i - 1] < 128 && _timeData![i] >= 128) ||
          (_timeData![i - 1] >= 128 && _timeData![i] < 128)) {
        zeroCrossings++;
      }
    }
    
    // Calculate pitch from zero crossings (very approximate)
    if (zeroCrossings > 0) {
      // Sample rate / (2 * zero crossings) * (FFT size / sample rate)
      final sampleRate = _audioContext['sampleRate'];
      _pitch = (sampleRate / 2.0) * (zeroCrossings / _timeData!.length);
      // Limit to reasonable MIDI note range
      _pitch = _pitch.clamp(27.5, 4186.0); // A0 to C8
      
      // Update synth parameters if auto-control is enabled
      if (_parametersModel != null) {
        if (_autoControlFilter) {
          // Map volume to filter cutoff (0.0 to 1.0)
          _parametersModel!.engine.setParameter(
            SynthParameterId.filterCutoff, 
            500.0 + (_volume * 15000.0)
          );
        }
        
        if (_autoControlOscillator) {
          // Map pitch changes to oscillator type
          final normalizedPitch = ((_pitch - 27.5) / (4186.0 - 27.5)).clamp(0.0, 1.0);
          final oscType = (normalizedPitch * 3).floor(); // 0-3 for sine, triangle, square, saw
          _parametersModel!.engine.setParameter(SynthParameterId.oscillatorType, oscType.toDouble());
        }
      }
    }
    
    // Update FFT data for visualization
    _fftData = uint8FrequencyData.toList();
    
    // Notify listeners of data update
    notifyListeners();
    
    // Schedule next analysis
    _animationFrameId = js.context['window'].callMethod('requestAnimationFrame', 
        [js.allowInterop((timestamp) => _analyzeAudio(timestamp))]);
  }
  
  Future<bool> stopRecording() async {
    if (!_isRecording) {
      return false;
    }
    
    try {
      // Cancel animation frame
      if (_animationFrameId != null) {
        js.context['window'].callMethod('cancelAnimationFrame', [_animationFrameId]);
        _animationFrameId = null;
      }
      
      // Disconnect and clean up nodes
      if (_sourceNode != null) {
        _sourceNode.callMethod('disconnect');
        
        // Get and stop all tracks in the media stream
        final mediaStream = _sourceNode['mediaStream'];
        if (mediaStream != null) {
          final tracks = mediaStream['getTracks'].callMethod('call', [mediaStream]);
          if (tracks != null) {
            for (var i = 0; i < tracks['length']; i++) {
              final track = tracks[i];
              track.callMethod('stop');
            }
          }
        }
        
        _sourceNode = null;
      }
      
      if (_analyserNode != null) {
        _analyserNode.callMethod('disconnect');
        _analyserNode = null;
      }
      
      _isRecording = false;
      _volume = 0.0;
      _pitch = 0.0;
      _fftData = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return false;
    }
  }
  
  @override
  void dispose() {
    stopRecording();
    
    if (_audioContext != null) {
      _audioContext.callMethod('close');
      _audioContext = null;
    }
    
    super.dispose();
  }
}