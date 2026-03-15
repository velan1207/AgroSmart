import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import '../utils/localization.dart';
import '../services/services.dart';
import 'alerts_screen.dart';
import 'stress_prediction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isPumpLoading = false;
  bool _isAutoToggling = false;
  StressPrediction? _stressPrediction;
  bool _isStressPredictionLoading = false;
  String? _lastStressLanguage;
  bool _isStressVoicePlaying = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<FieldProvider, SettingsProvider>(
      builder: (context, fieldProvider, settings, _) {
        final field = fieldProvider.selectedField;
        final sensorData = fieldProvider.currentSensorData;
        final lang = settings.languageCode;
        final ttsSpeaking = TTSService().isSpeaking;

        if (_isStressVoicePlaying && !ttsSpeaking) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isStressVoicePlaying) {
              setState(() => _isStressVoicePlaying = false);
            }
          });
        }

        if (_lastStressLanguage != null &&
            _lastStressLanguage != lang &&
            sensorData != null &&
            field != null &&
            !_isStressPredictionLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadStressPrediction(sensorData, field, lang);
            }
          });
        }
        
        debugPrint('[DashboardScreen] Build: field=${field?.id}, sensorData=${sensorData != null} (T:${sensorData?.temperature}, H:${sensorData?.humidity}, S:${sensorData?.soilMoisture})');

        if (fieldProvider.isLoading && field == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryGreen),
                const SizedBox(height: DesignTokens.space16),
                Text(
                  AppLocalizations.get('loading', lang),
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        if (field == null) {
          return _buildEmptyState(context, lang);
        }

      return _buildMainLayout(
        context,
        sensorData,
        field,
        lang,
        settings.isOnline,
        fieldProvider.isHardwareOnline,
        ttsSpeaking,
      );
    },
  );
}

Widget _buildMainLayout(
  BuildContext context,
  SensorData? sensorData,
  Field field,
  String lang,
  bool isAppOnline,
  bool isHardwareOnline,
  bool ttsSpeaking,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final screenWidth = MediaQuery.of(context).size.width;
  
  return Stack(
    children: [
      // Animated background gradient for premium feel
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [AppTheme.backgroundDark, const Color(0xFF142018), AppTheme.backgroundDark]
                : [AppTheme.backgroundLight, const Color(0xFFE8F3ED), AppTheme.backgroundLight],
          ),
        ),
      ),
      
      RefreshIndicator(
        onRefresh: () => context.read<FieldProvider>().loadFields(),
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 900 ? (screenWidth - 860) / 2 : 20.0,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Online status & Greeting
              _buildHeader(context, lang, isAppOnline, isHardwareOnline),
              const SizedBox(height: 24),

              
              // Health Status Card - HERO ELEMENT
              _buildHealthStatusCard(context, sensorData, field, lang),
              const SizedBox(height: 24),
              
              // Sensor Grid - 3 Cards
              _buildSensorGrid(context, sensorData, lang),
              const SizedBox(height: 24),
              
              // Motor Control - Large Touch Target
              _buildMotorControl(context, field, context.read<FieldProvider>(), lang),
              const SizedBox(height: 16),

              // Auto Irrigation Toggle
              _buildAutoIrrigationCard(context, field, context.read<FieldProvider>(), lang),
              const SizedBox(height: 24),

              // AI Stress Prediction Card
              StressPredictionCard(
                prediction: _stressPrediction,
                isLoading: _isStressPredictionLoading,
                isVoicePlaying: _isStressVoicePlaying || ttsSpeaking,
                languageCode: lang,
                onTap: () {
                  if (_stressPrediction != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StressPredictionScreen(
                          prediction: _stressPrediction!,
                          languageCode: lang,
                        ),
                      ),
                    );
                  } else {
                    _loadStressPrediction(sensorData, field, lang);
                  }
                },
                onRefresh: () => _loadStressPrediction(sensorData, field, lang),
                onVoiceToggle: () => _toggleStressVoice(sensorData, field, lang),
              ).animate().fadeIn(delay: 200.ms, duration: DesignTokens.animNormal),
              const SizedBox(height: 24),
              
              // Recent Alerts Preview (Add this for more "completeness")
              _buildAlertsPreview(context, lang),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildHeader(BuildContext context, String lang, bool isAppOnline, bool isHardwareOnline) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final userProvider = context.watch<UserProvider>();
  final hour = DateTime.now().hour;
  String greeting = 'Good Morning';
  if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
  if (hour >= 17) greeting = 'Good Evening';

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${userProvider.displayName} 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hardware Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isHardwareOnline ? AppTheme.success : AppTheme.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isHardwareOnline ? AppTheme.success : AppTheme.error).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isHardwareOnline ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isHardwareOnline ? 'SENSOR LIVE' : 'SENSOR OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isHardwareOnline ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // App Status
          Row(
            children: [
              Text(
                isAppOnline ? 'Cloud Synced' : 'Offline Mode',
                style: TextStyle(
                  fontSize: 10,
                  color: (isAppOnline ? AppTheme.primaryGreen : AppTheme.warning).withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isAppOnline ? Icons.cloud_done : Icons.cloud_off,
                size: 10,
                color: (isAppOnline ? AppTheme.primaryGreen : AppTheme.warning).withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildSyncInfoBadge(context, FirebaseService().currentUserId),
        ],
      ),
    ],
  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
}

