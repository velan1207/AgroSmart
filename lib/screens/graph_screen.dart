import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '24h';
  List<SensorData> _historicalData = [];
  List<Map<String, dynamic>> _dailyAverages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final provider = context.read<FieldProvider>();
    
    // Load historical data based on selected period
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case '24h':
        startDate = now.subtract(const Duration(hours: 24));
        break;
      case '7d':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = now.subtract(const Duration(days: 30));
        break;
      default:
        startDate = now.subtract(const Duration(hours: 24));
    }
    
    final data = await provider.getHistoricalData(
      startDate: startDate,
      endDate: now,
    );
    
    // Append current live data if it's not already in history
    if (provider.currentSensorData != null) {
      final liveData = provider.currentSensorData!;
      if (data.isEmpty || liveData.timestamp.isAfter(data.last.timestamp)) {
        data.add(liveData);
      }
    }
    
    // Ensure sorted by timestamp
    data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Filter to keep only last 24h if that's the period
    if (_selectedPeriod == '24h') {
       final cutoff = now.subtract(const Duration(hours: 24));
       data.removeWhere((d) => d.timestamp.isBefore(cutoff));
    }
    
    // If it's a 7d or 24h period, we can use the provider's real-time averages
    // otherwise we fetch for the 30d period
    List<Map<String, dynamic>> averages;
    if (_selectedPeriod == '24h' || _selectedPeriod == '7d') {
      averages = provider.dailyAverages;
    } else {
      averages = await provider.getDailyAverages(days: 30);
    }
    
    if (mounted) {
      setState(() {
        _historicalData = data;
        _dailyAverages = averages;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<FieldProvider>();
    
    // Auto-update daily averages if in real-time mode
    if (!_isLoading && (_selectedPeriod == '24h' || _selectedPeriod == '7d')) {
      _dailyAverages = provider.dailyAverages;
    }
    
    return Column(
      children: [
        // Period selector
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              _buildPeriodButton('24h', '24 Hours'),
              _buildPeriodButton('7d', '7 Days'),
              _buildPeriodButton('30d', '30 Days'),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
        
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: isDark ? null : AppTheme.cardShadow,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: isDark 
                ? AppTheme.textSecondaryDark 
                : AppTheme.textSecondaryLight,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              color: AppTheme.primaryGreen.withOpacity(0.1),
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.thermostat, size: 20),
                text: 'Temp',
              ),
              Tab(
                icon: Icon(Icons.water_drop, size: 20),
                text: 'Humidity',
              ),
              Tab(
                icon: Icon(Icons.grass, size: 20),
                text: 'Moisture',
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        
        const SizedBox(height: 20),
        
        // Charts
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChartView('temperature', 'Temperature', '°C', AppTheme.temperatureColor),
                    _buildChartView('humidity', 'Humidity', '%', AppTheme.humidityColor),
                    _buildChartView('soilMoisture', 'Soil Moisture', '%', AppTheme.soilMoistureColor),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Center(
            child: Text(
              settings.tr(label),
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartView(String dataType, String title, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current value card
          _buildCurrentValueCard(dataType, title, unit, color),
          const SizedBox(height: 20),
          
          // Line chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isDark ? null : AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.tr('historical_data'),
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: SensorLineChart(
                    data: _historicalData,
                    dataType: dataType,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 20),
          
          // Bar chart for daily averages
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isDark ? null : AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.tr('daily_averages'),
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: DailyBarChart(
                    data: _dailyAverages,
                    dataType: dataType,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 20),
          
          // Statistics
          _buildStatistics(dataType, unit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCurrentValueCard(String dataType, String title, String unit, Color color) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<FieldProvider>();
    final settings = context.watch<SettingsProvider>();
    final data = provider.currentSensorData;
    
    double? value;
    String status = 'N/A';
    
    if (data != null) {
      switch (dataType) {
        case 'temperature':
          value = data.temperature;
          status = data.temperatureStatus;
          break;
        case 'humidity':
          value = data.humidity;
          status = data.humidityStatus;
          break;
        case 'soilMoisture':
          value = data.soilMoisture;
          status = data.soilMoistureStatus;
          break;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              _getIcon(dataType),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${settings.tr('current')} ${settings.tr(dataType.toLowerCase())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value?.toStringAsFixed(1) ?? '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              settings.tr(status.toLowerCase()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: -0.1,
          duration: 400.ms,
        );
  }

  Widget _buildStatistics(String dataType, String unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    if (_historicalData.isEmpty) return const SizedBox.shrink();
    
    // Calculate statistics
    final List<double> values = _historicalData.map((d) {
      switch (dataType) {
        case 'temperature':
          return d.temperature;
        case 'humidity':
          return d.humidity;
        case 'soilMoisture':
          return d.soilMoisture;
        default:
          return 0.0;
      }
    }).toList();

    // Include the latest live reading for real-time accuracy
    final provider = context.watch<FieldProvider>();
    final liveData = provider.currentSensorData;
    if (liveData != null) {
      switch (dataType) {
        case 'temperature':
          values.add(liveData.temperature);
          break;
        case 'humidity':
          values.add(liveData.humidity);
          break;
        case 'soilMoisture':
          values.add(liveData.soilMoisture);
          break;
      }
    }

    if (values.isEmpty) return const SizedBox.shrink();
    
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.tr('statistics'),
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('min', min.toStringAsFixed(1), unit, Icons.arrow_downward, AppTheme.info),
              _buildStatItem('average', avg.toStringAsFixed(1), unit, Icons.trending_flat, AppTheme.warning),
              _buildStatItem('max', max.toStringAsFixed(1), unit, Icons.arrow_upward, AppTheme.error),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$value$unit',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            settings.tr(label),
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String dataType) {
    switch (dataType) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'soilMoisture':
        return Icons.grass;
      default:
        return Icons.analytics;
    }
  }
}
