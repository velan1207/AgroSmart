import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/localization.dart';

/// Widget to display poor/no connection status
class ConnectionStatusWidget extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;
  final String languageCode;
  final bool showFullPage;

  const ConnectionStatusWidget({
    super.key,
    required this.isOnline,
    this.onRetry,
    this.languageCode = 'en',
    this.showFullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    if (showFullPage) {
      return _buildFullPageOffline(context);
    }

    return _buildBanner(context);
  }

  Widget _buildBanner(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B6B),
            const Color(0xFFEE5A5A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.get('poor_connection', languageCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.get('poor_connection_msg', languageCode),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: AppLocalizations.get('try_again', languageCode),
            ),
        ],
      ),
    );
  }

  Widget _buildFullPageOffline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppTheme.backgroundDark, const Color(0xFF1A1A2E)]
              : [AppTheme.backgroundLight, const Color(0xFFF5F5F5)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated WiFi icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              AppLocalizations.get('no_connection', languageCode),
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.get('no_connection_msg', languageCode),
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Retry button
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.get('try_again', languageCode)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTip(
                    context,
                    icon: Icons.signal_cellular_alt,
                    text: AppLocalizations.get('connection_tip_1', languageCode),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTip(
                    context,
                    icon: Icons.wifi,
                    text: AppLocalizations.get('connection_tip_2', languageCode),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTip(
                    context,
                    icon: Icons.airplanemode_active,
                    text: AppLocalizations.get('connection_tip_3', languageCode),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, {
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
