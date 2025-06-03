import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring and optimization utilities for the UI
class UIPerformanceMonitor {
  static UIPerformanceMonitor? _instance;
  static UIPerformanceMonitor get instance => _instance ??= UIPerformanceMonitor._();
  
  UIPerformanceMonitor._();
  
  // Frame timing tracking
  final List<Duration> _frameDurations = [];
  static const int _maxFrames = 120; // Track last 2 seconds at 60fps
  
  // Performance metrics
  double _currentFps = 60.0;
  double _averageFps = 60.0;
  int _droppedFrames = 0;
  
  // Callbacks
  final List<VoidCallback> _listeners = [];
  
  // Start monitoring
  void startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }
  
  // Stop monitoring
  void stopMonitoring() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
  }
  
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final duration = timing.totalSpan;
      _frameDurations.add(duration);
      
      // Keep only recent frames
      if (_frameDurations.length > _maxFrames) {
        _frameDurations.removeAt(0);
      }
      
      // Check for dropped frames (>16.67ms)
      if (duration > const Duration(milliseconds: 17)) {
        _droppedFrames++;
      }
    }
    
    _updateMetrics();
    _notifyListeners();
  }
  
  void _updateMetrics() {
    if (_frameDurations.isEmpty) return;
    
    // Calculate current FPS from last frame
    final lastDuration = _frameDurations.last;
    _currentFps = 1000000.0 / lastDuration.inMicroseconds;
    
    // Calculate average FPS
    final totalDuration = _frameDurations.fold<Duration>(
      Duration.zero,
      (total, duration) => total + duration,
    );
    final avgDuration = totalDuration.inMicroseconds / _frameDurations.length;
    _averageFps = 1000000.0 / avgDuration;
  }
  
  // Add listener for performance updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  // Getters
  double get currentFps => _currentFps;
  double get averageFps => _averageFps;
  int get droppedFrames => _droppedFrames;
  bool get isPerformant => _averageFps >= 55.0; // Allow slight variation
  
  // Reset metrics
  void reset() {
    _frameDurations.clear();
    _currentFps = 60.0;
    _averageFps = 60.0;
    _droppedFrames = 0;
  }
}

/// Widget that displays performance metrics overlay
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  
  const PerformanceOverlay({
    Key? key,
    required this.child,
    this.enabled = false,
  }) : super(key: key);
  
  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final _monitor = UIPerformanceMonitor.instance;
  
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _monitor.startMonitoring();
      _monitor.addListener(_onMetricsUpdate);
    }
  }
  
  @override
  void dispose() {
    _monitor.removeListener(_onMetricsUpdate);
    if (widget.enabled) {
      _monitor.stopMonitoring();
    }
    super.dispose();
  }
  
  void _onMetricsUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 40,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FPS: ${_monitor.currentFps.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: _monitor.isPerformant ? Colors.green : Colors.red,
                    ),
                  ),
                  Text('Avg: ${_monitor.averageFps.toStringAsFixed(1)}'),
                  Text('Drops: ${_monitor.droppedFrames}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Utility class for optimizing parameter updates
class ParameterUpdateBatcher {
  final Duration _batchDuration;
  final void Function(Map<String, double>) _onBatchUpdate;
  
  final Map<String, double> _pendingUpdates = {};
  Timer? _batchTimer;
  
  ParameterUpdateBatcher({
    Duration batchDuration = const Duration(milliseconds: 16), // 60fps
    required void Function(Map<String, double>) onBatchUpdate,
  })  : _batchDuration = batchDuration,
        _onBatchUpdate = onBatchUpdate;
  
  void updateParameter(String name, double value) {
    _pendingUpdates[name] = value;
    
    // Start or reset batch timer
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDuration, _flushBatch);
  }
  
  void _flushBatch() {
    if (_pendingUpdates.isNotEmpty) {
      final updates = Map<String, double>.from(_pendingUpdates);
      _pendingUpdates.clear();
      _onBatchUpdate(updates);
    }
  }
  
  void dispose() {
    _batchTimer?.cancel();
    _flushBatch(); // Flush any remaining updates
  }
}

/// Extension methods for performance optimization
extension PerformanceExtensions on Widget {
  /// Wrap widget in RepaintBoundary for performance
  Widget withRepaintBoundary() => RepaintBoundary(child: this);
  
  /// Wrap widget in performance monitoring overlay
  Widget withPerformanceOverlay({bool enabled = false}) => 
      PerformanceOverlay(child: this, enabled: enabled);
}