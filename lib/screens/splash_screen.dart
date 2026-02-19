import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'CropWatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(
                      begin: 0.3,
                      delay: 300.ms,
                      duration: 500.ms,
                    ),
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  '24×7 Smart Crop Monitoring',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                
                const Spacer(flex: 2),
                
                // Loading indicator
                SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting to sensors...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                
                const SizedBox(height: 40),
                
                // Bottom info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sensors,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'IoT Powered Agriculture',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
