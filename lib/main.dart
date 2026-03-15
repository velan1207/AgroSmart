import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';

const FirebaseOptions _firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyC3XheBH60x7s2tlnmho2oDAIUD2WJsTMY',
  authDomain: 'fir-42101.firebaseapp.com',
  databaseURL: 'https://fir-42101-default-rtdb.firebaseio.com',
  projectId: 'fir-42101',
  storageBucket: 'fir-42101.firebasestorage.app',
  messagingSenderId: '493013331140',
  appId: '1:493013331140:web:1e4a92d64e2b3a5368ad91',
  measurementId: 'G-EPYEVC6H13',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseService = FirebaseService();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  bool firebaseReady = false;

  // Linux desktop uses a REST fallback because FlutterFire plugins are not
  // registered for Linux in this project.
  final useLinuxRestFallback =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  firebaseService.configureRestFallback(enabled: useLinuxRestFallback);

  // Initialize Firebase
  try {
    if (useLinuxRestFallback) {
      debugPrint('[App] Firebase plugins unavailable on Linux, using REST fallback');
      firebaseReady = true;
    } else {
    final requiresExplicitOptions = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (requiresExplicitOptions) {
      // Web and desktop platforms require explicit Firebase options.
      await Firebase.initializeApp(
        options: _firebaseOptions,
      );
    } else {
      // Android/iOS use google-services.json / GoogleService-Info.plist
      await Firebase.initializeApp();
    }
    debugPrint('[App] Firebase initialized successfully');
    firebaseReady = true;
    }
  } catch (e) {
    debugPrint('[App] Firebase initialization failed: $e');
    debugPrint('[App] Running in demo mode with mock data');
  }
  // Initialize Firebase service when cloud access is available.
  if (firebaseReady) {
    await firebaseService.initialize();
  }
  
  runApp(const CropMonitorApp());
}

class CropMonitorApp extends StatelessWidget {
  const CropMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FieldProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'CropWatch - Smart Crop Monitoring',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
