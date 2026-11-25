import '../../core/utils/aqi_helper.dart';
import '../../core/utils/json_parser.dart';

/// Data kualitas udara (bonus) dari Open-Meteo Air Quality API.
class AirQuality {
  final int? usAqi;
  final DateTime? time;

  const AirQuality({this.usAqi, this.time});

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final currentMap = current is Map<String, dynamic> ? current : null;

    return AirQuality(
      usAqi: asIntOrNull(currentMap?['us_aqi']),
      time: asDateOrNull(currentMap?['time']),
    );
  }

  String get category => AqiHelper.category(usAqi);

  String get description => AqiHelper.description(usAqi);
}
