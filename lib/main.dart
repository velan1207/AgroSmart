import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('[App] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[App] Firebase initialization failed: $e');
    debugPrint('[App] Running in demo mode with mock data');
  }
  
  // Initialize Firebase service
  await FirebaseService().initialize();
  
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
