import 'utils/platform_check.dart';
import 'utils/web_audio_fix_stub.dart'
    if (dart.library.html) 'utils/web_audio_fix.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'morph_app.dart';
import 'core/synth_parameters.dart';
import 'core/audio_service.dart';

void main() async {
  // Initialize platform-specific error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };
  
  // Initialize web-specific error handlers
  WebAudioFix.initWebErrorHandlers();
  
  // Log startup information
  debugPrint('Starting Synther - Visual Synthesizer on ${PlatformCheck.platformName}');
  debugPrint('Morph-UI System Active');
  
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the audio service
  await AudioService.instance.initialize();
  
  // Create the synth parameters model, which will initialize the engine
  final synthParameters = SynthParametersModel();
  
  // Set up providers for state management
  runApp(
    MultiProvider(
      providers: [
        // Provide the synth parameters model which contains the engine reference
        ChangeNotifierProvider<SynthParametersModel>.value(value: synthParameters),
        // Add other providers as needed
      ],
      child: const MorphSynthesizerApp(), // Using Morph-UI version
    ),
  );
  
  // Add a shutdown hook
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Listen for app lifecycle changes to handle shutdown
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(synthParameters));
  });
}

/// Observer to handle app lifecycle events for proper cleanup
class AppLifecycleObserver extends WidgetsBindingObserver {
  final SynthParametersModel _synthParameters;
  
  AppLifecycleObserver(this._synthParameters);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is about to be terminated, dispose resources
      _synthParameters.dispose();
    } else if (state == AppLifecycleState.paused) {
      // App is in the background, we might want to pause audio processing here
      // For a future enhancement
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground again, possibly restart processing
      // For a future enhancement
    }
  }
}