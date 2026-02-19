import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/localization.dart';

/// Language selector widget with native script names
class LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final bool compact;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector(context);
    }
    return _buildFullSelector(context);
  }

  Widget _buildCompactSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopupMenuButton<String>(
      initialValue: currentLanguage,
      onSelected: onLanguageChanged,
      offset: const Offset(0, DesignTokens.touchTargetMin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      itemBuilder: (context) => SupportedLanguages.all.map((lang) {
        return PopupMenuItem<String>(
          value: lang['code'],
          height: DesignTokens.touchTargetMin,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: currentLanguage == lang['code']
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    lang['code']!.toUpperCase(),
                    style: TextStyle(
                      color: currentLanguage == lang['code']
                          ? Colors.white
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: DesignTokens.fontSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang['nativeName']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSmall,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (currentLanguage == lang['code'])
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate,
              size: DesignTokens.iconSmall,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: DesignTokens.space4),
            Text(
              _getNativeName(currentLanguage),
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: DesignTokens.fontSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SupportedLanguages.all.map((lang) {
        final isSelected = currentLanguage == lang['code'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
          child: GestureDetector(
            onTap: () => onLanguageChanged(lang['code']!),
            child: AnimatedContainer(
              duration: DesignTokens.animFast,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                lang['nativeName']!,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: DesignTokens.fontMedium,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getNativeName(String code) {
    for (var lang in SupportedLanguages.all) {
      if (lang['code'] == code) {
        return lang['nativeName']!;
      }
    }
    return 'English';
  }
}

/// Language toggle row for settings
class LanguageToggleRow extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  const LanguageToggleRow({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Language / மொழி / भाषा',
          style: TextStyle(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            fontSize: DesignTokens.fontSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        LanguageSelector(
          currentLanguage: currentLanguage,
          onLanguageChanged: onLanguageChanged,
          compact: false,
        ),
      ],
    );
  }
}
