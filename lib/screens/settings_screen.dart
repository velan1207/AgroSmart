import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'profile_edit_screen.dart';
import 'threshold_settings_screen.dart';
import 'wifi_settings_screen.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showUid = false;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              _buildProfileSection(context),
              const SizedBox(height: 24),
              
              // Appearance
              _buildSectionTitle(context, settingsProvider.tr('appearance')),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.dark_mode,
                title: settingsProvider.tr('dark_mode'),
                subtitle: 'Enable dark theme',
                trailing: Switch(
                  value: settingsProvider.isDarkMode,
                  onChanged: (_) => settingsProvider.toggleDarkMode(),
                  activeColor: AppTheme.primaryGreen,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 24),
              
              // Notifications
              _buildSectionTitle(context, settingsProvider.tr('notifications')),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.notifications,
                title: settingsProvider.tr('push_notifications'),
                subtitle: 'Receive alert notifications',
                trailing: Switch(
                  value: settingsProvider.notificationsEnabled,
                  onChanged: (_) => settingsProvider.toggleNotifications(),
                  activeColor: AppTheme.primaryGreen,
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.warning_amber,
                title: 'Critical Alerts Only',
                subtitle: 'Only notify for critical issues',
                trailing: Switch(
                  value: settingsProvider.criticalAlertsOnly,
                  onChanged: (value) => settingsProvider.setCriticalAlertsOnly(value),
                  activeColor: AppTheme.primaryGreen,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 24),
              
              // Hardware Status
              _buildSectionTitle(context, settingsProvider.tr('hardware_status')),
              const SizedBox(height: 12),
               _buildHardwareStatusCard(context),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.wifi,
                title: 'WiFi Configuration',
                subtitle: 'Update device SSID & Password',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WifiSettingsScreen()),
                  );
                },
              ).animate().fadeIn(delay: 225.ms, duration: 300.ms),
              const SizedBox(height: 24),
              
              // Units & Preferences
              _buildSectionTitle(context, settingsProvider.tr('units_preferences')),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.thermostat,
                title: settingsProvider.tr('temperature_unit'),
                subtitle: settingsProvider.temperatureUnit == 'celsius' ? 'Celsius (°C)' : 'Fahrenheit (°F)',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTemperatureUnitPicker(context, settingsProvider),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.refresh,
                title: settingsProvider.tr('refresh_interval'),
                subtitle: '${settingsProvider.refreshInterval} seconds',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRefreshIntervalPicker(context, settingsProvider),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.language,
                title: settingsProvider.tr('language'),
                subtitle: _getLanguageLabel(settingsProvider.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context, settingsProvider),
              ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
              const SizedBox(height: 24),
              
              // About
              _buildSectionTitle(context, settingsProvider.tr('about')),
              const SizedBox(height: 12),
               _buildSettingCard(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              const SizedBox(height: 24),

              // Developer Info / Sync Info
              _buildSectionTitle(context, 'Device Sync Info'),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.fingerprint,
                title: 'User ID (UID)',
                subtitle: _showUid ? context.read<UserProvider>().profile?.uid ?? 'Not logged in' : 'Tap to show UID',
                trailing: Icon(_showUid ? Icons.visibility_off : Icons.visibility),
                onTap: () => setState(() => _showUid = !_showUid),
              ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Copy this UID to your ESP8266 code to sync your hardware with your account.',
                  style: TextStyle(
                    fontSize: 12,
                    color: (Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Crop Management
              _buildSectionTitle(context, 'Crop Management'),
              const SizedBox(height: 12),
              _buildCropManagementCard(context),
              const SizedBox(height: 24),

              // Danger Zone
              _buildSectionTitle(context, 'Data'),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.restore,
                title: settingsProvider.tr('reset_settings'),
                subtitle: settingsProvider.tr('restore_defaults'),
                trailing: const Icon(Icons.chevron_right),
                iconColor: AppTheme.warning,
                onTap: () => _showResetConfirmation(context, settingsProvider),
              ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.logout,
                title: 'Switch User / Reset Code',
                subtitle: 'Logout and use a different Monitoring Code',
                trailing: const Icon(Icons.chevron_right),
                iconColor: AppTheme.critical,
                onTap: () => _showLogoutConfirmation(context, settingsProvider),
              ).animate().fadeIn(delay: 575.ms, duration: 300.ms),
              const SizedBox(height: 24),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHardwareStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldProvider = context.watch<FieldProvider>();
    final isOnline = fieldProvider.isHardwareOnline;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: Border.all(
          color: isOnline 
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOnline ? AppTheme.success : AppTheme.error)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOnline ? Icons.sensors : Icons.sensors_off,
                  color: isOnline ? AppTheme.success : AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP8266 Sensor Hub',
                      style: TextStyle(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? AppTheme.success : AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: isOnline ? AppTheme.success : AppTheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isOnline ? AppTheme.success : AppTheme.info).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isOnline ? AppTheme.success : AppTheme.info,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isOnline 
                      ? 'Hardware is actively sending data (Heartbeat active).' 
                      : 'Hardware is not responding. Check ESP8266 power and WiFi connection.',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 225.ms, duration: 300.ms);
  }

  Widget _buildProfileSection(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final fieldProvider = context.watch<FieldProvider>();
    final fieldCount = fieldProvider.fields.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fieldCount fields connected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: -0.1,
          duration: 400.ms,
        );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'english':
        return 'English';
      case 'hindi':
        return 'हिंदी (Hindi)';
      case 'tamil':
        return 'தமிழ் (Tamil)';
      case 'telugu':
        return 'తెలుగు (Telugu)';
      default:
        return 'English';
    }
  }

  void _showTemperatureUnitPicker(BuildContext context, SettingsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperature Unit',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              context: context,
              title: 'Celsius (°C)',
              isSelected: provider.temperatureUnit == 'celsius',
              onTap: () {
                provider.setTemperatureUnit('celsius');
                Navigator.pop(context);
              },
            ),
            _buildOptionTile(
              context: context,
              title: 'Fahrenheit (°F)',
              isSelected: provider.temperatureUnit == 'fahrenheit',
              onTap: () {
                provider.setTemperatureUnit('fahrenheit');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRefreshIntervalPicker(BuildContext context, SettingsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final intervals = [3, 5, 10, 15, 30, 60];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refresh Interval',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...intervals.map((interval) => _buildOptionTile(
              context: context,
              title: interval < 60 ? '$interval seconds' : '1 minute',
              isSelected: provider.refreshInterval == interval,
              onTap: () {
                provider.setRefreshInterval(interval);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.tr('language'),
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your preferred language',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ...provider.availableLanguages.map((lang) => _buildLanguageTile(
              context: context,
              code: lang['code']!,
              name: lang['name']!,
              nativeName: lang['nativeName']!,
              isSelected: provider.languageCode == lang['code'],
              onTap: () {
                provider.setLanguageCode(lang['code']!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to ${lang['nativeName']}'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String code,
    required String name,
    required String nativeName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryGreen, width: 2)
              : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  code.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      color: isSelected 
                          ? AppTheme.primaryGreen
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryGreen)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected 
                      ? AppTheme.primaryGreen
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Reset Settings?',
          style: TextStyle(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        content: Text(
          'This will restore all settings to their default values. This action cannot be undone.',
          style: TextStyle(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildCropManagementCard(BuildContext context) {
    final fieldProvider = context.watch<FieldProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final selectedField = fieldProvider.selectedField;
    if (selectedField == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          'No field selected to manage crops.',
          style: TextStyle(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSettingCard(
          context: context,
          icon: Icons.edit,
          title: 'Field Name',
          subtitle: selectedField.name,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFieldNameEditor(context, fieldProvider, selectedField),
        ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
        const SizedBox(height: 12),
        _buildSettingCard(
          context: context,
          icon: Icons.grass,
          title: 'Crop Type',
          subtitle: selectedField.cropType,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showCropPicker(context, fieldProvider, selectedField),
        ).animate().fadeIn(delay: 600.ms, duration: 300.ms),
        const SizedBox(height: 12),
        _buildSettingCard(
          context: context,
          icon: Icons.calendar_today,
          title: 'Date of Planting',
          subtitle: selectedField.plantingDate != null 
              ? "${selectedField.plantingDate!.day}/${selectedField.plantingDate!.month}/${selectedField.plantingDate!.year}"
              : 'Not set',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDatePicker(context, fieldProvider, selectedField),
        ).animate().fadeIn(delay: 650.ms, duration: 300.ms),
        const SizedBox(height: 12),
        _buildSettingCard(
          context: context,
          icon: Icons.tune,
          title: 'Thresholds & Safety',
          subtitle: 'Edit min/max limits for sensors',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ThresholdSettingsScreen()),
            );
          },
        ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
      ],
    );
  }

  void _showCropPicker(BuildContext context, FieldProvider provider, Field field) {
    final crops = ['Paddy', 'Groundnut', 'Wheat', 'Maize', 'Sugarcane', 'Cotton'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Crop Type',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: crops.length,
                itemBuilder: (context, index) {
                  final crop = crops[index];
                  return _buildOptionTile(
                    context: context,
                    title: crop,
                    isSelected: field.cropType.toLowerCase() == crop.toLowerCase(),
                    onTap: () {
                      provider.updateField(
                        field.id,
                        name: field.name,
                        cropType: crop,
                        location: field.location,
                        plantingDate: field.plantingDate,
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, FieldProvider provider, Field field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: field.plantingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
              ? ColorScheme.dark(
                  primary: AppTheme.primaryGreen,
                  onPrimary: Colors.white,
                  surface: AppTheme.surfaceDark,
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: AppTheme.primaryGreen,
                  onPrimary: Colors.white,
                  surface: AppTheme.surfaceLight,
                  onSurface: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.updateField(
        field.id,
        name: field.name,
        cropType: field.cropType,
        location: field.location,
        plantingDate: picked,
      );
    }
  }

  void _showFieldNameEditor(BuildContext context, FieldProvider provider, Field field) {
    final controller = TextEditingController(text: field.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        title: Text(
          'Edit Field Name',
          style: TextStyle(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Main Field',
            hintStyle: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateField(
                  field.id,
                  name: controller.text.trim(),
                  cropType: field.cropType,
                  location: field.location,
                  plantingDate: field.plantingDate,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedDataCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isSeeding = false;

        return _buildSettingCard(
          context: context,
          icon: Icons.data_saver_on,
          title: 'Seed Dummy Data',
          subtitle: 'Insert sample user and crop data',
          trailing: isSeeding 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow),
          iconColor: Colors.blue,
          onTap: isSeeding ? null : () async {
            setState(() => isSeeding = true);
            try {
              await FirebaseService().seedDummyData();
              await context.read<FieldProvider>().loadFields();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dummy data inserted successfully!'), backgroundColor: AppTheme.success),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error seeding data: $e'), backgroundColor: AppTheme.error),
                );
              }
            } finally {
              if (context.mounted) setState(() => isSeeding = false);
            }
          },
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, SettingsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Reset Monitoring Code?'),
        content: const Text('This will log you out and require you to enter your Monitoring Code again. All your settings will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Clear other providers first
              context.read<FieldProvider>().clear();
              context.read<AlertProvider>().clearAll();
              
              // Then reset settings (this will trigger navigation check in HomeScreen)
              await provider.resetToDefaults();
              
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
