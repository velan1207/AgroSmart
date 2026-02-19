import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// AgroSmart Theme - Accessibility-First Agricultural Design System
class AppTheme {
  // Primary Colors - Agricultural Green
  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color primaryGreenLight = Color(0xFF40916C);
  static const Color primaryGreenDark = Color(0xFF1B4332);
  
  // Accent Colors
  static const Color accentBlue = Color(0xFF0077B6);
  static const Color accentOrange = Color(0xFFE85D04);
  
  // Health States - High Contrast Accessibility
  static const Color healthy = Color(HealthColors.healthyPrimary);
  static const Color healthyBg = Color(HealthColors.healthyLight);
  static const Color warning = Color(HealthColors.warningPrimary);
  static const Color warningBg = Color(HealthColors.warningLight);
  static const Color critical = Color(HealthColors.criticalPrimary);
  static const Color criticalBg = Color(HealthColors.criticalLight);
  static const Color info = Color(HealthColors.infoPrimary);
  static const Color infoBg = Color(HealthColors.infoLight);
  
  // Semantic aliases
  static const Color success = healthy;
  static const Color error = critical;
  
  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8FAF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1C1A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  
  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F1410);
  static const Color surfaceDark = Color(0xFF1A1F1C);
  static const Color cardDark = Color(0xFF242B26);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  
  // Radius constants (for backwards compatibility)
  static const double radiusSmall = DesignTokens.radiusSmall;
  static const double radiusMedium = DesignTokens.radiusMedium;
  static const double radiusLarge = DesignTokens.radiusLarge;
  static const double radiusXLarge = DesignTokens.radiusXLarge;
  
  // Sensor-specific colors
  static const Color temperatureColor = Color(0xFFEF4444);
  static const Color humidityColor = Color(0xFF3B82F6);
  static const Color soilMoistureColor = Color(0xFF8B5CF6);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient temperatureGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient humidityGradient = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient soilMoistureGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreenLight,
        surface: surfaceLight,
        error: critical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: DesignTokens.fontTitle,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimaryLight),
      ),
      textTheme: _buildTextTheme(textPrimaryLight, textSecondaryLight),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(false),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        color: cardLight,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreenLight,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: primaryGreenLight,
        secondary: primaryGreen,
        surface: surfaceDark,
        error: critical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: DesignTokens.fontTitle,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimaryDark),
      ),
      textTheme: _buildTextTheme(textPrimaryDark, textSecondaryDark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(true),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        color: cardDark,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: DesignTokens.fontHero,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: DesignTokens.fontDisplay,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: DesignTokens.fontHeadline,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: DesignTokens.fontTitle,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: DesignTokens.fontXLarge,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: DesignTokens.fontLarge,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: DesignTokens.fontLarge,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: DesignTokens.fontMedium,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: DesignTokens.fontMedium,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, DesignTokens.touchTargetMin),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space24,
          vertical: DesignTokens.space16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: DesignTokens.fontLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        minimumSize: const Size(double.infinity, DesignTokens.touchTargetMin),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space24,
          vertical: DesignTokens.space16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        side: const BorderSide(color: primaryGreen, width: 1.5),
        textStyle: const TextStyle(
          fontSize: DesignTokens.fontLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? cardDark : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: const BorderSide(color: critical),
      ),
      labelStyle: TextStyle(
        color: isDark ? textSecondaryDark : textSecondaryLight,
      ),
    );
  }
}

/// Extension for health state styling
extension HealthStateExtension on String {
  Color get healthColor {
    switch (toLowerCase()) {
      case 'healthy':
      case 'optimal':
        return AppTheme.healthy;
      case 'warning':
      case 'suboptimal':
        return AppTheme.warning;
      case 'critical':
      case 'danger':
        return AppTheme.critical;
      default:
        return AppTheme.info;
    }
  }
  
  Color get healthBgColor {
    switch (toLowerCase()) {
      case 'healthy':
      case 'optimal':
        return AppTheme.healthyBg;
      case 'warning':
      case 'suboptimal':
        return AppTheme.warningBg;
      case 'critical':
      case 'danger':
        return AppTheme.criticalBg;
      default:
        return AppTheme.infoBg;
    }
  }
}
