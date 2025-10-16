import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/audio_engine.dart';
import 'ui/vaporwave_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Lock to portrait for optimal touch interface
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Request audio permissions immediately
  await _requestAudioPermissions();
  
  runApp(const HolographicSynthApp());
}

Future<void> _requestAudioPermissions() async {
  debugPrint('🎤 Requesting audio permissions...');
  
  try {
    // Request microphone permission for audio processing
    final micStatus = await Permission.microphone.request();
    debugPrint('Microphone permission: $micStatus');
    
    if (micStatus.isGranted) {
      debugPrint('✅ Audio permissions granted!');
    } else {
      debugPrint('❌ Audio permissions denied');
    }
  } catch (e) {
    debugPrint('⚠ Permission request error: $e');
  }
}

class HolographicSynthApp extends StatelessWidget {
  const HolographicSynthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AudioEngine(),
      child: MaterialApp(
        title: 'Holographic Synth Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FFFF),
            secondary: Color(0xFFFF00FF),
            surface: Color(0xFF000010),
            background: Color(0xFF000000),
          ),
          fontFamily: 'monospace',
        ),
        home: const HolographicSynthHome(),
      ),
    );
  }
}

class HolographicSynthHome extends StatefulWidget {
  const HolographicSynthHome({super.key});

  @override
  State<HolographicSynthHome> createState() => _HolographicSynthHomeState();
}

class _HolographicSynthHomeState extends State<HolographicSynthHome>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudioEngine();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audioEngine = context.read<AudioEngine>();
    
    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background - pause audio gracefully
        debugPrint('🎵 App paused - audio engine standby');
        break;
      case AppLifecycleState.resumed:
        // App returns to foreground - resume audio
        debugPrint('🎵 App resumed - audio engine active');
        break;
      case AppLifecycleState.detached:
        // App is being killed - cleanup
        audioEngine.dispose();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeAudioEngine() async {
    final audioEngine = context.read<AudioEngine>();
    
    try {
      debugPrint('🎵 Initializing Holographic Audio Engine...');
      final success = await audioEngine.initialize();
      
      if (success) {
        debugPrint('✅ Holographic Audio Engine Ready!');
        
        // Set up initial parameters for vaporwave aesthetic
        await audioEngine.setMasterVolume(0.75);
        await audioEngine.setFilterCutoff(1200);
        await audioEngine.setFilterResonance(0.4);
        await audioEngine.setReverbMix(0.3);
        
        debugPrint('🌈 Vaporwave parameters initialized');
      } else {
        debugPrint('❌ Audio engine initialization failed');
        _showAudioErrorDialog();
      }
    } catch (e) {
      debugPrint('❌ Audio engine error: $e');
      _showAudioErrorDialog();
    }
  }

  void _showAudioErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001122),
        title: const Text(
          'AUDIO ENGINE OFFLINE',
          style: TextStyle(
            color: Color(0xFF00FFFF),
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          'The holographic audio engine could not initialize. '
          'Visual interface will still function, but no sound will be produced.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CONTINUE',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AudioEngine>(
        builder: (context, audioEngine, child) {
          return Stack(
            children: [
              // Main vaporwave interface
              const VaporwaveInterface(),
              
              // Startup overlay with fade out
              if (!audioEngine.isInitialized)
                _buildStartupOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStartupOverlay() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated holographic logo
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Color(0xFF00FFFF),
            ),
            SizedBox(height: 32),
            
            Text(
              'HOLOGRAPHIC',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 36,
                fontWeight: FontWeight.w100,
                letterSpacing: 8,
              ),
            ),
            Text(
              'SYNTHESIZER',
              style: TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 48),
            
            CircularProgressIndicator(
              color: Color(0xFF00FFFF),
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            
            Text(
              'INITIALIZING 4D AUDIO MATRIX',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}