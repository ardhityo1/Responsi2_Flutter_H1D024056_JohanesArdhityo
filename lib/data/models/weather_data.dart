import '../../core/errors/app_exception.dart';
import '../../core/utils/json_parser.dart';
import 'current_weather.dart';
import 'daily_forecast.dart';
import 'hourly_forecast.dart';
import 'location.dart';

/// Gabungan data current, hourly, dan daily untuk satu lokasi.
class WeatherData {
  final Location location;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final String? timezone;
  final int utcOffsetSeconds;

  const WeatherData({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
    this.timezone,
    this.utcOffsetSeconds = 0,
  });

  /// Array `hourly` dan `daily` dari Open-Meteo bersifat paralel,
  /// jadi digabungkan per indeks menjadi list objek.
  factory WeatherData.fromJson(
    Map<String, dynamic> json,
    Location location,
  ) {
    final currentJson = json['current'];
    if (currentJson is! Map<String, dynamic>) {
      throw const AppException('Data cuaca saat ini tidak ditemukan.');
    }

    final hourlyJson = json['hourly'];
    final hourlyMap = hourlyJson is Map<String, dynamic> ? hourlyJson : null;
    final dailyJson = json['daily'];
    final dailyMap = dailyJson is Map<String, dynamic> ? dailyJson : null;

    final hourly = <HourlyForecast>[];
    final hourlyTimes = hourlyMap?['time'];
    if (hourlyTimes is List) {
      for (var i = 0; i < hourlyTimes.length; i++) {
        final time = asDateOrNull(hourlyTimes[i]);
        if (time == null) continue;
        hourly.add(
          HourlyForecast(
            time: time,
            temperature: asDouble(_valueAt(hourlyMap, 'temperature_2m', i)),
            weatherCode: asInt(_valueAt(hourlyMap, 'weather_code', i)),
            precipitationProbability: asIntOrNull(
              _valueAt(hourlyMap, 'precipitation_probability', i),
            ),
          ),
        );
      }
    }

    final daily = <DailyForecast>[];
    final dailyTimes = dailyMap?['time'];
    if (dailyTimes is List) {
      for (var i = 0; i < dailyTimes.length; i++) {
        final date = asDateOrNull(dailyTimes[i]);
        if (date == null) continue;
        daily.add(
          DailyForecast(
            date: date,
            weatherCode: asInt(_valueAt(dailyMap, 'weather_code', i)),
            temperatureMax: asDouble(
              _valueAt(dailyMap, 'temperature_2m_max', i),
            ),
            temperatureMin: asDouble(
              _valueAt(dailyMap, 'temperature_2m_min', i),
            ),
            precipitationProbabilityMax: asIntOrNull(
              _valueAt(dailyMap, 'precipitation_probability_max', i),
            ),
            sunrise: asDateOrNull(_valueAt(dailyMap, 'sunrise', i)),
            sunset: asDateOrNull(_valueAt(dailyMap, 'sunset', i)),
          ),
        );
      }
    }

    return WeatherData(
      location: location,
      current: CurrentWeather.fromJson(currentJson),
      hourly: hourly,
      daily: daily,
      timezone: asStringOrNull(json['timezone']),
      utcOffsetSeconds: asInt(json['utc_offset_seconds']),
    );
  }

  static dynamic _valueAt(
    Map<String, dynamic>? json,
    String key,
    int index,
  ) {
    final list = json?[key];
    if (list is List && index < list.length) return list[index];
    return null;
  }
}
