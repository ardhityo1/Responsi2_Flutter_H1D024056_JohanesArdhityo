import 'package:shared_preferences/shared_preferences.dart';

/// Pembungkus SharedPreferences agar ViewModel tidak menyentuh storage
/// secara langsung.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? const [];
  }

  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  Future<bool> remove(String key) => _prefs.remove(key);
}
