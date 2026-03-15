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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final provider = context.read<FieldProvider>();

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

    // Append current live data
    if (provider.currentSensorData != null) {
      final liveData = provider.currentSensorData!;
      if (data.isEmpty || liveData.timestamp.isAfter(data.last.timestamp)) {
        data.add(liveData);
      }
    }

    data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (_selectedPeriod == '24h') {
      final cutoff = now.subtract(const Duration(hours: 24));
      data.removeWhere((d) => d.timestamp.isBefore(cutoff));
    }

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

    // Auto-update daily averages in real-time modes
    if (!_isLoading && (_selectedPeriod == '24h' || _selectedPeriod == '7d')) {
      _dailyAverages = provider.dailyAverages;
    }

    return Column(
      children: [
        // ── Period Selector ──
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              _buildPeriodButton('24h', '24 Hours', Icons.access_time),
              _buildPeriodButton('7d', '7 Days', Icons.date_range),
              _buildPeriodButton('30d', '30 Days', Icons.calendar_month),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        // ── Tab Bar (Temp / Humidity / Moisture) ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: isDark ? null : AppTheme.cardShadow,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: _getActiveTabColor(),
            unselectedLabelColor: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              color: _getActiveTabColor().withOpacity(0.1),
            ),
            tabs: const [
              Tab(icon: Icon(Icons.thermostat, size: 20), text: 'Temp'),
              Tab(icon: Icon(Icons.water_drop, size: 20), text: 'Humidity'),
              Tab(icon: Icon(Icons.grass, size: 20), text: 'Moisture'),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

        const SizedBox(height: 16),

        // ── Chart Content ──
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _getActiveTabColor()),
                      const SizedBox(height: 12),
                      Text(
                        'Loading $_selectedPeriod data...',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
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

  Color _getActiveTabColor() {
    switch (_tabController.index) {
      case 0: return AppTheme.temperatureColor;
      case 1: return AppTheme.humidityColor;
      case 2: return AppTheme.soilMoistureColor;
      default: return AppTheme.primaryGreen;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  PERIOD BUTTON
  // ──────────────────────────────────────────────────────────
  Widget _buildPeriodButton(String value, String label, IconData icon) {
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: isSelected
                ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
              ),
              const SizedBox(width: 4),
              Text(
                settings.tr(label),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  MAIN CHART VIEW  — changes based on period
  // ──────────────────────────────────────────────────────────
  Widget _buildChartView(String dataType, String title, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: color,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Current Value Card + Gauge ──
            _buildCurrentValueCard(dataType, title, unit, color),
            const SizedBox(height: 16),

            // ── GAUGE (always shown) ──
            _buildGaugeSection(dataType, unit, color),
            const SizedBox(height: 16),

            // ── Period-specific charts ──
            ..._buildPeriodCharts(dataType, title, unit, color, isDark, settings),

            // ── Statistics (always shown) ──
            _buildStatistics(dataType, unit),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  PERIOD-SPECIFIC CHART SECTIONS
  // ──────────────────────────────────────────────────────────
  List<Widget> _buildPeriodCharts(
    String dataType, String title, String unit, Color color, bool isDark, SettingsProvider settings,
  ) {
    switch (_selectedPeriod) {
      // ============= 24 HOURS =============
      case '24h':
        return [
          // Scrollable line chart
          _chartCard(
            title: settings.tr('real_time_trend'),
            subtitle: '${_historicalData.length} ${settings.tr('points')}',
            color: color,
            isDark: isDark,
            height: 220,
            delay: 200,
            child: SensorLineChart(
              data: _historicalData,
              dataType: dataType,
              period: '24h',
            ),
          ),
          const SizedBox(height: 16),

          // Hourly distribution
          _chartCard(
            title: settings.tr('hourly_distribution'),
            subtitle: '24h',
            color: color,
            isDark: isDark,
            height: 180,
            delay: 300,
            child: HourlyDistributionChart(
              data: _historicalData,
              dataType: dataType,
            ),
          ),
          const SizedBox(height: 16),
        ];

      // ============= 7 DAYS =============
      case '7d':
        return [
          // Line chart
          _chartCard(
            title: settings.tr('weekly_trend'),
            subtitle: '${_historicalData.length} ${settings.tr('points')}',
            color: color,
            isDark: isDark,
            height: 220,
            delay: 200,
            child: SensorLineChart(
              data: _historicalData,
              dataType: dataType,
              period: '7d',
            ),
          ),
          const SizedBox(height: 16),

          // Daily bar chart
          _chartCard(
            title: settings.tr('daily_averages'),
            subtitle: '${_dailyAverages.length} ${settings.tr('days')}',
            color: color,
            isDark: isDark,
            height: 180,
            delay: 300,
            child: DailyBarChart(
              data: _dailyAverages,
              dataType: dataType,
            ),
          ),
          const SizedBox(height: 16),

          // Min/Max range chart
          _chartCard(
            title: settings.tr('daily_range'),
            subtitle: 'Min / Avg / Max',
            color: color,
            isDark: isDark,
            height: 200,
            delay: 400,
            child: MinMaxRangeChart(
              data: _historicalData,
              dataType: dataType,
              period: '7d',
            ),
            legendItems: [
              _LegendItem('Max', color),
              _LegendItem('Avg', color.withOpacity(0.6)),
              _LegendItem('Min', color.withOpacity(0.35)),
            ],
          ),
          const SizedBox(height: 16),
        ];

      // ============= 30 DAYS =============
      case '30d':
        return [
          // Trend line with moving average
          _chartCard(
            title: settings.tr('monthly_trend'),
            subtitle: '${_dailyAverages.length} ${settings.tr('days')}',
            color: color,
            isDark: isDark,
            height: 220,
            delay: 200,
            child: TrendComparisonChart(
              data: _dailyAverages,
              dataType: dataType,
            ),
            legendItems: [
              _LegendItem('Actual', color),
              _LegendItem('Trend', color.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 16),

          // Daily bar chart
          _chartCard(
            title: settings.tr('daily_averages'),
            subtitle: '${_dailyAverages.length} ${settings.tr('days')}',
            color: color,
            isDark: isDark,
            height: 180,
            delay: 300,
            child: DailyBarChart(
              data: _dailyAverages,
              dataType: dataType,
            ),
          ),
          const SizedBox(height: 16),

          // Min/Max range chart
          _chartCard(
            title: settings.tr('monthly_range'),
            subtitle: 'Min / Avg / Max',
            color: color,
            isDark: isDark,
            height: 200,
            delay: 400,
            child: MinMaxRangeChart(
              data: _historicalData,
              dataType: dataType,
              period: '30d',
            ),
            legendItems: [
              _LegendItem('Max', color),
              _LegendItem('Avg', color.withOpacity(0.6)),
              _LegendItem('Min', color.withOpacity(0.35)),
            ],
          ),
          const SizedBox(height: 16),
        ];

      default:
        return [];
    }
  }

  // ──────────────────────────────────────────────────────────
  //  REUSABLE CHART CARD WRAPPER
  // ──────────────────────────────────────────────────────────
  Widget _chartCard({
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required double height,
    required int delay,
    required Widget child,
    List<_LegendItem>? legendItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: isDark
            ? Border.all(color: color.withOpacity(0.08), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (legendItems != null && legendItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: legendItems.map((item) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
     .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut);
  }

  // ──────────────────────────────────────────────────────────
  //  GAUGE SECTION
  // ──────────────────────────────────────────────────────────
  Widget _buildGaugeSection(String dataType, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<FieldProvider>();
    final settings = context.watch<SettingsProvider>();
    final data = provider.currentSensorData;

    double value = 0;
    double minVal = 0;
    double maxVal = 100;
    String statusLabel = 'N/A';

    if (data != null) {
      switch (dataType) {
        case 'temperature':
          value = data.temperature;
          minVal = 0;
          maxVal = 50;
          statusLabel = data.temperatureStatus;
          break;
        case 'humidity':
          value = data.humidity;
          statusLabel = data.humidityStatus;
          break;
        case 'soilMoisture':
          value = data.soilMoisture;
          statusLabel = data.soilMoistureStatus;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: isDark
            ? Border.all(color: color.withOpacity(0.08), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    settings.tr('live_gauge'),
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(statusLabel).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  settings.tr(statusLabel.toLowerCase()),
                  style: TextStyle(
                    color: _statusColor(statusLabel),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: SensorGaugeChart(
              value: value,
              minValue: minVal,
              maxValue: maxVal,
              unit: unit,
              color: color,
              label: settings.tr(dataType.toLowerCase()),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('optimal')) return AppTheme.healthy;
    if (s.contains('critical') || s.contains('too') || s.contains('waterlog')) return AppTheme.critical;
    if (s.contains('low') || s.contains('high') || s.contains('sub')) return AppTheme.warning;
    if (s.contains('dry') || s.contains('humid')) return AppTheme.warning;
    return AppTheme.info;
  }

  // ──────────────────────────────────────────────────────────
  //  CURRENT VALUE CARD (gradient hero card)
  // ──────────────────────────────────────────────────────────
  Widget _buildCurrentValueCard(String dataType, String title, String unit, Color color) {
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
          colors: [color, color.withOpacity(0.75)],
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
            child: Icon(_getIcon(dataType), color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${settings.tr('current')} ${settings.tr(dataType.toLowerCase())}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value?.toStringAsFixed(1) ?? '--',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        unit,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600),
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
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, duration: 400.ms);
  }

  // ──────────────────────────────────────────────────────────
  //  STATISTICS CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildStatistics(String dataType, String unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    if (_historicalData.isEmpty) return const SizedBox.shrink();

    final List<double> values = _historicalData.map((d) {
      switch (dataType) {
        case 'temperature': return d.temperature;
        case 'humidity': return d.humidity;
        case 'soilMoisture': return d.soilMoisture;
        default: return 0.0;
      }
    }).toList();

    final provider = context.watch<FieldProvider>();
    final liveData = provider.currentSensorData;
    if (liveData != null) {
      switch (dataType) {
        case 'temperature': values.add(liveData.temperature); break;
        case 'humidity': values.add(liveData.humidity); break;
        case 'soilMoisture': values.add(liveData.soilMoisture); break;
      }
    }

    if (values.isEmpty) return const SizedBox.shrink();

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final range = max - min;

    final color = _getDataColor(dataType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: isDark
            ? Border.all(color: color.withOpacity(0.08), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                settings.tr('statistics'),
                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPeriod == '24h' ? '24h' : _selectedPeriod == '7d' ? '7 days' : '30 days',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('min', min.toStringAsFixed(1), unit, Icons.arrow_downward, AppTheme.info, isDark, settings),
              _buildStatItem('average', avg.toStringAsFixed(1), unit, Icons.trending_flat, AppTheme.warning, isDark, settings),
              _buildStatItem('max', max.toStringAsFixed(1), unit, Icons.arrow_upward, AppTheme.error, isDark, settings),
              _buildStatItem('range', range.toStringAsFixed(1), unit, Icons.unfold_more, color, isDark, settings),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon, Color color, bool isDark, SettingsProvider settings) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '$value$unit',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            settings.tr(label),
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDataColor(String dataType) {
    switch (dataType) {
      case 'temperature': return AppTheme.temperatureColor;
      case 'humidity': return AppTheme.humidityColor;
      case 'soilMoisture': return AppTheme.soilMoistureColor;
      default: return AppTheme.primaryGreen;
    }
  }

  IconData _getIcon(String dataType) {
    switch (dataType) {
      case 'temperature': return Icons.thermostat;
      case 'humidity': return Icons.water_drop;
      case 'soilMoisture': return Icons.grass;
      default: return Icons.analytics;
    }
  }
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}