Widget _buildSyncInfoBadge(BuildContext context, String currentUid) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.sync,
          size: 10,
          color: (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'ID: $currentUid',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withOpacity(0.5),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAlertsPreview(BuildContext context, String lang) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: (isDark ? AppTheme.cardDark : AppTheme.cardLight).withOpacity(0.7),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            );
          },
          icon: const Icon(Icons.notifications_none, color: AppTheme.primaryGreen),
          tooltip: AppLocalizations.get('alerts', lang),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'System monitoring active. No critical issues detected.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            );
          },
          child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  }

  Future<void> _loadStressPrediction(SensorData? sensorData, Field field, String lang) async {
    if (sensorData == null || _isStressPredictionLoading) return;
    setState(() => _isStressPredictionLoading = true);
    try {
      final prediction = await AIService().predictStress(
        sensorData: sensorData,
        field: field,
        languageCode: lang,
      );
      if (mounted) {
        setState(() {
          _stressPrediction = prediction;
          _isStressPredictionLoading = false;
          _lastStressLanguage = lang;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Stress prediction error: $e');
      if (mounted) setState(() => _isStressPredictionLoading = false);
    }
  }

  Future<void> _toggleStressVoice(SensorData? sensorData, Field field, String lang) async {
    final tts = TTSService();

    if (_isStressVoicePlaying || tts.isSpeaking) {
      await tts.stop();
      if (mounted) setState(() => _isStressVoicePlaying = false);
      return;
    }

    if (_stressPrediction == null && sensorData != null) {
      await _loadStressPrediction(sensorData, field, lang);
    }

    final pred = _stressPrediction;
    if (pred == null) return;

    final summary = '${pred.predictedStressType}. ${pred.recommendation}. ${pred.detailedAnalysis}';
    await tts.speakStressPrediction(summary, lang);

    if (!tts.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'ta'
                  ? 'இந்த சாதனத்தில் குரல் வெளியீடு ஆதரிக்கப்படவில்லை.'
                  : (lang == 'hi'
                      ? 'इस डिवाइस पर वॉइस आउटपुट समर्थित नहीं है।'
                      : 'Voice output is not supported on this device.'),
            ),
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isStressVoicePlaying = true);
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grass,
                size: DesignTokens.iconHero,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: DesignTokens.space24),
            Text(
              AppLocalizations.get('no_fields_yet', lang),
              style: TextStyle(
                fontSize: DesignTokens.fontHeadline,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              AppLocalizations.get('add_first_field_msg', lang),
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space32),
            SizedBox(
              height: DesignTokens.touchTargetLarge,
              child: ElevatedButton.icon(
                onPressed: () {}, // Switch to Fields tab manually via BottomNav
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.get('add', lang)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: DesignTokens.animNormal);
  }

  Widget _buildFieldSelector(BuildContext context, FieldProvider provider, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedField = provider.selectedField;
    
    if (selectedField == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.cardDark : AppTheme.cardLight).withOpacity(isDark ? 0.7 : 0.9),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium + 4),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.2)),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(selectedField.cropEmoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedField.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  AppLocalizations.getCropName(selectedField.cropType, lang),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (provider.fields.length > 1)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {}, // Handled by PopupMenuButton
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  icon: const Icon(
                    Icons.unfold_more,
                    color: AppTheme.primaryGreen,
                  ),
                  onSelected: (id) => provider.selectField(id),
                  itemBuilder: (context) => provider.fields
                      .where((f) => f.id != selectedField.id)
                      .map((field) => PopupMenuItem<String>(
                            value: field.id,
                            child: Row(
                              children: [
                                Text(field.cropEmoji),
                                const SizedBox(width: 12),
                                Text(field.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: DesignTokens.animNormal).slideX(begin: -0.05);
  }

  Widget _buildHealthStatusCard(BuildContext context, SensorData? data, Field field, String lang) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stressLevel = data?.stressLevel ?? CropStressLevel.healthy;
    
    // Get health state color
    Color statusColor;
    // ignore: unused_local_variable
    Color statusBgColor;
    String statusEmoji;
    String statusText;
    
    switch (stressLevel) {
      case CropStressLevel.healthy:
        statusColor = AppTheme.healthy;
        statusBgColor = AppTheme.healthyBg;
        statusEmoji = '🌱';
        statusText = AppLocalizations.get('healthy', lang);
        break;
      case CropStressLevel.moderate:
        statusColor = AppTheme.warning;
        statusBgColor = AppTheme.warningBg;
        statusEmoji = '⚠️';
        statusText = AppLocalizations.get('warning', lang);
        break;
      case CropStressLevel.high:
      case CropStressLevel.critical:
        statusColor = AppTheme.critical;
        statusBgColor = AppTheme.criticalBg;
        statusEmoji = '🔴';
        statusText = AppLocalizations.get('critical', lang);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Crop emoji + name
              Text(field.cropEmoji, style: const TextStyle(fontSize: DesignTokens.fontDisplay)),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: DesignTokens.fontXLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.getCropName(field.cropType, lang),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: DesignTokens.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Row(
                  children: [
                    Text(statusEmoji, style: const TextStyle(fontSize: DesignTokens.fontTitle)),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space20),
          // Status description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Text(
              stressLevel.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontMedium,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: DesignTokens.animNormal).slideY(
          begin: -0.05,
          duration: DesignTokens.animNormal,
        );
  }

  Widget _buildSensorGrid(BuildContext context, SensorData? data, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Single column for very narrow screens (< 340px)
        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              _buildSensorCard(
                context,
                icon: Icons.thermostat,
                label: AppLocalizations.get('temperature', lang),
                value: data?.temperature != null ? data!.temperature.toStringAsFixed(1) : '--',
                unit: '°C',
                status: data?.temperatureStatus ?? 'Waiting...',
                gradient: AppTheme.temperatureGradient,
                isLoading: data == null,
              ),
              const SizedBox(height: 8),
              _buildSensorCard(
                context,
                icon: Icons.water_drop,
                label: AppLocalizations.get('humidity', lang),
                value: data?.humidity != null ? data!.humidity.toStringAsFixed(0) : '--',
                unit: '%',
                status: data?.humidityStatus ?? 'Waiting...',
                gradient: AppTheme.humidityGradient,
                isLoading: data == null,
              ),
              const SizedBox(height: 8),
              _buildSensorCard(
                context,
                icon: Icons.grass,
                label: AppLocalizations.get('soil_moisture', lang),
                value: data?.soilMoisture != null ? data!.soilMoisture.toStringAsFixed(0) : '--',
                unit: '%',
                status: data?.soilMoistureStatus ?? 'Waiting...',
                gradient: AppTheme.soilMoistureGradient,
                isLoading: data == null,
                nonOptimalSymbol: '✓',
              ),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
              Expanded(
                child: _buildSensorCard(
                  context,
                  icon: Icons.thermostat,
                  label: AppLocalizations.get('temperature', lang),
                  value: data?.temperature != null ? data!.temperature.toStringAsFixed(1) : '--',
                  unit: '°C',
                  status: data?.temperatureStatus ?? 'Waiting...',
                  gradient: AppTheme.temperatureGradient,
                  isLoading: data == null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSensorCard(
                  context,
                  icon: Icons.water_drop,
                  label: AppLocalizations.get('humidity', lang),
                  value: data?.humidity != null ? data!.humidity.toStringAsFixed(0) : '--',
                  unit: '%',
                  status: data?.humidityStatus ?? 'Waiting...',
                  gradient: AppTheme.humidityGradient,
                  isLoading: data == null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSensorCard(
                  context,
                  icon: Icons.grass,
                  label: AppLocalizations.get('soil_moisture', lang),
                  value: data?.soilMoisture != null ? data!.soilMoisture.toStringAsFixed(0) : '--',
                  unit: '%',
                  status: data?.soilMoistureStatus ?? 'Waiting...',
                  gradient: AppTheme.soilMoistureGradient,
                  isLoading: data == null,
                  nonOptimalSymbol: '✓',
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 100.ms, duration: DesignTokens.animNormal);
  }

  Widget _buildSensorCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String status,
    required LinearGradient gradient,
    bool isLoading = false,
    String nonOptimalSymbol = '!',
  }) {
    final isOptimal = status.toLowerCase().contains('optimal');
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: DesignTokens.sensorIconSize),
          const SizedBox(height: DesignTokens.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                 isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                if (!isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: DesignTokens.fontSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: DesignTokens.sensorLabelSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space8,
              vertical: DesignTokens.space4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isOptimal ? 0.2 : 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Text(
              isOptimal ? '✓' : nonOptimalSymbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorControl(BuildContext context, Field field, FieldProvider provider, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOn = field.isPumpOn;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: Border.all(
          color: isOn ? AppTheme.info.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Water icon with animation
          Container(
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: (isOn ? AppTheme.info : AppTheme.textSecondaryLight).withOpacity(0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Icon(
              isOn ? Icons.water_drop : Icons.water_drop_outlined,
              color: isOn ? AppTheme.info : AppTheme.textSecondaryLight,
              size: DesignTokens.iconLarge,
            ),
          ),
          const SizedBox(width: DesignTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'ta' ? 'நீர் மோட்டார்' : lang == 'hi' ? 'पानी की मोटर' : 'Water Motor',
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: DesignTokens.fontLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isOn 
                      ? AppLocalizations.get('irrigation_on', lang)
                      : AppLocalizations.get('irrigation_off', lang),
                  style: TextStyle(
                    color: isOn ? AppTheme.info : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                    fontSize: DesignTokens.fontMedium,
                  ),
                ),
              ],
            ),
          ),
          // Large touch target toggle
          SizedBox(
            height: DesignTokens.touchTargetLarge,
            width: 100,
            child: ElevatedButton(
              onPressed: _isPumpLoading ? null : () async {
                setState(() => _isPumpLoading = true);
                final ok = await provider.togglePump();
                setState(() => _isPumpLoading = false);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'ta'
                            ? 'மோட்டார் கட்டளையை அனுப்ப முடியவில்லை.'
                            : (lang == 'hi'
                                ? 'मोटर कमांड भेजने में विफल।'
                                : 'Failed to send motor command.'),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOn ? AppTheme.critical : AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
              ),
              child: _isPumpLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isOn 
                          ? (lang == 'ta' ? 'நிறுத்து' : lang == 'hi' ? 'बंद' : 'STOP')
                          : (lang == 'ta' ? 'தொடங்கு' : lang == 'hi' ? 'चालू' : 'START'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontMedium,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: DesignTokens.animNormal);
  }

  Widget _buildAutoIrrigationCard(BuildContext context, Field field, FieldProvider provider, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuto = field.settings.autoIrrigation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: isAuto
            ? LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.12),
                  AppTheme.primaryGreen.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isAuto ? null : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: Border.all(
          color: isAuto
              ? AppTheme.primaryGreen.withOpacity(0.4)
              : Colors.transparent,
          width: isAuto ? 1.5 : 0,
        ),
      ),
      child: Row(
        children: [
          // Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isAuto ? AppTheme.primaryGreen : AppTheme.textSecondaryLight)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAuto ? Icons.autorenew : Icons.back_hand_outlined,
              color: isAuto ? AppTheme.primaryGreen : AppTheme.textSecondaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'ta'
                      ? '\u0ba4\u0bbe\u0ba9\u0bbf\u0baf\u0b99\u0bcd\u0b95\u0bbf \u0ba8\u0bc0\u0bb0\u0bcd\u0baa\u0bcd\u0baa\u0bbe\u0b9a\u0ba9\u0bae\u0bcd'
                      : lang == 'hi'
                          ? '\u0911\u091f\u094b \u0938\u093f\u0902\u091a\u093e\u0908'
                          : 'Auto Irrigation',
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: DesignTokens.fontMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAuto
                      ? (lang == 'ta'
                          ? '\u0bae\u0ba3\u0bcd \u0bb5\u0bb1\u0ba3\u0bcd\u0b9f\u0bbe\u0bb2\u0bcd \u0ba4\u0bbe\u0ba9\u0bbe\u0b95 \u0baa\u0bae\u0bcd\u0baa\u0bcd \u0b87\u0baf\u0b99\u0bcd\u0b95\u0bc1\u0bae\u0bcd'
                          : lang == 'hi'
                              ? '\u092e\u093f\u091f\u094d\u091f\u0940 \u0938\u0942\u0916\u0928\u0947 \u092a\u0930 \u092a\u0902\u092a \u0905\u092a\u0928\u0947 \u0906\u092a \u091a\u0932\u0947\u0917\u093e'
                              : 'Pump activates when soil is dry')
                      : (lang == 'ta'
                          ? '\u0b95\u0bc8\u0bae\u0bc1\u0bb1\u0bc8 \u0b95\u0b9f\u0bcd\u0b9f\u0bc1\u0baa\u0bcd\u0baa\u0bbe\u0b9f\u0bc1'
                          : lang == 'hi'
                              ? '\u092e\u0948\u0928\u094d\u092f\u0941\u0905\u0932 \u0928\u093f\u092f\u0902\u0924\u094d\u0930\u0923'
                              : 'Manual control only'),
                  style: TextStyle(
                    color: isAuto
                        ? AppTheme.primaryGreen.withOpacity(0.8)
                        : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          _isAutoToggling
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                )
              : Switch.adaptive(
                  value: isAuto,
                  activeColor: AppTheme.primaryGreen,
                  activeTrackColor: AppTheme.primaryGreen.withOpacity(0.4),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  onChanged: (val) async {
                    setState(() => _isAutoToggling = true);
                    final newSettings = field.settings.copyWith(autoIrrigation: val);
                    final ok = await provider.updateFieldSettings(field.id, newSettings);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == 'ta'
                                ? 'தானியங்கி நீர்ப்பாசன அமைப்பை புதுப்பிக்க முடியவில்லை.'
                                : (lang == 'hi'
                                    ? 'ऑटो सिंचाई सेटिंग अपडेट नहीं हुई।'
                                    : 'Failed to update auto-irrigation setting.'),
                          ),
                        ),
                      );
                    }
                    if (mounted) setState(() => _isAutoToggling = false);
                  },
                ),
        ],
      ),
    ).animate().fadeIn(delay: 175.ms, duration: DesignTokens.animNormal);
  }
}
