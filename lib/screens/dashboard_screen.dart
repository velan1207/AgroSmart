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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isPumpLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<FieldProvider, SettingsProvider>(
      builder: (context, fieldProvider, settings, _) {
        final field = fieldProvider.selectedField;
        final sensorData = fieldProvider.currentSensorData;
        final lang = settings.languageCode;
        
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

      return _buildMainLayout(context, sensorData, field, lang, settings.isOnline, fieldProvider.isHardwareOnline);
    },
  );
}

Widget _buildMainLayout(BuildContext context, SensorData? sensorData, Field field, String lang, bool isAppOnline, bool isHardwareOnline) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${userProvider.displayName} 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
        const Icon(Icons.notifications_none, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'System monitoring active. No critical issues detected.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () {}, // Navigate to alerts
          child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
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
        // Switch to column for extremely narrow screens or keep row with fitted boxes
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
              isOptimal ? '✓' : '!',
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
                await provider.togglePump();
                setState(() => _isPumpLoading = false);
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
}
