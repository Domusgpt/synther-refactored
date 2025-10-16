import 'package:flutter/foundation.dart';

import 'audio_backend.dart';
import 'basic_audio_backend.dart';
import 'web_audio_backend_stub.dart'
    if (dart.library.html) 'web_audio_backend.dart';

AudioBackend createAudioBackend() {
  if (kIsWeb) {
    return WebAudioBackend();
  }

  _SharedBackendRegistry.instance._retain();
  return _SharedBackendHandle(_SharedBackendRegistry.instance);
}

/// Internal registry that keeps a single backend instance alive while at
/// least one consumer holds on to it.  Once all consumers release their handle
/// a new backend is created on demand.
class _SharedBackendRegistry {
  _SharedBackendRegistry._();

  static final _SharedBackendRegistry instance = _SharedBackendRegistry._();

  BasicAudioBackend _backend = BasicAudioBackend();
  int _retainCount = 0;

  BasicAudioBackend get backend => _backend;

  void _retain() {
    _retainCount++;
  }

  void _release() {
    _retainCount = (_retainCount - 1).clamp(0, 1 << 31).toInt();
    if (_retainCount == 0) {
      _backend.dispose();
      _backend = BasicAudioBackend();
    }
  }

  @visibleForTesting
  void reset() {
    _backend.dispose();
    _backend = BasicAudioBackend();
    _retainCount = 0;
  }
}

class _SharedBackendHandle implements AudioBackend {
  _SharedBackendHandle(this._registry);

  final _SharedBackendRegistry _registry;
  bool _isDisposed = false;

  BasicAudioBackend get _backend => _registry.backend;

  @override
  bool get isInitialized => _backend.isInitialized;

  @override
  String? get lastError => _backend.lastError;

  @override
  Future<void> initialize() => _backend.initialize();

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _registry._release();
  }

  @override
  void noteOn(int voiceId, int note, double velocity) {
    _backend.noteOn(voiceId, note, velocity);
  }

  @override
  void noteOff(int voiceId) {
    _backend.noteOff(voiceId);
  }

  @override
  void setParameter(int parameterId, double value) {
    _backend.setParameter(parameterId, value);
  }

  @override
  double getParameter(int parameterId) {
    return _backend.getParameter(parameterId);
  }

  @override
  Map<String, double> getVisualizerData() {
    return _backend.getVisualizerData();
  }
}

/// Exposed for tests – allows resetting the shared backend between runs.
@visibleForTesting
void resetSharedAudioBackend() {
  _SharedBackendRegistry.instance.reset();
}
