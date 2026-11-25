/// Konstanta endpoint dan parameter Open-Meteo.
/// Semua URL/parameter API dikumpulkan di sini agar mudah dijelaskan.
class ApiConstants {
  ApiConstants._();

  static const String forecastHost = 'api.open-meteo.com';
  static const String forecastPath = '/v1/forecast';

  static const String geocodingHost = 'geocoding-api.open-meteo.com';
  static const String geocodingPath = '/v1/search';

  static const String airQualityHost = 'air-quality-api.open-meteo.com';
  static const String airQualityPath = '/v1/air-quality';

  static const String currentFields =
      'temperature_2m,relative_humidity_2m,apparent_temperature,'
      'precipitation,weather_code,wind_speed_10m,surface_pressure,'
      'is_day,uv_index,visibility';

  static const String hourlyFields =
      'temperature_2m,weather_code,precipitation_probability';

  static const String dailyFields =
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max,sunrise,sunset';

  static const int forecastDays = 7;
  static const int geocodingCount = 10;
  static const String geocodingLanguage = 'id';
  static const String airQualityCurrent = 'us_aqi';

  static const Duration requestTimeout = Duration(seconds: 10);
}
