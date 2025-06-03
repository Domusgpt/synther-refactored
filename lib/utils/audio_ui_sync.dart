import 'dart:async';
import 'package:flutter/material.dart';
import '../core/synth_parameters.dart';
import '../core/audio_backend.dart';

/// Manages synchronization between audio engine and UI updates
class AudioUISyncManager {
  static AudioUISyncManager? _instance;
  static AudioUISyncManager get instance => _instance ??= AudioUISyncManager._();
  
  AudioUISyncManager._();
  
  // Audio engine status
  bool _isAudioInitialized = false;
  AudioEngineStatus _engineStatus = AudioEngineStatus.uninitialized;
  String? _lastError;
  
  // Listeners
  final List<VoidCallback> _statusListeners = [];
  
  // Parameter update queue for thread-safe updates
  final List<ParameterUpdate> _updateQueue = [];
  Timer? _updateTimer;
  
  // Initialize monitoring
  void initialize(AudioBackend engine) {
    // Start periodic status check
    Timer.periodic(const Duration(milliseconds: 100), (_) {
      _checkEngineStatus(engine);
    });
  }
  
  void _checkEngineStatus(AudioBackend engine) {
    final wasInitialized = _isAudioInitialized;
    _isAudioInitialized = engine.isInitialized;
    
    if (wasInitialized != _isAudioInitialized) {
      _notifyStatusListeners();
    }
  }
  
  // Queue parameter update for audio thread
  void queueParameterUpdate(int parameterId, double value) {
    _updateQueue.add(ParameterUpdate(parameterId, value));
    
    // Process queue on next frame
    _updateTimer?.cancel();
    _updateTimer = Timer(Duration.zero, _processUpdateQueue);
  }
  
  void _processUpdateQueue() {
    if (_updateQueue.isEmpty) return;
    
    // Process all queued updates
    final updates = List<ParameterUpdate>.from(_updateQueue);
    _updateQueue.clear();
    
    // Apply updates in batch
    for (final update in updates) {
      // This would be sent to audio thread
      debugPrint('Audio update: param ${update.parameterId} = ${update.value}');
    }
  }
  
  // Status listeners
  void addStatusListener(VoidCallback listener) {
    _statusListeners.add(listener);
  }
  
  void removeStatusListener(VoidCallback listener) {
    _statusListeners.remove(listener);
  }
  
  void _notifyStatusListeners() {
    for (final listener in _statusListeners) {
      listener();
    }
  }
  
  // Getters
  bool get isAudioInitialized => _isAudioInitialized;
  AudioEngineStatus get engineStatus => _engineStatus;
  String? get lastError => _lastError;
  
  // Set error state
  void setError(String error) {
    _lastError = error;
    _engineStatus = AudioEngineStatus.error;
    _notifyStatusListeners();
  }
  
  void clearError() {
    _lastError = null;
    _engineStatus = AudioEngineStatus.running;
    _notifyStatusListeners();
  }
}

/// Represents a parameter update
class ParameterUpdate {
  final int parameterId;
  final double value;
  
  ParameterUpdate(this.parameterId, this.value);
}

/// Audio engine status enum
enum AudioEngineStatus {
  uninitialized,
  initializing,
  running,
  error,
  stopped,
}

/// Widget that shows audio engine status
class AudioEngineStatusWidget extends StatefulWidget {
  const AudioEngineStatusWidget({Key? key}) : super(key: key);
  
  @override
  State<AudioEngineStatusWidget> createState() => _AudioEngineStatusWidgetState();
}

class _AudioEngineStatusWidgetState extends State<AudioEngineStatusWidget> {
  final _syncManager = AudioUISyncManager.instance;
  
  @override
  void initState() {
    super.initState();
    _syncManager.addStatusListener(_onStatusUpdate);
  }
  
  @override
  void dispose() {
    _syncManager.removeStatusListener(_onStatusUpdate);
    super.dispose();
  }
  
  void _onStatusUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final status = _syncManager.engineStatus;
    final error = _syncManager.lastError;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case AudioEngineStatus.uninitialized:
        statusColor = Colors.grey;
        statusText = 'Audio not initialized';
        statusIcon = Icons.radio_button_unchecked;
        break;
      case AudioEngineStatus.initializing:
        statusColor = Colors.orange;
        statusText = 'Initializing audio...';
        statusIcon = Icons.hourglass_empty;
        break;
      case AudioEngineStatus.running:
        statusColor = Colors.green;
        statusText = 'Audio engine active';
        statusIcon = Icons.check_circle;
        break;
      case AudioEngineStatus.error:
        statusColor = Colors.red;
        statusText = error ?? 'Audio error';
        statusIcon = Icons.error;
        break;
      case AudioEngineStatus.stopped:
        statusColor = Colors.grey;
        statusText = 'Audio stopped';
        statusIcon = Icons.stop_circle;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Mixin for widgets that need audio-UI synchronization
mixin AudioUISyncMixin<T extends StatefulWidget> on State<T> {
  final _syncManager = AudioUISyncManager.instance;
  
  // Override to handle audio status changes
  void onAudioStatusChanged(AudioEngineStatus status) {}
  
  // Override to handle audio errors
  void onAudioError(String error) {}
  
  @override
  void initState() {
    super.initState();
    _syncManager.addStatusListener(_handleStatusUpdate);
  }
  
  @override
  void dispose() {
    _syncManager.removeStatusListener(_handleStatusUpdate);
    super.dispose();
  }
  
  void _handleStatusUpdate() {
    if (!mounted) return;
    
    onAudioStatusChanged(_syncManager.engineStatus);
    
    if (_syncManager.engineStatus == AudioEngineStatus.error) {
      final error = _syncManager.lastError;
      if (error != null) {
        onAudioError(error);
      }
    }
  }
  
  // Helper method to safely update audio parameters
  void updateAudioParameter(int parameterId, double value) {
    if (_syncManager.isAudioInitialized) {
      _syncManager.queueParameterUpdate(parameterId, value);
    } else {
      debugPrint('Warning: Audio not initialized, parameter update skipped');
    }
  }
}