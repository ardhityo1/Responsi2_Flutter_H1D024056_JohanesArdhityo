import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/data/models/air_quality.dart';
import 'package:weather_app/data/models/location.dart';
import 'package:weather_app/data/models/weather_data.dart';

void main() {
  late Map<String, dynamic> forecastJson;
  late Location location;

  setUpAll(() {
    final raw = File('test/fixtures/forecast.json').readAsStringSync();
    forecastJson = jsonDecode(raw) as Map<String, dynamic>;
    location = const Location(
      name: 'Jakarta',
      latitude: -6.2146,
      longitude: 106.8451,
    );
  });

  group('Location', () {
    test('mem-parse hasil geocoding dan membuat displayName', () {
      final raw = File('test/fixtures/geocoding.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>;
      final parsed = Location.fromGeocodingJson(
        results.first as Map<String, dynamic>,
      );

      expect(parsed.name, 'Kota Purwokerto');
      expect(parsed.admin1, 'Jawa Tengah');
      expect(parsed.country, 'Indonesia');
      expect(parsed.displayName, 'Kota Purwokerto, Jawa Tengah, Indonesia');
      expect(parsed.latitude, closeTo(-7.42139, 0.000001));
    });

    test('displayName tidak menyisakan koma untuk bagian yang null', () {
      const parsed = Location(
        name: 'Jakarta',
        latitude: -6.2,
        longitude: 106.8,
      );
      expect(parsed.displayName, 'Jakarta');
    });

    test('dua lokasi dianggap sama berdasarkan koordinat', () {
      const a = Location(name: 'A', latitude: -6.2, longitude: 106.8);
      const b = Location(name: 'B', latitude: -6.2, longitude: 106.8);
      const c = Location(name: 'C', latitude: -6.3, longitude: 106.8);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('bisa disimpan dan dibaca kembali dari JSON', () {
      const original = Location(
        id: 1,
        name: 'Purwokerto',
        latitude: -7.42,
        longitude: 109.23,
        country: 'Indonesia',
        admin1: 'Jawa Tengah',
        timezone: 'Asia/Jakarta',
      );

      final restored = Location.fromJson(original.toJson());

      expect(restored.name, original.name);
      expect(restored.latitude, original.latitude);
      expect(restored.admin1, original.admin1);
      expect(restored, equals(original));
    });
  });

  group('WeatherData.fromJson', () {
    late WeatherData data;

    setUp(() {
      data = WeatherData.fromJson(forecastJson, location);
    });

    test('mem-parse data current dengan tipe angka yang aman', () {
      final current = data.current;
      expect(current.temperature, 28.6);
      expect(current.relativeHumidity, 80);
      expect(current.apparentTemperature, 35.1);
      expect(current.precipitation, 0.0);
      expect(current.weatherCode, 3);
      expect(current.windSpeed, 1.1);
      expect(current.surfacePressure, 1006.5);
      expect(current.isDay, isTrue);
      expect(current.uvIndex, 0.45);
      expect(current.visibility, 7460.0);
      expect(current.time, DateTime(2026, 11, 25, 17, 15));
    });

    test('menggabungkan array hourly yang paralel', () {
      expect(data.hourly, hasLength(168));
      expect(data.hourly.first.time, DateTime(2026, 11, 25, 0));
      expect(data.hourly.first.temperature, 26.0);
      expect(data.hourly.first.weatherCode, 3);
      expect(data.hourly.first.precipitationProbability, 50);
    });

    test('menggabungkan array daily yang paralel', () {
      expect(data.daily, hasLength(7));
      final today = data.daily.first;
      expect(today.date, DateTime(2026, 11, 25));
      expect(today.weatherCode, 80);
      expect(today.temperatureMax, 33.3);
      expect(today.temperatureMin, 25.6);
      expect(today.precipitationProbabilityMax, 95);
      expect(today.sunrise, DateTime(2026, 11, 25, 5, 26));
      expect(today.sunset, DateTime(2026, 11, 25, 17, 52));
    });

    test('menyimpan timezone dari respons', () {
      expect(data.timezone, 'Asia/Jakarta');
      expect(data.utcOffsetSeconds, 25200);
    });
  });

  group('AirQuality', () {
    test('mem-parse US AQI dan memberi kategori', () {
      final aqi = AirQuality.fromJson({
        'current': {'time': '2026-11-25T17:00', 'us_aqi': 31},
      });

      expect(aqi.usAqi, 31);
      expect(aqi.category, 'Baik');
      expect(aqi.description, contains('aktivitas luar ruangan'));
    });
  });
}
