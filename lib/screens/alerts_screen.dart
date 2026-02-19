import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, _) {
        final alerts = _getFilteredAlerts(alertProvider);
        
        return Column(
          children: [
            // Header with filter
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Alert summary
                  _buildAlertSummary(context, alertProvider),
                  const SizedBox(height: 16),
                  
                  // Filter chips
                  _buildFilterChips(context, alertProvider),
                ],
              ),
            ),
            
            // Alerts list
            Expanded(
              child: alertProvider.isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : alerts.isEmpty 
                      ? _buildEmptyState(context)
                      : RefreshIndicator(
                          onRefresh: () => alertProvider.loadAlerts(),
                          color: AppTheme.primaryGreen,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: alerts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              return AlertCard(
                                alert: alert,
                                onTap: () => _showAlertDetails(context, alert),
                                onDismiss: () => alertProvider.deleteAlert(alert.id),
                              ).animate().fadeIn(
                                    delay: Duration(milliseconds: 50 * index),
                                    duration: 300.ms,
                                  );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertSummary(BuildContext context, AlertProvider provider) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: provider.hasCritical 
            ? const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: (provider.hasCritical ? AppTheme.error : AppTheme.primaryGreen)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  provider.hasCritical ? Icons.warning_amber : Icons.notifications,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.hasCritical ? settings.tr('critical_alerts') : settings.tr('alert_center'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.unreadCount} ${settings.tr('unread_alerts')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.3,
                      ),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.hasUnread) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => provider.markAllAsRead(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  settings.tr('mark_all_read'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: -0.1,
          duration: 400.ms,
        );
  }

  Widget _buildFilterChips(BuildContext context, AlertProvider provider) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', settings.tr('all'), Icons.apps, provider.alerts.length),
          const SizedBox(width: 8),
          _buildFilterChip('unread', settings.tr('unread'), Icons.circle, provider.unreadCount),
          const SizedBox(width: 8),
          _buildFilterChip('critical', settings.tr('critical'), Icons.error, provider.criticalAlerts.length),
          const SizedBox(width: 8),
          _buildFilterChip('moisture', settings.tr('soil_moisture'), Icons.water_drop, 
              provider.getAlertsByType(AlertType.lowMoisture).length + 
              provider.getAlertsByType(AlertType.highMoisture).length),
          const SizedBox(width: 8),
          _buildFilterChip('temperature', settings.tr('temperature'), Icons.thermostat,
              provider.getAlertsByType(AlertType.highTemperature).length + 
              provider.getAlertsByType(AlertType.lowTemperature).length),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildFilterChip(String value, String label, IconData icon, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _filter == value;
    
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen 
              : (isDark ? AppTheme.cardDark : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? null 
              : Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.2,
                ),
                softWrap: true,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            settings.tr('all_clear'),
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            settings.tr('no_alerts_moment'),
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.9, 0.9),
          duration: 400.ms,
        );
  }

  List<Alert> _getFilteredAlerts(AlertProvider provider) {
    switch (_filter) {
      case 'unread':
        return provider.unreadAlerts;
      case 'critical':
        return provider.criticalAlerts;
      case 'moisture':
        return [
          ...provider.getAlertsByType(AlertType.lowMoisture),
          ...provider.getAlertsByType(AlertType.highMoisture),
        ];
      case 'temperature':
        return [
          ...provider.getAlertsByType(AlertType.highTemperature),
          ...provider.getAlertsByType(AlertType.lowTemperature),
        ];
      default:
        return provider.alerts;
    }
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertProvider = context.read<AlertProvider>();
    final settings = context.read<SettingsProvider>();
    
    // Mark as read
    alertProvider.markAsRead(alert.id);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Alert icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert.severity).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        alert.fieldName,
                        style: TextStyle(
                          color: _getSeverityColor(alert.severity),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Message
            Text(
              alert.message,
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Value info
            if (alert.value != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          settings.tr('current'),
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.value!.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getSeverityColor(alert.severity),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Column(
                      children: [
                        Text(
                          settings.tr('threshold'),
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.threshold?.toStringAsFixed(1) ?? 'N/A',
                          style: TextStyle(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      alertProvider.markAsResolved(alert.id);
                    },
                    child: Text(settings.tr('mark_resolved')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to field
                    },
                    child: Text(settings.tr('view_field')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppTheme.info;
      case AlertSeverity.warning:
        return AppTheme.warning;
      case AlertSeverity.critical:
        return AppTheme.error;
    }
  }
}
