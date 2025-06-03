import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Utility class to fix common Web Audio issues
class WebAudioFix {
  /// Initialize and debug the audio context on web
  static void debugAudioContext(dynamic audioContext) {
    if (kIsWeb) {
      try {
        js.context.callMethod('debugAudioContext', [audioContext]);
      } catch (e) {
        debugPrint('Error calling debugAudioContext: $e');
      }
    }
  }
  
  /// Add web-specific exception handlers
  static void initWebErrorHandlers() {
    if (kIsWeb) {
      // We can't do much more than the JS error handlers in index.html
      debugPrint('Web error handlers initialized');
    }
  }
  
  /// Log web console message
  static void logToConsole(String message) {
    if (kIsWeb) {
      try {
        js.context.callMethod('console.log', ['[Flutter] $message']);
      } catch (e) {
        debugPrint('Error logging to console: $e');
      }
    } else {
      debugPrint(message);
    }
  }
}
