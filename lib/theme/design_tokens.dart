/// Design Tokens for AgroSmart
/// Centralized spacing, sizing, and animation constants

class DesignTokens {
  // Spacing - 8px grid system
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;

  // Touch targets - Accessibility minimum 48px
  static const double touchTargetMin = 48.0;
  static const double touchTargetLarge = 56.0;
  static const double touchTargetXLarge = 64.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 999.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconHero = 64.0;

  // Font sizes
  static const double fontXSmall = 10.0;
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontXLarge = 18.0;
  static const double fontTitle = 20.0;
  static const double fontHeadline = 24.0;
  static const double fontDisplay = 32.0;
  static const double fontHero = 48.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationVeryHigh = 16.0;

  // Card sizes
  static const double cardMinHeight = 80.0;
  static const double cardMediumHeight = 120.0;
  static const double cardLargeHeight = 160.0;

  // Sensor card specific
  static const double sensorValueSize = 36.0;
  static const double sensorLabelSize = 12.0;
  static const double sensorIconSize = 28.0;
}

/// Health state colors with semantic meaning
class HealthColors {
  // Healthy state - Green
  static const int healthyPrimary = 0xFF22C55E;
  static const int healthyLight = 0xFFDCFCE7;
  static const int healthyDark = 0xFF166534;
  
  // Warning state - Amber/Yellow
  static const int warningPrimary = 0xFFF59E0B;
  static const int warningLight = 0xFFFEF3C7;
  static const int warningDark = 0xFF92400E;
  
  // Critical state - Red
  static const int criticalPrimary = 0xFFEF4444;
  static const int criticalLight = 0xFFFEE2E2;
  static const int criticalDark = 0xFF991B1B;
  
  // Info state - Blue
  static const int infoPrimary = 0xFF3B82F6;
  static const int infoLight = 0xFFDBEAFE;
  static const int infoDark = 0xFF1E40AF;
}
