import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_logo.dart';
import '../widgets/language_selector.dart';
import '../models/models.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'ai_insights_screen.dart';
import 'dashboard_screen.dart';
import 'graph_screen.dart';
import 'loading_screen.dart';
import '../utils/localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isBootstrapping = false;
  String? _bootstrappedUserId;
  
  final List<Widget> _screens = const [
    DashboardScreen(),
    GraphScreen(),
    AIInsightsScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp({bool force = false}) async {
    if (_isBootstrapping && !force) return;

    if (mounted) {
      setState(() {
        _isBootstrapping = true;
      });
    }

    final settingsProvider = context.read<SettingsProvider>();
    final userProvider = context.read<UserProvider>();
    final fieldProvider = context.read<FieldProvider>();
    final alertProvider = context.read<AlertProvider>();

    try {
      await settingsProvider.initialize();

      if (!settingsProvider.hasUserId) {
        _bootstrappedUserId = null;
        return;
      }

      final activeUserId = settingsProvider.userId!;
      await userProvider.loadProfile(activeUserId);

      await Future.wait([
        fieldProvider.loadFields(),
        alertProvider.initialize(settingsProvider: settingsProvider),
      ]);

      _bootstrappedUserId = activeUserId;
    } catch (e) {
      debugPrint('[HomeScreen] Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (settings.isInitialized) {
      final needsRebootstrap = settings.hasUserId && settings.userId != _bootstrappedUserId;
      if (needsRebootstrap && !_isBootstrapping) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _initializeApp(force: true);
          }
        });
      }
    }
    
    // Show full-screen loading while app/auth bootstrap is in progress.
    if (!settings.isInitialized || _isBootstrapping) {
      return const LoadingScreen();
    }
    
    // If initialized and still no user id, show setup
    if (!settings.hasUserId) {
      return const SetupScreen();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final useRail = screenWidth >= 720;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: _buildAppBar(context),
      body: useRail
          ? Row(
              children: [
                _buildNavigationRail(context),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: DesignTokens.animNormal,
                    child: _screens[_currentIndex],
                  ),
                ),
              ],
            )
          : AnimatedSwitcher(
              duration: DesignTokens.animNormal,
              child: _screens[_currentIndex],
            ),
      bottomNavigationBar: useRail ? null : _buildBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      elevation: 0,
      titleSpacing: DesignTokens.space16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App logo
          AppLogo(
            size: 40,
            borderRadius: DesignTokens.radiusSmall,
          ),
          const SizedBox(width: DesignTokens.space12),
          // App name and title - Wrap in Flexible/FittedBox for responsiveness
          Flexible(
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AgroSmart',
                        style: TextStyle(
                          fontSize: DesignTokens.fontLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        settings.tr(_getTitleKey(_currentIndex)),
                        style: TextStyle(
                          fontSize: DesignTokens.fontXSmall,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        // Language selector
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return LanguageSelector(
              currentLanguage: settings.languageCode,
              onLanguageChanged: settings.setLanguageCode,
              compact: true,
            );
          },
        ),
        const SizedBox(width: DesignTokens.space8),
        
        // Connection status
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space8,
                vertical: DesignTokens.space4,
              ),
              decoration: BoxDecoration(
                color: (settings.isOnline ? AppTheme.success : AppTheme.error)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: settings.isOnline ? AppTheme.success : AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Text(
                    settings.tr(settings.isOnline ? 'online' : 'offline'),
                    style: TextStyle(
                      color: settings.isOnline ? AppTheme.success : AppTheme.error,
                      fontSize: DesignTokens.fontXSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: DesignTokens.space8),
        
        // Alert badge
        Consumer<AlertProvider>(
          builder: (context, alertProvider, _) {
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                  onPressed: () => setState(() => _currentIndex = 3),
                ),
                if (alertProvider.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: alertProvider.hasCritical 
                            ? AppTheme.critical 
                            : AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        alertProvider.unreadCount > 9 
                            ? '9+' 
                            : alertProvider.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: DesignTokens.fontXSmall,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 500.ms,
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: DesignTokens.space8),
      ],
    );
  }

  String _getTitleKey(int index) {
    switch (index) {
      case 0: return 'dashboard';
      case 1: return 'weekly_trend';
      case 2: return 'ai_insights';
      case 3: return 'alerts';
      case 4: return 'settings';
      default: return 'dashboard';
    }
  }

  Widget _buildNavigationRail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final lang = settings.languageCode;
    final screenWidth = MediaQuery.of(context).size.width;

    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
      selectedIconTheme: const IconThemeData(color: AppTheme.primaryGreen),
      unselectedIconTheme: IconThemeData(
        color: isDark ? Colors.white38 : Colors.grey.shade400,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: AppTheme.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.grey.shade400,
        fontSize: 12,
      ),
      labelType: screenWidth >= 900
          ? NavigationRailLabelType.selected
          : NavigationRailLabelType.none,
      extended: screenWidth >= 1100,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: Text(AppLocalizations.get('dashboard', lang)),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: Text(AppLocalizations.get('graphs', lang)),
        ),
        NavigationRailDestination(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          label: Text(AppLocalizations.get('ai_insights', lang)),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications),
          label: Text(AppLocalizations.get('alerts', lang)),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(AppLocalizations.get('settings', lang)),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final lang = settings.languageCode;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: isDark ? Colors.white54 : Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: AppLocalizations.get('dashboard', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: AppLocalizations.get('graphs', lang),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 24),
            ),
            label: AppLocalizations.get('ai_insights', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_outlined),
            activeIcon: const Icon(Icons.notifications),
            label: AppLocalizations.get('alerts', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: AppLocalizations.get('settings', lang),
          ),
        ],
      ),
    );
  }
}
