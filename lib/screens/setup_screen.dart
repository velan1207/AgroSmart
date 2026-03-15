import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../services/services.dart';
import '../models/models.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _userIdError;
  String? _nameError;

  Future<void> _completeSetup() async {
    setState(() {
      _userIdError = null;
      _nameError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _userIdController.text.trim();
      final nameInput = _nameController.text.trim();

      // 1. Validate user against Firebase
      final firebase = FirebaseService();

      if (!firebase.isAvailable) {
        setState(() {
          _userIdError = 'Cloud login is not available on this platform. Please use web/mobile build.';
          _isLoading = false;
        });
        return;
      }

      final existingProfile = await firebase.getUserProfile(userId);

      if (existingProfile == null) {
        setState(() {
          _userIdError = 'User not found. Please check your Monitoring Code.';
          _isLoading = false;
        });
        return;
      }

      // 2. Check if this is a first-time login (ESP32 created node, no real profile yet)
      final isFirstTimeUser = existingProfile.name == 'User';

      if (!isFirstTimeUser) {
        // Returning user — verify name matches (case-insensitive)
        if (existingProfile.name.toLowerCase() != nameInput.toLowerCase()) {
          setState(() {
            _nameError = 'Name does not match this Monitoring Code. Please check your name.';
            _isLoading = false;
          });
          return;
        }
      }

      // 3. Set User ID in settings
      final settings = context.read<SettingsProvider>();
      await settings.setUserId(userId);

      // 4. If first-time user, save their name as profile
      UserProfile profileToUse = existingProfile;
      if (isFirstTimeUser) {
        profileToUse = UserProfile(
          uid: userId,
          name: nameInput,
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
        );
        await firebase.updateUserProfile(profileToUse);
        debugPrint('[Setup] First-time profile saved for $userId');
      }

      // 5. Update UserProvider
      if (mounted) {
        context.read<UserProvider>().setProfile(profileToUse);

        // Reload data
        await Future.wait([
          context.read<FieldProvider>().loadFields(),
          context.read<AlertProvider>().initialize(settingsProvider: settings),
        ]);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Setup failed. ';
        if (e.toString().contains('network') || e.toString().contains('SocketException')) {
          errorMessage += 'No internet connection. Please check your network.';
        } else {
          errorMessage += '$e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.critical,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 568 ? (screenWidth - 520) / 2 : 24.0,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo/Icon
                Center(
                  child: const AppLogo(
                    size: 120,
                    borderRadius: 60,
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  'Welcome to AgroSmart',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Enter your agricultural monitoring code to begin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 48),

                // User ID (Code) Field
                _buildTextField(
                  controller: _userIdController,
                  label: 'Monitoring Code (User ID)',
                  hint: 'Enter your unique device code',
                  icon: Icons.vpn_key,
                  errorText: _userIdError,
                  validator: (v) => v!.isEmpty ? 'Code is required' : null,
                  onChanged: (_) => setState(() => _userIdError = null),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                const SizedBox(height: 20),

                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Farmer Name',
                  hint: 'Enter your full name',
                  icon: Icons.person,
                  errorText: _nameError,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  onChanged: (_) => setState(() => _nameError = null),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                
                const SizedBox(height: 48),

                // Continue Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Login / Get Started',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 24),
                Text(
                  'Your data is securely stored in the cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        errorStyle: const TextStyle(color: AppTheme.critical),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        filled: true,
        fillColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        labelStyle: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorText != null ? AppTheme.critical : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorText != null ? AppTheme.critical : AppTheme.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.critical, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.critical, width: 2),
        ),
      ),
    );
  }
}
