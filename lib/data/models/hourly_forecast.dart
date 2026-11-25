/// Satu titik data prakiraan per jam.
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int? precipitationProbability;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    this.precipitationProbability,
  });
}
