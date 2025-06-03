// Export the appropriate implementation based on the platform
export 'preset_manager.dart'
  if (dart.library.html) 'preset_manager_web.dart';