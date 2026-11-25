import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/theme/weather_gradients.dart';
import 'package:weather_app/core/utils/aqi_helper.dart';
import 'package:weather_app/core/utils/weather_code_mapper.dart';

void main() {
  group('WeatherCodeMapper', () {
    test('memberi label Indonesia untuk kode WMO', () {
      expect(WeatherCodeMapper.label(0), 'Cerah');
      expect(WeatherCodeMapper.label(3), 'Berawan');
      expect(WeatherCodeMapper.label(61), 'Hujan');
      expect(WeatherCodeMapper.label(95), 'Badai petir');
      expect(WeatherCodeMapper.label(999), 'Tidak diketahui');
    });

    test('memakai ikon matahari saat siang dan bulan saat malam', () {
      expect(WeatherCodeMapper.icon(0), Icons.wb_sunny_rounded);
      expect(
        WeatherCodeMapper.icon(0, isDay: false),
        Icons.nightlight_round,
      );
    });

    test('memakai ikon yang sesuai untuk hujan dan badai', () {
      expect(WeatherCodeMapper.icon(61), Icons.water_drop_rounded);
      expect(WeatherCodeMapper.icon(95), Icons.thunderstorm_rounded);
    });
  });

  group('WeatherGradients', () {
    test('cerah siang memakai gradien biru terang', () {
      final colors = WeatherGradients.forCode(0, isDay: true);
      expect(colors.first, const Color(0xFF2D7DD2));
      expect(colors.last, const Color(0xFF9ED2FF));
    });

    test('malam selalu memakai gradien gelap', () {
      final colors = WeatherGradients.forCode(0, isDay: false);
      expect(colors.first, const Color(0xFF0B1A3A));
      expect(colors.last, const Color(0xFF2E4A7D));
    });

    test('hujan memakai gradien biru tua', () {
      final colors = WeatherGradients.forCode(61, isDay: true);
      expect(colors.first, const Color(0xFF2A5CB8));
      expect(colors.last, const Color(0xFF8FBCF5));
    });
  });

  group('AqiHelper', () {
    test('memetakan nilai AQI ke kategori US AQI', () {
      expect(AqiHelper.category(31), 'Baik');
      expect(AqiHelper.category(75), 'Sedang');
      expect(
        AqiHelper.category(120),
        'Tidak sehat bagi kelompok sensitif',
      );
      expect(AqiHelper.category(180), 'Tidak sehat');
      expect(AqiHelper.category(250), 'Sangat tidak sehat');
      expect(AqiHelper.category(350), 'Berbahaya');
    });

    test('memberi deskripsi untuk kategori Baik', () {
      expect(
        AqiHelper.description(31),
        contains('aktivitas luar ruangan'),
      );
    });
  });
}
