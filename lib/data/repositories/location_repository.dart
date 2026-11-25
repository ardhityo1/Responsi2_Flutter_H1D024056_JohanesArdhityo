import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../models/location.dart';
import '../services/geocoding_api_service.dart';
import '../services/local_storage_service.dart';

/// Sumber data lokasi: hasil geocoding dan penyimpanan lokal.
class LocationRepository {
  final GeocodingApiService _geocodingApi;
  final LocalStorageService _storage;

  LocationRepository(this._geocodingApi, this._storage);

  Future<List<Location>> searchCities(String query) async {
    final results = await _geocodingApi.searchCity(query);
    return results.map(Location.fromGeocodingJson).toList();
  }

  Future<List<Location>> getFavorites() {
    return _readLocations(AppConstants.favoritesKey);
  }

  Future<void> saveFavorites(List<Location> favorites) {
    return _writeLocations(AppConstants.favoritesKey, favorites);
  }

  Future<List<Location>> getHistory() {
    return _readLocations(AppConstants.searchHistoryKey);
  }

  Future<void> addHistory(Location location) async {
    final history = await getHistory();
    history.removeWhere((item) => item == location);
    history.insert(0, location);
    if (history.length > AppConstants.historyLimit) {
      history.removeRange(AppConstants.historyLimit, history.length);
    }
    await _writeLocations(AppConstants.searchHistoryKey, history);
  }

  Future<void> clearHistory() async {
    await _storage.remove(AppConstants.searchHistoryKey);
  }

  Future<Location?> getLastLocation() async {
    final raw = _storage.getString(AppConstants.lastLocationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return Location.fromJson(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> saveLastLocation(Location location) {
    return _storage.setString(
      AppConstants.lastLocationKey,
      jsonEncode(location.toJson()),
    );
  }

  Future<List<Location>> _readLocations(String key) async {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Location.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocations(String key, List<Location> locations) {
    final encoded = jsonEncode(
      locations.map((location) => location.toJson()).toList(),
    );
    return _storage.setString(key, encoded);
  }
}
