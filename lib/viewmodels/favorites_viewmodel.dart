import 'package:flutter/foundation.dart';

import '../data/models/location.dart';
import '../data/repositories/location_repository.dart';

/// Menyimpan daftar lokasi favorit dan menyinkronkannya ke storage.
class FavoritesViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;

  FavoritesViewModel(this._locationRepository);

  List<Location> _favorites = const [];
  bool _disposed = false;

  List<Location> get favorites => _favorites;

  Future<void> load() async {
    _favorites = await _locationRepository.getFavorites();
    _notify();
  }

  bool isFavorite(Location location) {
    return _favorites.any((item) => item == location);
  }

  Future<void> toggleFavorite(Location location) async {
    if (isFavorite(location)) {
      _favorites = _favorites.where((item) => item != location).toList();
    } else {
      _favorites = [location, ..._favorites];
    }
    await _locationRepository.saveFavorites(_favorites);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
