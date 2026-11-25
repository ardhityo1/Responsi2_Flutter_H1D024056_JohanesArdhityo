/// Satu hari prakiraan cuaca.
class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double temperatureMax;
  final double temperatureMin;
  final int? precipitationProbabilityMax;
  final DateTime? sunrise;
  final DateTime? sunset;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    this.precipitationProbabilityMax,
    this.sunrise,
    this.sunset,
  });
}
