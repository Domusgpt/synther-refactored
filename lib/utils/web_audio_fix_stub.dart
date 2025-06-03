/// Stub implementation for non-web platforms
class WebAudioFix {
  static void initWebErrorHandlers() {
    // No-op on non-web platforms
  }
  
  static void logToConsole(String message) {
    print(message);
  }
}