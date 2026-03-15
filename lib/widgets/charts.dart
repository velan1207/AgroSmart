import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────
//  1. SENSOR LINE CHART  (enhanced with period-aware labels)
// ─────────────────────────────────────────────────────────────
class SensorLineChart extends StatelessWidget {
  final List<SensorData> data;
  final String dataType;
  final String period; // '24h', '7d', '30d'
  final bool showGrid;
  final double? minY;
  final double? maxY;

  const SensorLineChart({
    super.key,
    required this.data,
    required this.dataType,
    this.period = '24h',
    this.showGrid = true,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return _emptyState(isDark, Icons.show_chart, 'Collecting data...', 'Graph will appear as data is recorded');
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: _getYInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getInterval(),
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getYInterval(),
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY ?? _getMinY(),
        maxY: maxY ?? _getMaxY(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt().clamp(0, data.length - 1);
                final dp = data[idx];
                String timeLabel;
                if (period == '24h') {
                  timeLabel = DateFormat('HH:mm').format(dp.timestamp);
                } else if (period == '7d') {
                  timeLabel = DateFormat('E HH:mm').format(dp.timestamp);
                } else {
                  timeLabel = DateFormat('MMM d').format(dp.timestamp);
                }
                return LineTooltipItem(
                  '${_getValue(dp).toStringAsFixed(1)}${_getUnit()}\n$timeLabel',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            gradient: _getGradient(),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 30,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: _getGradient().colors.first,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: _getGradient().colors.map((c) => c.withOpacity(0.15)).toList(),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  List<FlSpot> _getSpots() =>
      data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _getValue(e.value))).toList();

  double _getValue(SensorData d) {
    switch (dataType) {
      case 'temperature': return d.temperature;
      case 'humidity': return d.humidity;
      case 'soilMoisture': return d.soilMoisture;
      default: return 0;
    }
  }

  String _getUnit() {
    switch (dataType) {
      case 'temperature': return '°C';
      case 'humidity':
      case 'soilMoisture': return '%';
      default: return '';
    }
  }

  LinearGradient _getGradient() {
    switch (dataType) {
      case 'temperature': return AppTheme.temperatureGradient;
      case 'humidity': return AppTheme.humidityGradient;
      case 'soilMoisture': return AppTheme.soilMoistureGradient;
      default: return AppTheme.primaryGradient;
    }
  }

  double _getMinY() {
    if (data.isEmpty) return 0;
    final values = data.map(_getValue).toList();
    return (values.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, double.infinity);
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    final values = data.map(_getValue).toList();
    return values.reduce((a, b) => a > b ? a : b) + 5;
  }

  double _getInterval() {
    if (data.length <= 6) return 1;
    return (data.length / 6).ceilToDouble();
  }

  double _getYInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) return const SizedBox.shrink();
    String label;
    if (period == '30d') {
      label = DateFormat('d/M').format(data[index].timestamp);
    } else if (period == '7d') {
      label = DateFormat('E').format(data[index].timestamp);
    } else {
      label = DateFormat('HH:mm').format(data[index].timestamp);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. DAILY BAR CHART  (unchanged logic, polish)
// ─────────────────────────────────────────────────────────────
class DailyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String dataType;

  const DailyBarChart({super.key, required this.data, required this.dataType});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return _emptyState(isDark, Icons.bar_chart, 'Building daily averages...', 'Data will appear after 24 hours');
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxBarY(),
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final value = rod.toY;
              final date = data[groupIndex]['date'] as DateTime;
              return BarTooltipItem(
                '${value.toStringAsFixed(1)}${_getUnit()}\n${DateFormat('MMM d').format(date)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final date = data[index]['date'] as DateTime;
                String label;
                if (data.length > 14) {
                  label = DateFormat('d/M').format(date);
                } else {
                  label = DateFormat('E').format(date);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: data.length > 14 ? 8 : 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(),
      ),
    );
  }

  double _getMaxBarY() {
    if (data.isEmpty) return 100;
    double maxVal = 0;
    for (final d in data) {
      final v = _getValue(d);
      if (v > maxVal) maxVal = v;
    }
    return (maxVal + 10).clamp(0, 120);
  }

  List<BarChartGroupData> _getBarGroups() {
    final barWidth = data.length > 14 ? 8.0 : 16.0;
    return data.asMap().entries.map((entry) {
      final value = _getValue(entry.value);
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: _getGradient(),
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getValue(Map<String, dynamic> d) {
    switch (dataType) {
      case 'temperature': return (d['temperature'] as num).toDouble();
      case 'humidity': return (d['humidity'] as num).toDouble();
      case 'soilMoisture': return (d['soilMoisture'] as num).toDouble();
      default: return 0;
    }
  }

  String _getUnit() {
    switch (dataType) {
      case 'temperature': return '°C';
      case 'humidity':
      case 'soilMoisture': return '%';
      default: return '';
    }
  }

  LinearGradient _getGradient() {
    switch (dataType) {
      case 'temperature': return AppTheme.temperatureGradient;
      case 'humidity': return AppTheme.humidityGradient;
      case 'soilMoisture': return AppTheme.soilMoistureGradient;
      default: return AppTheme.primaryGradient;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  3. SENSOR GAUGE CHART  (radial arc gauge for current value)
// ─────────────────────────────────────────────────────────────
class SensorGaugeChart extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final Color color;
  final String label;

  const SensorGaugeChart({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _GaugePainter(
        value: value,
        minValue: minValue,
        maxValue: maxValue,
        color: color,
        isDark: isDark,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color color;
  final bool isDark;

  _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = math.min(size.width, size.height) * 0.4;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Value arc
    final progress = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final valuePaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [color.withOpacity(0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      valuePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      glowPaint,
    );

    // End-dot
    final angle = startAngle + sweepAngle * progress;
    final dotCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(dotCenter, 6, Paint()..color = color);
    canvas.drawCircle(dotCenter, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────────────────────
//  4. MIN / MAX RANGE CHART  (band between min & max per day)
// ─────────────────────────────────────────────────────────────
class MinMaxRangeChart extends StatelessWidget {
  final List<SensorData> data;
  final String dataType;
  final String period;

  const MinMaxRangeChart({
    super.key,
    required this.data,
    required this.dataType,
    this.period = '7d',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return _emptyState(isDark, Icons.align_vertical_center, 'No range data yet', 'Min/Max range will appear here');
    }

    // Group by day
    final Map<String, List<double>> grouped = {};
    for (final d in data) {
      final key = DateFormat('yyyy-MM-dd').format(d.timestamp);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(_getValue(d));
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final List<_RangePoint> rangePoints = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      final vals = grouped[sortedKeys[i]]!;
      rangePoints.add(_RangePoint(
        x: i.toDouble(),
        min: vals.reduce((a, b) => a < b ? a : b),
        max: vals.reduce((a, b) => a > b ? a : b),
        avg: vals.reduce((a, b) => a + b) / vals.length,
        label: sortedKeys[i],
      ));
    }

    if (rangePoints.isEmpty) {
      return _emptyState(isDark, Icons.show_chart, 'Not enough data', 'Need at least one day of data');
    }

    final color = _getColor();
    final allVals = rangePoints.expand((r) => [r.min, r.max]).toList();
    final chartMinY = (allVals.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, double.infinity);
    final chartMaxY = allVals.reduce((a, b) => a > b ? a : b) + 5;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rangePoints.length - 1).toDouble(),
        minY: chartMinY,
        maxY: chartMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: rangePoints.length <= 7 ? 1 : (rangePoints.length / 6).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= rangePoints.length) return const SizedBox.shrink();
                final date = DateTime.tryParse(rangePoints[idx].label);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    date != null ? DateFormat('d/M').format(date) : rangePoints[idx].label,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.x.toInt().clamp(0, rangePoints.length - 1);
              final rp = rangePoints[idx];
              if (spot.barIndex == 0) {
                return LineTooltipItem(
                  'Max: ${rp.max.toStringAsFixed(1)}\nAvg: ${rp.avg.toStringAsFixed(1)}\nMin: ${rp.min.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                );
              }
              return null;
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Max line
          LineChartBarData(
            spots: rangePoints.map((r) => FlSpot(r.x, r.max)).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Average line (dashed)
          LineChartBarData(
            spots: rangePoints.map((r) => FlSpot(r.x, r.avg)).toList(),
            isCurved: true,
            color: color.withOpacity(0.6),
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
          // Min line
          LineChartBarData(
            spots: rangePoints.map((r) => FlSpot(r.x, r.min)).toList(),
            isCurved: true,
            color: color.withOpacity(0.35),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Filled range band (between max and min)
          LineChartBarData(
            spots: rangePoints.map((r) => FlSpot(r.x, r.max)).toList(),
            isCurved: true,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.10),
              cutOffY: chartMinY,
              applyCutOffY: true,
            ),
          ),
        ],
        betweenBarsData: [
          BetweenBarsData(
            fromIndex: 0,  // Max
            toIndex: 2,    // Min
            color: color.withOpacity(0.12),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  double _getValue(SensorData d) {
    switch (dataType) {
      case 'temperature': return d.temperature;
      case 'humidity': return d.humidity;
      case 'soilMoisture': return d.soilMoisture;
      default: return 0;
    }
  }

  Color _getColor() {
    switch (dataType) {
      case 'temperature': return AppTheme.temperatureColor;
      case 'humidity': return AppTheme.humidityColor;
      case 'soilMoisture': return AppTheme.soilMoistureColor;
      default: return AppTheme.primaryGreen;
    }
  }
}

class _RangePoint {
  final double x, min, max, avg;
  final String label;
  _RangePoint({required this.x, required this.min, required this.max, required this.avg, required this.label});
}

// ─────────────────────────────────────────────────────────────
//  5. HOURLY DISTRIBUTION CHART  (24-hour bar distribution)
// ─────────────────────────────────────────────────────────────
class HourlyDistributionChart extends StatelessWidget {
  final List<SensorData> data;
  final String dataType;

  const HourlyDistributionChart({
    super.key,
    required this.data,
    required this.dataType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return _emptyState(isDark, Icons.access_time, 'No hourly data', 'Hourly distribution will appear here');
    }

    // Group by hour (0-23)
    final Map<int, List<double>> hourlyBuckets = {};
    for (int h = 0; h < 24; h++) {
      hourlyBuckets[h] = [];
    }
    for (final d in data) {
      hourlyBuckets[d.timestamp.hour]!.add(_getValue(d));
    }

    final color = _getColor();
    double overallMax = 1;
    final avgByHour = <int, double>{};
    for (int h = 0; h < 24; h++) {
      if (hourlyBuckets[h]!.isNotEmpty) {
        final avg = hourlyBuckets[h]!.reduce((a, b) => a + b) / hourlyBuckets[h]!.length;
        avgByHour[h] = avg;
        if (avg > overallMax) overallMax = avg;
      } else {
        avgByHour[h] = 0;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: overallMax + 10,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}${_getUnit()}\n${group.x.toString().padLeft(2, '0')}:00',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                if (h % 3 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${h.toString().padLeft(2, '0')}h',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (h) {
          final val = avgByHour[h] ?? 0;
          final intensity = overallMax > 0 ? (val / overallMax).clamp(0.0, 1.0) : 0.0;
          return BarChartGroupData(
            x: h,
            barRods: [
              BarChartRodData(
                toY: val,
                color: color.withOpacity(0.4 + intensity * 0.6),
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _getValue(SensorData d) {
    switch (dataType) {
      case 'temperature': return d.temperature;
      case 'humidity': return d.humidity;
      case 'soilMoisture': return d.soilMoisture;
      default: return 0;
    }
  }

  String _getUnit() {
    switch (dataType) {
      case 'temperature': return '°C';
      case 'humidity':
      case 'soilMoisture': return '%';
      default: return '';
    }
  }

  Color _getColor() {
    switch (dataType) {
      case 'temperature': return AppTheme.temperatureColor;
      case 'humidity': return AppTheme.humidityColor;
      case 'soilMoisture': return AppTheme.soilMoistureColor;
      default: return AppTheme.primaryGreen;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  6. TREND COMPARISON CHART  (overlays avg line on bar chart)
// ─────────────────────────────────────────────────────────────
class TrendComparisonChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String dataType;

  const TrendComparisonChart({
    super.key,
    required this.data,
    required this.dataType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return _emptyState(isDark, Icons.trending_up, 'No trend data', 'Trend analysis will appear here');
    }

    final color = _getColor();
    final values = data.map((d) => _getValue(d)).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final chartMaxY = maxVal + 10;

    // Calculate moving average (window of 3)
    final List<FlSpot> maSpots = [];
    for (int i = 0; i < values.length; i++) {
      double sum = 0;
      int count = 0;
      for (int j = math.max(0, i - 1); j <= math.min(values.length - 1, i + 1); j++) {
        sum += values[j];
        count++;
      }
      maSpots.add(FlSpot(i.toDouble(), sum / count));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: (minVal - 5).clamp(0.0, double.infinity),
        maxY: chartMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: data.length <= 7 ? 1 : (data.length / 6).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final date = data[idx]['date'] as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.length > 14 ? DateFormat('d/M').format(date) : DateFormat('E').format(date),
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.x.toInt().clamp(0, data.length - 1);
              final date = data[idx]['date'] as DateTime;
              if (spot.barIndex == 0) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}${_getUnit()}\n${DateFormat('MMM d').format(date)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }
              return LineTooltipItem(
                'Trend: ${spot.y.toStringAsFixed(1)}',
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Actual values
          LineChartBarData(
            spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length <= 14,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.02)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Moving average trend
          LineChartBarData(
            spots: maSpots,
            isCurved: true,
            color: color.withOpacity(0.4),
            barWidth: 2,
            dashArray: [8, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  double _getValue(Map<String, dynamic> d) {
    switch (dataType) {
      case 'temperature': return (d['temperature'] as num).toDouble();
      case 'humidity': return (d['humidity'] as num).toDouble();
      case 'soilMoisture': return (d['soilMoisture'] as num).toDouble();
      default: return 0;
    }
  }

  String _getUnit() {
    switch (dataType) {
      case 'temperature': return '°C';
      case 'humidity':
      case 'soilMoisture': return '%';
      default: return '';
    }
  }

  Color _getColor() {
    switch (dataType) {
      case 'temperature': return AppTheme.temperatureColor;
      case 'humidity': return AppTheme.humidityColor;
      case 'soilMoisture': return AppTheme.soilMoistureColor;
      default: return AppTheme.primaryGreen;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED EMPTY STATE HELPER
// ─────────────────────────────────────────────────────────────
Widget _emptyState(bool isDark, IconData icon, String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 48,
          color: isDark
              ? AppTheme.textSecondaryDark.withOpacity(0.5)
              : AppTheme.textSecondaryLight.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? AppTheme.textSecondaryDark.withOpacity(0.7)
                : AppTheme.textSecondaryLight.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
