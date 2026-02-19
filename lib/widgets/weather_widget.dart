import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Weather widget displaying current conditions and forecast
class WeatherWidget extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback? onTap;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(weather.condition),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: _getGradientColors(weather.condition).first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Weather',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  _getWeatherIcon(weather.condition),
                  color: Colors.white,
                  size: 64,
                ).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.3)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildWeatherDetail(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${weather.humidity}%',
                ),
                const SizedBox(width: 24),
                _buildWeatherDetail(
                  icon: Icons.air,
                  label: 'Wind',
                  value: '${weather.windSpeed} km/h',
                ),
                const SizedBox(width: 24),
                _buildWeatherDetail(
                  icon: Icons.wb_sunny,
                  label: 'UV Index',
                  value: weather.uvIndex.toString(),
                ),
              ],
            ),
            if (weather.forecast.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weather.forecast.take(4).map((day) {
                  return _buildForecastDay(day);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: -0.1,
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForecastDay(ForecastDay day) {
    return Column(
      children: [
        Text(
          day.dayName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          _getWeatherIcon(day.condition),
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '${day.highTemp.round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${day.lowTemp.round()}°',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return [const Color(0xFFFF8C00), const Color(0xFFFFD700)];
      case WeatherCondition.partlyCloudy:
        return [const Color(0xFF5B86E5), const Color(0xFF36D1DC)];
      case WeatherCondition.cloudy:
        return [const Color(0xFF636E72), const Color(0xFF2D3436)];
      case WeatherCondition.rainy:
        return [const Color(0xFF3A6186), const Color(0xFF89253E)];
      case WeatherCondition.stormy:
        return [const Color(0xFF434343), const Color(0xFF000000)];
      case WeatherCondition.foggy:
        return [const Color(0xFF757F9A), const Color(0xFFD7DDE8)];
    }
  }

  IconData _getWeatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.partlyCloudy:
        return Icons.cloud_queue;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.rainy:
        return Icons.water_drop;
      case WeatherCondition.stormy:
        return Icons.thunderstorm;
      case WeatherCondition.foggy:
        return Icons.foggy;
    }
  }
}

/// Compact weather widget for smaller spaces
class CompactWeatherWidget extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback? onTap;

  const CompactWeatherWidget({
    super.key,
    required this.weather,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isDark ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getWeatherIcon(weather.condition),
                color: AppTheme.accentBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${weather.temperature.round()}°C',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weather.condition.label,
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 14,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weather.humidity}%',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.air,
                      size: 14,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weather.windSpeed} km/h',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.partlyCloudy:
        return Icons.cloud_queue;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.rainy:
        return Icons.water_drop;
      case WeatherCondition.stormy:
        return Icons.thunderstorm;
      case WeatherCondition.foggy:
        return Icons.foggy;
    }
  }
}

/// Weather data model
class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int uvIndex;
  final WeatherCondition condition;
  final List<ForecastDay> forecast;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.condition,
    this.forecast = const [],
  });

  /// Default mock weather data
  factory WeatherData.mock() {
    return WeatherData(
      temperature: 28.5,
      humidity: 65,
      windSpeed: 12.0,
      uvIndex: 6,
      condition: WeatherCondition.partlyCloudy,
      forecast: [
        ForecastDay(dayName: 'Thu', highTemp: 30, lowTemp: 22, condition: WeatherCondition.sunny),
        ForecastDay(dayName: 'Fri', highTemp: 28, lowTemp: 21, condition: WeatherCondition.partlyCloudy),
        ForecastDay(dayName: 'Sat', highTemp: 26, lowTemp: 20, condition: WeatherCondition.rainy),
        ForecastDay(dayName: 'Sun', highTemp: 27, lowTemp: 21, condition: WeatherCondition.partlyCloudy),
      ],
    );
  }
}

/// Forecast day data
class ForecastDay {
  final String dayName;
  final double highTemp;
  final double lowTemp;
  final WeatherCondition condition;

  const ForecastDay({
    required this.dayName,
    required this.highTemp,
    required this.lowTemp,
    required this.condition,
  });
}

/// Weather conditions
enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  stormy,
  foggy,
}

extension WeatherConditionExtension on WeatherCondition {
  String get label {
    switch (this) {
      case WeatherCondition.sunny:
        return 'Sunny';
      case WeatherCondition.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.stormy:
        return 'Stormy';
      case WeatherCondition.foggy:
        return 'Foggy';
    }
  }
}
