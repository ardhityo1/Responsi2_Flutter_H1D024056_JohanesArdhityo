import '../../core/constants/api_constants.dart';
import 'api_client.dart';

/// Service HTTP untuk mencari kota lewat Open-Meteo Geocoding API.
class GeocodingApiService {
  final ApiClient _apiClient;

  GeocodingApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> searchCity(String name) async {
    final uri = Uri.https(
      ApiConstants.geocodingHost,
      ApiConstants.geocodingPath,
      {
        'name': name,
        'count': '${ApiConstants.geocodingCount}',
        'language': ApiConstants.geocodingLanguage,
        'format': 'json',
      },
    );

    final json = await _apiClient.getJson(uri);
    final results = json['results'];

    // Open-Meteo tidak mengirim key `results` sama sekali jika kota
    // tidak ditemukan, jadi kondisi ini diperlakukan sebagai list kosong.
    if (results is! List) return const [];
    return results.whereType<Map<String, dynamic>>().toList();
  }
}
