// Export the appropriate implementation based on the platform
export 'mic_service.dart'
  if (dart.library.html) 'mic_service_web.dart';