import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../data/models/location.dart';
import '../data/repositories/location_repository.dart';
import 'view_state.dart';

/// State Search Screen: pencarian dengan debounce, favorit, dan riwayat.
class SearchViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;

  SearchViewModel(this._locationRepository);

  ViewState _state = ViewState.initial;
  List<Location> _results = const [];
  List<Location> _history = const [];
  String _query = '';
  String? _errorMessage;
  Timer? _debounce;
  int _requestToken = 0;
  bool _disposed = false;

  ViewState get state => _state;
  List<Location> get results => _results;
  List<Location> get history => _history;
  String get query => _query;
  String? get errorMessage => _errorMessage;

  Future<void> loadHistory() async {
    _history = await _locationRepository.getHistory();
    _notify();
  }

  /// Mengosongkan pencarian saat layar dibuka kembali, agar hasil sesi
  /// sebelumnya tidak tampil padahal field pencarian masih kosong.
  /// [notify] dimatikan saat dipanggil dari `initState`, karena notifikasi
  /// pada fase build akan memicu `markNeedsBuild` dan error.
  void reset({bool notify = true}) {
    _debounce?.cancel();
    _requestToken++;
    _query = '';
    _results = const [];
    _errorMessage = null;
    _state = ViewState.initial;
    if (notify) _notify();
  }

  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _requestToken++;

    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minimumQueryLength) {
      _results = const [];
      _errorMessage = null;
      _state = ViewState.initial;
      _notify();
      return;
    }

    // Tampilkan loading saat menunggu debounce agar UI responsif.
    _state = ViewState.loading;
    _errorMessage = null;
    _notify();

    _debounce = Timer(
      Duration(milliseconds: AppConstants.searchDebounceMs),
      () => _search(trimmed),
    );
  }

  Future<void> retry() async {
    final trimmed = _query.trim();
    if (trimmed.length < AppConstants.minimumQueryLength) return;
    await _search(trimmed);
  }

  Future<void> addToHistory(Location location) async {
    await _locationRepository.addHistory(location);
    _history = await _locationRepository.getHistory();
    _notify();
  }

  Future<void> clearHistory() async {
    await _locationRepository.clearHistory();
    _history = const [];
    _notify();
  }

  Future<void> _search(String query) async {
    final token = ++_requestToken;
    _state = ViewState.loading;
    _errorMessage = null;
    _notify();

    try {
      final results = await _locationRepository.searchCities(query);
      // Abaikan respons usang jika pengguna sudah mengetik query lain.
      if (token != _requestToken) return;
      _results = results;
      _state = results.isEmpty ? ViewState.empty : ViewState.success;
    } catch (error) {
      if (token != _requestToken) return;
      _errorMessage = error is AppException
          ? error.message
          : 'Gagal mencari kota. Silakan coba lagi.';
      _state = ViewState.error;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _requestToken++;
    super.dispose();
  }
}
