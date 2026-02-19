import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class StressIndicator extends StatelessWidget {
  final CropStressLevel stressLevel;
  final bool showLabel;
  final bool showDescription;
  final double size;

  const StressIndicator({
    super.key,
    required this.stressLevel,
    this.showLabel = true,
    this.showDescription = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircularIndicator(isDark),
        if (showLabel) ...[
          const SizedBox(height: 12),
          Text(
            stressLevel.label,
            style: TextStyle(
              color: _getColor(),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (showDescription) ...[
          const SizedBox(height: 4),
          Text(
            stressLevel.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark 
                  ? AppTheme.textSecondaryDark 
                  : AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularIndicator(bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getColor().withOpacity(0.2),
            _getColor().withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: _getProgress(),
              strokeWidth: 6,
              backgroundColor: _getColor().withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
            ),
          ),
          // Icon in center
          Icon(
            _getIcon(),
            color: _getColor(),
            size: size * 0.4,
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
      duration: 2000.ms,
      color: _getColor().withOpacity(0.3),
    );
  }

  Color _getColor() {
    switch (stressLevel) {
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

  IconData _getIcon() {
    switch (stressLevel) {
      case CropStressLevel.healthy:
        return Icons.eco;
      case CropStressLevel.moderate:
        return Icons.trending_flat;
      case CropStressLevel.high:
        return Icons.warning_amber;
      case CropStressLevel.critical:
        return Icons.error_outline;
    }
  }

  double _getProgress() {
    switch (stressLevel) {
      case CropStressLevel.healthy:
        return 1.0;
      case CropStressLevel.moderate:
        return 0.75;
      case CropStressLevel.high:
        return 0.5;
      case CropStressLevel.critical:
        return 0.25;
    }
  }
}

class CompactStressIndicator extends StatelessWidget {
  final CropStressLevel stressLevel;

  const CompactStressIndicator({
    super.key,
    required this.stressLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stressLevel.label,
            style: TextStyle(
              color: _getColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (stressLevel) {
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
}
