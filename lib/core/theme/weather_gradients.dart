import 'package:flutter/material.dart';

/// Gradien latar Weather Screen berdasarkan kode cuaca dan siang/malam.
class WeatherGradients {
  WeatherGradients._();

  static List<Color> forCode(int code, {required bool isDay}) {
    if (!isDay) {
      return const [Color(0xFF0B1A3A), Color(0xFF2E4A7D)];
    }
    if (code >= 95) {
      return const [Color(0xFF3B4A6B), Color(0xFF8A9BB8)];
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return const [Color(0xFF2A5CB8), Color(0xFF8FBCF5)];
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return const [Color(0xFF6B8FB5), Color(0xFFD6E4F0)];
    }
    if (code == 0) {
      return const [Color(0xFF2D7DD2), Color(0xFF9ED2FF)];
    }
    return const [Color(0xFF5B7BA6), Color(0xFFB5C7DB)];
  }

  static LinearGradient gradient(int code, {required bool isDay}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: forCode(code, isDay: isDay),
    );
  }
}
