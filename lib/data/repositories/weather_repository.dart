import '../models/air_quality.dart';
import '../models/location.dart';
import '../models/weather_data.dart';
import '../services/weather_api_service.dart';

/// Menghubungkan service cuaca dengan model yang dipakai ViewModel.
class WeatherRepository {
  final WeatherApiService _weatherApi;

  WeatherRepository(this._weatherApi);

  Future<WeatherData> getWeather(Location location) async {
    final json = await _weatherApi.fetchForecast(
      location.latitude,
      location.longitude,
    );
    return WeatherData.fromJson(json, location);
  }

  /// AQI hanya bonus. Jika gagal, layar cuaca tetap boleh tampil.
  Future<AirQuality?> getAirQuality(Location location) async {
    try {
      final json = await _weatherApi.fetchAirQuality(
        location.latitude,
        location.longitude,
      );
      return AirQuality.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
