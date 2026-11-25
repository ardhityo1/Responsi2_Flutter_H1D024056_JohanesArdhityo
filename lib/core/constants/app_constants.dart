/// Konstanta aplikasi yang bukan bagian dari API.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cuaca';
  static const String defaultCityName = 'Jakarta';
  static const double defaultLatitude = -6.2146;
  static const double defaultLongitude = 106.8451;

  static const String favoritesKey = 'favorites';
  static const String searchHistoryKey = 'search_history';
  static const String lastLocationKey = 'last_location';

  static const int historyLimit = 10;
  static const int searchDebounceMs = 500;
  static const int minimumQueryLength = 2;
}
