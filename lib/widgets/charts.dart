import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class SensorLineChart extends StatelessWidget {
  final List<SensorData> data;
  final String dataType; // 'temperature', 'humidity', 'soilMoisture'
  final bool showGrid;
  final double? minY;
  final double? maxY;

  const SensorLineChart({
    super.key,
    required this.data,
    required this.dataType,
    this.showGrid = true,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: isDark 
                ? AppTheme.textSecondaryDark 
                : AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
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
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark 
                        ? AppTheme.textSecondaryDark 
                        : AppTheme.textSecondaryLight,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                final dataPoint = data[spot.x.toInt()];
                return LineTooltipItem(
                  '${_getValue(dataPoint).toStringAsFixed(1)}${_getUnit()}\n${DateFormat('HH:mm').format(dataPoint.timestamp)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: _getGradient().colors
                    .map((c) => c.withOpacity(0.2))
                    .toList(),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        _getValue(entry.value),
      );
    }).toList();
  }

  double _getValue(SensorData d) {
    switch (dataType) {
      case 'temperature':
        return d.temperature;
      case 'humidity':
        return d.humidity;
      case 'soilMoisture':
        return d.soilMoisture;
      default:
        return 0;
    }
  }

  String _getUnit() {
    switch (dataType) {
      case 'temperature':
        return '°C';
      case 'humidity':
      case 'soilMoisture':
        return '%';
      default:
        return '';
    }
  }

  LinearGradient _getGradient() {
    switch (dataType) {
      case 'temperature':
        return AppTheme.temperatureGradient;
      case 'humidity':
        return AppTheme.humidityGradient;
      case 'soilMoisture':
        return AppTheme.soilMoistureGradient;
      default:
        return AppTheme.primaryGradient;
    }
  }

  double _getMinY() {
    if (data.isEmpty) return 0;
    final values = data.map(_getValue).toList();
    return (values.reduce((a, b) => a < b ? a : b) - 5).clamp(0, double.infinity);
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
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        DateFormat('HH:mm').format(data[index].timestamp),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      ),
    );
  }
}

class DailyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String dataType;

  const DailyBarChart({
    super.key,
    required this.data,
    required this.dataType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: isDark 
                ? AppTheme.textSecondaryDark 
                : AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final value = rod.toY;
              final date = data[groupIndex]['date'] as DateTime;
              return BarTooltipItem(
                '${value.toStringAsFixed(1)}${_getUnit()}\n${DateFormat('MMM d').format(date)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final date = data[index]['date'] as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isDark 
                          ? AppTheme.textSecondaryDark 
                          : AppTheme.textSecondaryLight,
                      fontSize: 11,
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
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark 
                        ? AppTheme.textSecondaryDark 
                        : AppTheme.textSecondaryLight,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return data.asMap().entries.map((entry) {
      final value = _getValue(entry.value);
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: _getGradient(),
            width: 16,
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
      case 'temperature':
        return (d['temperature'] as num).toDouble();
      case 'humidity':
        return (d['humidity'] as num).toDouble();
      case 'soilMoisture':
        return (d['soilMoisture'] as num).toDouble();
      default:
        return 0;
    }
  }

  String _getUnit() {
    switch (dataType) {
      case 'temperature':
        return '°C';
      case 'humidity':
      case 'soilMoisture':
        return '%';
      default:
        return '';
    }
  }

  LinearGradient _getGradient() {
    switch (dataType) {
      case 'temperature':
        return AppTheme.temperatureGradient;
      case 'humidity':
        return AppTheme.humidityGradient;
      case 'soilMoisture':
        return AppTheme.soilMoistureGradient;
      default:
        return AppTheme.primaryGradient;
    }
  }
}
