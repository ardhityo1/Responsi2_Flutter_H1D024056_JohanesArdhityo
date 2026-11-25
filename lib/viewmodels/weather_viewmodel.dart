import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../data/models/air_quality.dart';
import '../data/models/daily_forecast.dart';
import '../data/models/hourly_forecast.dart';
import '../data/models/location.dart';
import '../data/models/weather_data.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/weather_repository.dart';
import 'view_state.dart';

enum HourlyItemType { weather, sunrise, sunset }

/// Satu kolom pada kartu jam-per-jam. Bisa berupa cuaca per jam
/// atau penanda matahari terbit/terbenam.
class HourlyItem {
  final DateTime time;
  final HourlyItemType type;
  final double? temperature;
  final int? weatherCode;
  final bool isNow;
  final bool isDay;

  const HourlyItem({
    required this.time,
    required this.type,
    this.temperature,
    this.weatherCode,
    this.isNow = false,
    this.isDay = true,
  });

  HourlyItem asNow() {
    return HourlyItem(
      time: time,
      type: type,
      temperature: temperature,
      weatherCode: weatherCode,
      isNow: true,
      isDay: isDay,
    );
  }
}

/// State utama Weather Screen.
class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _weatherRepository;
  final LocationRepository _locationRepository;

  WeatherViewModel(this._weatherRepository, this._locationRepository);

  ViewState _state = ViewState.initial;
  Location? _location;
  WeatherData? _weather;
  AirQuality? _airQuality;
  String? _errorMessage;
  bool _showLineChart = true;
  bool _initialized = false;
  bool _disposed = false;

  ViewState get state => _state;
  Location? get location => _location;
  WeatherData? get weather => _weather;
  AirQuality? get airQuality => _airQuality;
  String? get errorMessage => _errorMessage;
  bool get showLineChart => _showLineChart;

  double? get todayMin {
    final daily = _weather?.daily;
    if (daily == null || daily.isEmpty) return null;
    return daily.first.temperatureMin;
  }

  double? get todayMax {
    final daily = _weather?.daily;
    if (daily == null || daily.isEmpty) return null;
    return daily.first.temperatureMax;
  }

  DailyForecast? get today {
    final daily = _weather?.daily;
    if (daily == null || daily.isEmpty) return null;
    return daily.first;
  }

  /// Jam-per-jam mulai dari jam sekarang, ditambah penanda
  /// matahari terbit/terbenam jika jatuh dalam rentang 24 jam.
  List<HourlyItem> get hourlyItems {
    final data = _weather;
    if (data == null) return const [];

    final currentTime = data.current.time;
    final start = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      currentTime.hour,
    );
    final end = start.add(const Duration(hours: 24));

    final items = <HourlyItem>[];
    for (final HourlyForecast hour in data.hourly) {
      if (hour.time.isBefore(start) || !hour.time.isBefore(end)) continue;
      items.add(
        HourlyItem(
          time: hour.time,
          type: HourlyItemType.weather,
          temperature: hour.temperature,
          weatherCode: hour.weatherCode,
          isDay: _isDayAt(hour.time),
        ),
      );
    }

    final todayForecast = today;
    _addSunEvent(
      items,
      todayForecast?.sunrise,
      HourlyItemType.sunrise,
      start,
      end,
    );
    _addSunEvent(
      items,
      todayForecast?.sunset,
      HourlyItemType.sunset,
      start,
      end,
    );

    items.sort((a, b) => a.time.compareTo(b.time));
    final firstWeatherIndex = items.indexWhere(
      (item) => item.type == HourlyItemType.weather,
    );
    if (firstWeatherIndex >= 0) {
      items[firstWeatherIndex] = items[firstWeatherIndex].asNow();
    }
    return items;
  }

  void _addSunEvent(
    List<HourlyItem> items,
    DateTime? time,
    HourlyItemType type,
    DateTime start,
    DateTime end,
  ) {
    if (time == null) return;
    if (time.isBefore(start) || !time.isBefore(end)) return;
    items.add(
      HourlyItem(
        time: time,
        type: type,
        temperature: _temperatureAt(time),
        isDay: type == HourlyItemType.sunrise,
      ),
    );
  }

  /// Perkiraan suhu pada waktu terbit/terbenam diambil dari jam terdekat.
  double? _temperatureAt(DateTime time) {
    final hourly = _weather?.hourly;
    if (hourly == null || hourly.isEmpty) return null;

    var nearest = hourly.first;
    var nearestDiff = nearest.time.difference(time).inMinutes.abs();
    for (final hour in hourly) {
      final diff = hour.time.difference(time).inMinutes.abs();
      if (diff < nearestDiff) {
        nearest = hour;
        nearestDiff = diff;
      }
    }
    return nearest.temperature;
  }

  /// Menentukan siang/malam berdasarkan sunrise & sunset hari tersebut.
  bool _isDayAt(DateTime time) {
    final daily = _weather?.daily;
    if (daily == null) return true;

    for (final day in daily) {
      if (day.date.year == time.year &&
          day.date.month == time.month &&
          day.date.day == time.day) {
        final sunrise = day.sunrise;
        final sunset = day.sunset;
        if (sunrise != null && sunset != null) {
          return !time.isBefore(sunrise) && time.isBefore(sunset);
        }
      }
    }
    return time.hour >= 6 && time.hour < 18;
  }

  /// Memuat lokasi terakhir dari storage; jika kosong pakai Jakarta.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final saved = await _locationRepository.getLastLocation();
    final location =
        saved ??
        const Location(
          name: AppConstants.defaultCityName,
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
        );
    await selectLocation(location);
  }

  Future<void> selectLocation(Location location) async {
    _location = location;
    _weather = null;
    _airQuality = null;
    _errorMessage = null;
    _state = ViewState.loading;
    _notify();
    await _locationRepository.saveLastLocation(location);
    await _fetch();
  }

  Future<void> refresh() async {
    if (_location == null) return;
    final hasData = _weather != null;
    if (!hasData) {
      _state = ViewState.loading;
      _errorMessage = null;
      _notify();
    }
    await _fetch(keepDataOnError: hasData);
  }

  Future<void> retry() async {
    if (_location == null) {
      await init();
      return;
    }
    _state = ViewState.loading;
    _errorMessage = null;
    _notify();
    await _fetch();
  }

  void toggleChartMode(bool showLine) {
    if (_showLineChart == showLine) return;
    _showLineChart = showLine;
    _notify();
  }

  Future<void> _fetch({bool keepDataOnError = false}) async {
    final location = _location;
    if (location == null) return;

    try {
      final data = await _weatherRepository.getWeather(location);
      final airQuality = await _weatherRepository.getAirQuality(location);
      _weather = data;
      _airQuality = airQuality;
      _errorMessage = null;
      _state = ViewState.success;
    } catch (error) {
      final message = error is AppException
          ? error.message
          : 'Gagal memuat data cuaca. Silakan coba lagi.';
      _errorMessage = message;
      if (!keepDataOnError) {
        _state = ViewState.error;
      }
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
