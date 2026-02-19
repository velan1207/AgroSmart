import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class PumpControlButton extends StatelessWidget {
  final bool isPumpOn;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PumpControlButton({
    super.key,
    required this.isPumpOn,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPumpOn 
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                      : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: isPumpOn 
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : isDark ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isPumpOn 
                    ? Colors.white.withOpacity(0.2)
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: isLoading 
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      isPumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                      size: 28,
                      color: isPumpOn 
                          ? Colors.white 
                          : (isDark ? Colors.white54 : AppTheme.primaryGreen),
                    ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Irrigation Pump',
                    style: TextStyle(
                      color: isPumpOn 
                          ? Colors.white 
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPumpOn ? 'Pump is running...' : 'Tap to start irrigation',
                    style: TextStyle(
                      color: isPumpOn 
                          ? Colors.white.withOpacity(0.8)
                          : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Status indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPumpOn 
                    ? Colors.white.withOpacity(0.2)
                    : (isDark ? Colors.white.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPumpOn ? Colors.greenAccent : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ).animate(
                    target: isPumpOn ? 1 : 0,
                    onPlay: (controller) {
                      if (isPumpOn) controller.repeat(reverse: true);
                    },
                  ).scaleXY(
                    begin: 1,
                    end: 1.3,
                    duration: 500.ms,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPumpOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isPumpOn 
                          ? Colors.white 
                          : (isDark ? Colors.white54 : AppTheme.textSecondaryLight),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
