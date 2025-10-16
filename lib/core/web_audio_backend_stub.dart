import 'audio_backend.dart';

/// Placeholder WebAudioBackend used on platforms where the real implementation
/// is unavailable. The class intentionally throws when used so we never
/// accidentally rely on the stub at runtime.
class WebAudioBackend implements AudioBackend {
  const WebAudioBackend();

  Never _unsupported() {
    throw UnsupportedError('WebAudioBackend is only available on web builds.');
  }

  @override
  bool get isInitialized => false;

  @override
  String? get lastError => 'WebAudioBackend is not supported on this platform.';

  @override
  Future<void> initialize() async => _unsupported();

  @override
  void dispose() {}

  @override
  void noteOn(int voiceId, int note, double velocity) => _unsupported();

  @override
  void noteOff(int voiceId) => _unsupported();

  @override
  void setParameter(int parameterId, double value) => _unsupported();

  @override
  double getParameter(int parameterId) => _unsupported();

  @override
  Map<String, double> getVisualizerData() => _unsupported();
}
