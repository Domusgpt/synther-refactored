import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/vaporwave_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SyntherRefreshedApp());
}

class SyntherRefreshedApp extends StatelessWidget {
  const SyntherRefreshedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther VIB Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF9F45FF),
          surface: Color(0xFF0B0B17),
        ),
      ),
      home: const VaporwaveDashboardPage(),
    );
  }
}
