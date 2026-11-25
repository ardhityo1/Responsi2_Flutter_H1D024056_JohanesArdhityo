import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/constants/app_constants.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/data/models/location.dart';
import 'package:weather_app/data/repositories/location_repository.dart';
import 'package:weather_app/data/repositories/weather_repository.dart';
import 'package:weather_app/data/services/geocoding_api_service.dart';
import 'package:weather_app/data/services/local_storage_service.dart';
import 'package:weather_app/data/services/weather_api_service.dart';
import 'package:weather_app/viewmodels/favorites_viewmodel.dart';
import 'package:weather_app/viewmodels/view_state.dart';
import 'package:weather_app/viewmodels/weather_viewmodel.dart';

class _FakeWeatherApiService extends WeatherApiService {
  Map<String, dynamic> forecastResponse;
  Map<String, dynamic> airQualityResponse;
  Object? forecastError;
  Object? airQualityError;

  _FakeWeatherApiService({
    required this.forecastResponse,
    required this.airQualityResponse,
  });

  @override
  Future<Map<String, dynamic>> fetchForecast(
    double latitude,
    double longitude,
  ) async {
    if (forecastError != null) throw forecastError!;
    return forecastResponse;
  }

  @override
  Future<Map<String, dynamic>> fetchAirQuality(
    double latitude,
    double longitude,
  ) async {
    if (airQualityError != null) throw airQualityError!;
    return airQualityResponse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> forecastJson;
  late Map<String, dynamic> aqiJson;
  late _FakeWeatherApiService weatherApi;
  late LocationRepository locationRepository;
  late WeatherRepository weatherRepository;

  setUpAll(() {
    final raw = File('test/fixtures/forecast.json').readAsStringSync();
    forecastJson = jsonDecode(raw) as Map<String, dynamic>;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    aqiJson = {
      'current': {'time': '2026-11-25T17:00', 'us_aqi': 31},
    };
    weatherApi = _FakeWeatherApiService(
      forecastResponse: forecastJson,
      airQualityResponse: aqiJson,
    );
    weatherRepository = WeatherRepository(weatherApi);
    locationRepository = LocationRepository(
      GeocodingApiService(),
      LocalStorageService(prefs),
    );
  });

  group('WeatherViewModel', () {
    test('init memakai Jakarta sebagai default saat storage kosong', () async {
      final viewModel = WeatherViewModel(
        weatherRepository,
        locationRepository,
      );

      await viewModel.init();

      expect(viewModel.state, ViewState.success);
      expect(viewModel.location?.name, AppConstants.defaultCityName);
      expect(viewModel.location?.latitude, AppConstants.defaultLatitude);
      expect(viewModel.weather, isNotNull);
      expect(viewModel.airQuality?.usAqi, 31);
      expect(viewModel.todayMin, 25.6);
      expect(viewModel.todayMax, 33.3);

      viewModel.dispose();
    });

    test('init memuat last_location dari storage bila tersedia', () async {
      const saved = Location(
        name: 'Kota Purwokerto',
        latitude: -7.42139,
        longitude: 109.23444,
        admin1: 'Jawa Tengah',
        country: 'Indonesia',
      );
      await locationRepository.saveLastLocation(saved);

      final viewModel = WeatherViewModel(
        weatherRepository,
        locationRepository,
      );
      await viewModel.init();

      expect(viewModel.state, ViewState.success);
      expect(viewModel.location, equals(saved));
      expect(viewModel.location?.name, 'Kota Purwokerto');

      viewModel.dispose();
    });

    test('hourlyItems mengambil 24 jam dari current.time dan menyisipkan sunset', () async {
      final viewModel = WeatherViewModel(
        weatherRepository,
        locationRepository,
      );
      await viewModel.init();

      final items = viewModel.hourlyItems;
      expect(items, hasLength(25));
      expect(items.first.isNow, isTrue);
      expect(items.first.type, HourlyItemType.weather);
      expect(items.first.time, DateTime(2026, 11, 25, 17, 0));

      final sunsetItems = items
          .where((item) => item.type == HourlyItemType.sunset)
          .toList();
      expect(sunsetItems, hasLength(1));
      expect(sunsetItems.first.time, DateTime(2026, 11, 25, 17, 52));

      viewModel.dispose();
    });

    test('kegagalan AQI tidak menggagalkan WeatherViewModel', () async {
      weatherApi.airQualityError = const AppException('AQI gagal');
      final viewModel = WeatherViewModel(
        weatherRepository,
        locationRepository,
      );

      await viewModel.init();

      expect(viewModel.state, ViewState.success);
      expect(viewModel.weather, isNotNull);
      expect(viewModel.airQuality, isNull);

      viewModel.dispose();
    });

    test('refresh mempertahankan data lama saat gagal dan error state saat awal gagal', () async {
      final viewModel = WeatherViewModel(
        weatherRepository,
        locationRepository,
      );
      await viewModel.init();
      expect(viewModel.state, ViewState.success);

      weatherApi.forecastError = const AppException('Tidak ada koneksi internet.');
      await viewModel.refresh();

      expect(viewModel.state, ViewState.success);
      expect(viewModel.weather, isNotNull);
      expect(viewModel.errorMessage, 'Tidak ada koneksi internet.');

      await viewModel.selectLocation(
        const Location(name: 'Bandung', latitude: -6.9, longitude: 107.6),
      );
      expect(viewModel.state, ViewState.error);
      expect(viewModel.weather, isNull);
      expect(viewModel.errorMessage, 'Tidak ada koneksi internet.');

      viewModel.dispose();
    });
  });

  group('FavoritesViewModel', () {
    test('toggleFavorite menyimpan dan memuat ulang lokasi favorit', () async {
      const purwokerto = Location(
        name: 'Kota Purwokerto',
        latitude: -7.42139,
        longitude: 109.23444,
      );
      const bandung = Location(
        name: 'Bandung',
        latitude: -6.9175,
        longitude: 107.6191,
      );

      final viewModel = FavoritesViewModel(locationRepository);
      await viewModel.load();
      expect(viewModel.favorites, isEmpty);

      await viewModel.toggleFavorite(purwokerto);
      await viewModel.toggleFavorite(bandung);
      expect(viewModel.isFavorite(purwokerto), isTrue);
      expect(viewModel.favorites.first, equals(bandung));

      final reloaded = FavoritesViewModel(locationRepository);
      await reloaded.load();
      expect(reloaded.favorites, hasLength(2));
      expect(reloaded.isFavorite(purwokerto), isTrue);

      await reloaded.toggleFavorite(purwokerto);
      expect(reloaded.isFavorite(purwokerto), isFalse);
      expect(reloaded.favorites, hasLength(1));

      viewModel.dispose();
      reloaded.dispose();
    });
  });
}
