import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;
import '../../core/synth_parameters.dart';

/// A service for handling microphone input and processing audio in real-time.
///
/// This service manages microphone permissions, audio recording, and processing
/// the microphone input to extract audio features that can be used to control
/// the synthesizer parameters.
class MicrophoneService extends ChangeNotifier {
  // FlutterSound recorder
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  // Streaming subscription
  StreamSubscription? _recorderSubscription;
  
  // State
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _hasPermission = false;
  
  // Audio features
  double _volume = 0.0;
  double _pitch = 0.0;
  
  // Audio analysis settings
  bool _autoControlFilter = false;
  bool _autoControlOscillator = false;
  
  // Target parameters model for controlling synthesis
  SynthParametersModel? _parametersModel;
  
  // Constructor
  MicrophoneService({SynthParametersModel? parametersModel}) {
    _parametersModel = parametersModel;
    _initialize();
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  double get volume => _volume;
  double get pitch => _pitch;
  bool get autoControlFilter => _autoControlFilter;
  bool get autoControlOscillator => _autoControlOscillator;
  
  // Initialize the microphone service
  Future<void> _initialize() async {
    try {
      // Configure logging for troubleshooting (set to false for production)
      // TODO: Fix setLogLevel API change
      // await _recorder.setLogLevel(Level.info);
      
      // Open the recorder with proper initialization
      await _recorder.openRecorder();
      
      // Platform-specific initialization can be handled here if needed
      if (!kIsWeb) {
        if (Platform.isIOS || Platform.isAndroid) {
          // Some mobile devices might need additional configuration
        }
      } else {
        // Web platform requires special handling
        print('Web platform detected for microphone. Using web-specific handling');
        // Permission will be requested when startRecording is called
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = false;
      print('Error initializing microphone: $e');
      
      // Retry initialization after a delay if needed
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isInitialized) {
          _initialize();
        }
      });
    }
  }
  
  // Request microphone permission
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      // For web, we'll check for permission directly before recording
      try {
        _hasPermission = true; // We'll check this at recording time for web
        notifyListeners();
        return true;
      } catch (e) {
        print('Error requesting web microphone permission: $e');
        _hasPermission = false;
        notifyListeners();
        return false;
      }
    } else {
      // For native platforms, use the permission handler
      final status = await Permission.microphone.request();
      _hasPermission = status.isGranted;
      notifyListeners();
      return _hasPermission;
    }
  }
  
  // Start recording from the microphone
  Future<void> startRecording() async {
    if (!_isInitialized) {
      await _initialize();
    }
    
    if (!_hasPermission) {
      await requestPermission();
      if (!_hasPermission) {
        return; // Permission denied
      }
    }
    
    try {
      // Create a controller for the audio stream
      final StreamController<Uint8List> audioController = StreamController<Uint8List>();
      
      // Start recording with stream output
      await _recorder.startRecorder(
        toStream: audioController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100,
      );
      
      // Listen to the audio stream and process raw data
      audioController.stream.listen((audioData) {
        _processRawAudioData(audioData);
      });
      
      _recorderSubscription = _recorder.onProgress?.listen((event) {
        _processAudioData(event);
      });
      
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      print('Error starting microphone recording: $e');
    }
  }
  
  // Stop recording from the microphone
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      await _recorder.stopRecorder();
      _recorderSubscription?.cancel();
      _recorderSubscription = null;
      
      _isRecording = false;
      
      // Reset audio features
      _volume = 0.0;
      _pitch = 0.0;
      
      notifyListeners();
    } catch (e) {
      print('Error stopping microphone recording: $e');
    }
  }
  
  // Process audio data from the microphone
  void _processAudioData(RecordingDisposition event) {
    // Calculate volume (amplitude) from the decibel level
    // dB is logarithmic, we convert to linear amplitude (0-1 range)
    final double dbLevel = event.decibels ?? -160.0;
    final double normalizedDb = (dbLevel + 160.0) / 160.0; // Normalize to 0-1
    _volume = normalizedDb.clamp(0.0, 1.0);
    
    // Note: Pitch detection would require more complex FFT analysis
    // For now, we'll use a placeholder based on volume variations
    // In a real implementation, you'd use a proper pitch detection algorithm
    
    // Apply audio features to synth parameters if auto control is enabled
    _applyAudioFeaturesToSynth();
    
    notifyListeners();
  }
  
  void _processRawAudioData(Uint8List data) {
    // Process raw PCM data to calculate volume
    // This is a simple RMS calculation
    if (data.isEmpty) return;
    
    double sum = 0.0;
    int sampleCount = data.length ~/ 2; // 16-bit samples
    
    for (int i = 0; i < sampleCount; i++) {
      // Convert bytes to 16-bit signed integer
      int sample = (data[i * 2 + 1] << 8) | data[i * 2];
      if (sample > 32767) sample -= 65536; // Handle signed conversion
      
      // Normalize to -1.0 to 1.0 range
      double normalizedSample = sample / 32768.0;
      sum += normalizedSample * normalizedSample;
    }
    
    // Calculate RMS value
    double rms = sampleCount > 0 ? math.sqrt(sum / sampleCount) : 0.0;
    _volume = rms.clamp(0.0, 1.0);
    
    // Apply audio features to synth parameters if auto control is enabled
    _applyAudioFeaturesToSynth();
    
    notifyListeners();
  }
  
  // Apply detected audio features to synth parameters
  void _applyAudioFeaturesToSynth() {
    if (_parametersModel == null) return;
    
    if (_autoControlFilter) {
      // Map volume to filter cutoff (louder = brighter)
      final double cutoff = 20.0 + (_volume * 19980.0); // 20Hz - 20kHz
      _parametersModel!.setFilterCutoff(cutoff);
      
      // Map rapid volume changes to resonance
      // In a real implementation, you'd use a more sophisticated algorithm
      _parametersModel!.setFilterResonance(_volume);
    }
    
    if (_autoControlOscillator) {
      // Vary the oscillator mix based on volume
      if (_parametersModel!.oscillators.length >= 2) {
        // Update oscillator volumes through the model
        final osc0 = _parametersModel!.oscillators[0];
        final osc1 = _parametersModel!.oscillators[1];
        
        _parametersModel!.updateOscillator(0, osc0.copyWith(volume: 1.0 - _volume));
        _parametersModel!.updateOscillator(1, osc1.copyWith(volume: _volume));
      }
    }
  }
  
  // Toggle auto control for filter
  void toggleAutoControlFilter() {
    _autoControlFilter = !_autoControlFilter;
    notifyListeners();
  }
  
  // Toggle auto control for oscillator
  void toggleAutoControlOscillator() {
    _autoControlOscillator = !_autoControlOscillator;
    notifyListeners();
  }
  
  // Set the synth parameters model
  void setSynthParameters(SynthParametersModel model) {
    _parametersModel = model;
  }
  
  @override
  void dispose() {
    stopRecording();
    _recorder.closeRecorder();
    _recorderSubscription?.cancel();
    super.dispose();
  }
}