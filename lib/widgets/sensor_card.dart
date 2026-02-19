import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Trend direction for sensor values
enum TrendDirection { up, down, stable }

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData icon;
  final LinearGradient gradient;
  final bool isOptimal;
  final VoidCallback? onTap;
  final TrendDirection? trend;
  final double? previousValue;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.gradient,
    this.isOptimal = true,
    this.onTap,
    this.trend,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Row(
                        children: [
                          if (trend != null) _buildTrendIndicator(),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(isOptimal ? 0.2 : 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildTrendIndicator() {
    IconData trendIcon;
    Color trendColor;
    
    switch (trend) {
      case TrendDirection.up:
        trendIcon = Icons.trending_up;
        trendColor = Colors.white;
        break;
      case TrendDirection.down:
        trendIcon = Icons.trending_down;
        trendColor = Colors.white;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.white.withOpacity(0.7);
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        trendIcon,
        color: trendColor,
        size: 16,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3));
  }
}

class SmallSensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SmallSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isDark ? null : AppTheme.cardShadow,
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark 
                          ? AppTheme.textSecondaryDark 
                          : AppTheme.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: isDark 
                              ? AppTheme.textPrimaryDark 
                              : AppTheme.textPrimaryLight,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 2),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: isDark 
                                ? AppTheme.textSecondaryDark 
                                : AppTheme.textSecondaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}

/// Large info card for displaying weather or summary data
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
