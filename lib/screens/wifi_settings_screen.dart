import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({super.key});

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ssidController;
  late TextEditingController _passwordController;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final field = context.read<FieldProvider>().selectedField;
    final settings = field?.settings ?? FieldSettings();
    _ssidController = TextEditingController(text: settings.wifiSsid);
    _passwordController = TextEditingController(text: settings.wifiPassword);
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveWifiSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final fieldProvider = context.read<FieldProvider>();
    final field = fieldProvider.selectedField;
    
    if (field == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No field selected')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final newSettings = field.settings.copyWith(
      wifiSsid: _ssidController.text.trim(),
      wifiPassword: _passwordController.text,
    );

    final success = await fieldProvider.updateFieldSettings(field.id, newSettings);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WiFi credentials updated. Microcontroller will sync on next heartbeat.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update WiFi settings'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device WiFi Setup'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.cardDark : AppTheme.cardLight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.wifi, color: AppTheme.primaryGreen, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Update Microcontroller WiFi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the credentials for the WiFi network you want your ESP8266 to connect to.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'WiFi Name (SSID)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ssidController,
                decoration: InputDecoration(
                  hintText: 'Enter SSID',
                  prefixIcon: const Icon(Icons.network_wifi),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                ),
                validator: (v) => v == null || v.isEmpty ? 'SSID is required' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'WiFi Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ensure the device is currently online to receive these new settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWifiSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'UPDATE DEVICE WIFI', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
