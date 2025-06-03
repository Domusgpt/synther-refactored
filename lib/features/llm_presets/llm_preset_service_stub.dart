// Stub implementation for conditional imports
export 'llm_preset_service.dart'
    if (dart.library.html) 'llm_preset_service_web.dart';
