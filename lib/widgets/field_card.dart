import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class FieldCard extends StatelessWidget {
  final Field field;
  final bool isSelected;
  final VoidCallback? onTap;

  const FieldCard({
    super.key,
    required this.field,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stressLevel = field.latestData?.stressLevel ?? CropStressLevel.healthy;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.cardDark : AppTheme.cardLight).withOpacity(isDark ? 0.7 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : Colors.white.withOpacity(isDark ? 0.05 : 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]
              : isDark ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Crop emoji container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStressColor(stressLevel).withOpacity(0.2),
                    _getStressColor(stressLevel).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  field.cropEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Field info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name,
                    style: TextStyle(
                      color: isDark 
                          ? AppTheme.textPrimaryDark 
                          : AppTheme.textPrimaryLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Planted: ${_formatDate(field.plantingDate ?? field.createdAt)}',
                        style: TextStyle(
                          color: isDark 
                              ? AppTheme.textSecondaryDark 
                              : AppTheme.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          field.cropType,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (field.location != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.red.withOpacity(0.6),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            field.location!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark 
                                  ? AppTheme.textSecondaryDark 
                                  : AppTheme.textSecondaryLight,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(stressLevel),
                const SizedBox(height: 10),
                if (field.isPumpOn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.water_drop, size: 12, color: AppTheme.info),
                        const SizedBox(width: 4),
                        const Text(
                          'Active',
                          style: TextStyle(color: AppTheme.info, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CropStressLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStressColor(level).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getStressColor(level),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: TextStyle(
              color: _getStressColor(level),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStressColor(CropStressLevel level) {
    switch (level) {
      case CropStressLevel.healthy:
        return AppTheme.success;
      case CropStressLevel.moderate:
        return AppTheme.warning;
      case CropStressLevel.high:
        return AppTheme.accentOrange;
      case CropStressLevel.critical:
        return AppTheme.error;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
