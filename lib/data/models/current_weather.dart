import '../../core/utils/json_parser.dart';

/// Data cuaca saat ini dari objek `current` Open-Meteo.
class CurrentWeather {
  final DateTime time;
  final double temperature;
  final int relativeHumidity;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
  final double surfacePressure;
  final bool isDay;
  final double? uvIndex;
  final double? visibility;

  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.relativeHumidity,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
    required this.surfacePressure,
    required this.isDay,
    this.uvIndex,
    this.visibility,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: DateTime.parse(json['time'] as String),
      temperature: asDouble(json['temperature_2m']),
      relativeHumidity: asInt(json['relative_humidity_2m']),
      apparentTemperature: asDouble(json['apparent_temperature']),
      precipitation: asDouble(json['precipitation']),
      weatherCode: asInt(json['weather_code']),
      windSpeed: asDouble(json['wind_speed_10m']),
      surfacePressure: asDouble(json['surface_pressure']),
      isDay: asInt(json['is_day']) == 1,
      uvIndex: asDoubleOrNull(json['uv_index']),
      visibility: asDoubleOrNull(json['visibility']),
    );
  }
}
