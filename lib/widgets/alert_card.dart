import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppTheme.error,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: !alert.isRead 
                ? Border.all(
                    color: _getSeverityColor().withOpacity(0.5),
                    width: 1,
                  )
                : null,
            boxShadow: isDark ? null : AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getSeverityColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alert.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Alert content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              color: isDark 
                                  ? AppTheme.textPrimaryDark 
                                  : AppTheme.textPrimaryLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getSeverityColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.fieldName,
                      style: TextStyle(
                        color: _getSeverityColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.message,
                      style: TextStyle(
                        color: isDark 
                            ? AppTheme.textSecondaryDark 
                            : AppTheme.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSeverityBadge(),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark 
                              ? AppTheme.textSecondaryDark 
                              : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(alert.timestamp),
                          style: TextStyle(
                            color: isDark 
                                ? AppTheme.textSecondaryDark 
                                : AppTheme.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getSeverityColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _getSeverityLabel(),
        style: TextStyle(
          color: _getSeverityColor(),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSeverityColor() {
    switch (alert.severity) {
      case AlertSeverity.info:
        return AppTheme.info;
      case AlertSeverity.warning:
        return AppTheme.warning;
      case AlertSeverity.critical:
        return AppTheme.error;
    }
  }

  String _getSeverityLabel() {
    switch (alert.severity) {
      case AlertSeverity.info:
        return 'INFO';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.critical:
        return 'CRITICAL';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
