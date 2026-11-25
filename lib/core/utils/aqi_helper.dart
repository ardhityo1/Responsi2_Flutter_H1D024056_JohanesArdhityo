import 'package:flutter/material.dart';

/// Kategori US AQI dan warna indikatornya.
class AqiHelper {
  AqiHelper._();

  static const List<Color> barColors = [
    Color(0xFF00E400),
    Color(0xFFFFFF00),
    Color(0xFFFF7E00),
    Color(0xFFFF0000),
    Color(0xFF8F3F97),
    Color(0xFF7E0023),
  ];

  static String category(int? aqi) {
    if (aqi == null) return 'Tidak tersedia';
    if (aqi <= 50) return 'Baik';
    if (aqi <= 100) return 'Sedang';
    if (aqi <= 150) return 'Tidak sehat bagi kelompok sensitif';
    if (aqi <= 200) return 'Tidak sehat';
    if (aqi <= 300) return 'Sangat tidak sehat';
    return 'Berbahaya';
  }

  static String description(int? aqi) {
    if (aqi == null) return 'Data kualitas udara tidak tersedia.';
    if (aqi <= 50) {
      return 'Kualitas udara cocok untuk aktivitas luar ruangan.';
    }
    if (aqi <= 100) {
      return 'Kualitas udara dapat diterima bagi sebagian besar orang.';
    }
    if (aqi <= 150) {
      return 'Kelompok sensitif sebaiknya mengurangi aktivitas luar ruangan.';
    }
    if (aqi <= 200) {
      return 'Kurangi aktivitas luar ruangan yang berkepanjangan.';
    }
    if (aqi <= 300) {
      return 'Hindari aktivitas luar ruangan bila memungkinkan.';
    }
    return 'Tetap di dalam ruangan dan tutup ventilasi.';
  }

  static Color color(int? aqi) {
    if (aqi == null) return Colors.white70;
    if (aqi <= 50) return const Color(0xFF4CD964);
    if (aqi <= 100) return const Color(0xFFFFD60A);
    if (aqi <= 150) return const Color(0xFFFF9F0A);
    if (aqi <= 200) return const Color(0xFFFF453A);
    if (aqi <= 300) return const Color(0xFFBF5AF2);
    return const Color(0xFF9E1B32);
  }

  /// Posisi 0..1 untuk penanda pada bar gradien AQI.
  static double position(int? aqi) {
    if (aqi == null) return 0;
    return (aqi.clamp(0, 300) / 300).toDouble();
  }
}
