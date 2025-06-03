// Export the platform-specific implementation
export 'visualizer_bridge_widget_stub.dart'
    if (dart.library.html) 'visualizer_bridge_widget_web.dart';