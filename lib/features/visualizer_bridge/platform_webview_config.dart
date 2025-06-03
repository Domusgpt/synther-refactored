import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Platform-specific WebView configuration
class PlatformWebViewConfig {
  /// Configure WebView settings for optimal visualizer performance
  static void configureForVisualizer(WebViewController controller) {
    // Common settings for all platforms
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)); // Transparent
    
    // Platform-specific optimizations
    if (Platform.isAndroid) {
      // Android-specific configuration
      final androidParams = controller.platform as AndroidWebViewController;
      androidParams.setMediaPlaybackRequiresUserGesture(false);
      
      // Enable debugging in debug mode
      if (kDebugMode) {
        AndroidWebViewController.enableDebugging(true);
      }
    } else if (Platform.isIOS) {
      // iOS-specific configuration
      final iosParams = controller.platform as WebKitWebViewController;
      // Note: setAllowsInlineMediaPlayback may need to be set during creation
    }
  }
}