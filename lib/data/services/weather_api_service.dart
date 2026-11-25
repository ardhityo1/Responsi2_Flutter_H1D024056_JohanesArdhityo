import '../../core/constants/api_constants.dart';
import 'api_client.dart';

/// Service HTTP untuk Weather Forecast dan Air Quality Open-Meteo.
class WeatherApiService {
  final ApiClient _apiClient;

  WeatherApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> fetchForecast(
    double latitude,
    double longitude,
  ) {
    final uri = Uri.https(ApiConstants.forecastHost, ApiConstants.forecastPath, {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': ApiConstants.currentFields,
      'hourly': ApiConstants.hourlyFields,
      'daily': ApiConstants.dailyFields,
      'timezone': 'auto',
      'forecast_days': '${ApiConstants.forecastDays}',
      'wind_speed_unit': 'kmh',
    });
    return _apiClient.getJson(uri);
  }

  Future<Map<String, dynamic>> fetchAirQuality(
    double latitude,
    double longitude,
  ) {
    final uri = Uri.https(
      ApiConstants.airQualityHost,
      ApiConstants.airQualityPath,
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': ApiConstants.airQualityCurrent,
        'timezone': 'auto',
      },
    );
    return _apiClient.getJson(uri);
  }
}
