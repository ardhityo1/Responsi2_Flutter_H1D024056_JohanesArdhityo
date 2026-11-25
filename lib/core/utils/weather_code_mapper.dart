import 'package:flutter/material.dart';

/// Menerjemahkan kode cuaca WMO dari Open-Meteo menjadi label dan ikon.
class WeatherCodeMapper {
  WeatherCodeMapper._();

  static String label(int code) {
    if (code == 0) return 'Cerah';
    if (code == 1 || code == 2) return 'Cerah berawan';
    if (code == 3) return 'Berawan';
    if (code == 45 || code == 48) return 'Berkabut';
    if (code >= 51 && code <= 57) return 'Gerimis';
    if (code >= 61 && code <= 67) return 'Hujan';
    if (code >= 71 && code <= 77) return 'Salju';
    if (code >= 80 && code <= 82) return 'Hujan lebat';
    if (code == 85 || code == 86) return 'Hujan salju';
    if (code >= 95 && code <= 99) return 'Badai petir';
    return 'Tidak diketahui';
  }

  static IconData icon(int code, {bool isDay = true}) {
    if (code == 0) {
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    }
    if (code == 1 || code == 2) {
      return isDay ? Icons.wb_cloudy_rounded : Icons.cloud_queue_rounded;
    }
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 57) return Icons.grain_rounded;
    if (code >= 61 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.water_drop_rounded;
    if (code == 85 || code == 86) return Icons.ac_unit_rounded;
    if (code >= 95 && code <= 99) return Icons.thunderstorm_rounded;
    return Icons.help_outline_rounded;
  }

  /// Ikon untuk peluang hujan di kartu prakiraan.
  static IconData precipitationIcon(int code) {
    if (code >= 95) return Icons.thunderstorm_rounded;
    if (code >= 71 && code <= 86) return Icons.ac_unit_rounded;
    return Icons.water_drop_rounded;
  }
}
