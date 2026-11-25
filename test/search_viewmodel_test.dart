import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/data/models/location.dart';
import 'package:weather_app/data/repositories/location_repository.dart';
import 'package:weather_app/data/services/geocoding_api_service.dart';
import 'package:weather_app/data/services/local_storage_service.dart';
import 'package:weather_app/viewmodels/favorites_viewmodel.dart';
import 'package:weather_app/viewmodels/search_viewmodel.dart';
import 'package:weather_app/viewmodels/view_state.dart';
import 'package:weather_app/views/screens/search_screen.dart';

Location _location(int index) {
  return Location(
    name: 'Kota $index',
    latitude: -6.2 - index,
    longitude: 106.8 + index,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocationRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = LocationRepository(
      GeocodingApiService(),
      LocalStorageService(prefs),
    );
  });

  group('LocationRepository', () {
    test('menyimpan favorit dan membacanya kembali', () async {
      final a = _location(1);
      final b = _location(2);

      await repository.saveFavorites([a, b]);
      final favorites = await repository.getFavorites();

      expect(favorites, hasLength(2));
      expect(favorites[0].name, 'Kota 1');
      expect(favorites[1].name, 'Kota 2');
      expect(favorites[0], equals(a));
    });

    test('riwayat unik, terbaru di atas, dan maksimal 10', () async {
      for (var i = 0; i < 11; i++) {
        await repository.addHistory(_location(i));
      }

      final history = await repository.getHistory();
      expect(history, hasLength(10));
      expect(history.first.name, 'Kota 10');
      expect(history.last.name, 'Kota 1');

      // Menambahkan kota yang sudah ada memindahkannya ke atas,
      // bukan membuat duplikat.
      await repository.addHistory(_location(5));
      final reordered = await repository.getHistory();
      expect(reordered, hasLength(10));
      expect(reordered.first.name, 'Kota 5');
      expect(
        reordered.where((location) => location.name == 'Kota 5'),
        hasLength(1),
      );
    });

    test('menyimpan dan membaca lokasi terakhir', () async {
      final location = _location(3);

      await repository.saveLastLocation(location);
      final restored = await repository.getLastLocation();

      expect(restored, isNotNull);
      expect(restored, equals(location));
      expect(restored!.displayName, location.displayName);
    });
  });

  group('SearchViewModel', () {
    test('reset membatalkan pencarian dan mengembalikan state awal', () async {
      final viewModel = SearchViewModel(repository);

      viewModel.onQueryChanged('Purwokerto');
      expect(viewModel.query, 'Purwokerto');
      expect(viewModel.state, ViewState.loading);

      viewModel.reset();

      expect(viewModel.query, isEmpty);
      expect(viewModel.results, isEmpty);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.state, ViewState.initial);

      viewModel.dispose();
    });

    testWidgets(
      'membuka Search Screen menampilkan riwayat, bukan query lama',
      (tester) async {
        await repository.addHistory(_location(0));
        final searchViewModel = SearchViewModel(repository);
        final favoritesViewModel = FavoritesViewModel(repository);
        await searchViewModel.loadHistory();

        // Simulasikan query yang tertinggal dari sesi sebelumnya.
        searchViewModel.onQueryChanged('Purwokerto');
        expect(searchViewModel.query, 'Purwokerto');

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<SearchViewModel>.value(
                  value: searchViewModel,
                ),
                ChangeNotifierProvider<FavoritesViewModel>.value(
                  value: favoritesViewModel,
                ),
              ],
              child: const SearchScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(searchViewModel.query, isEmpty);
        expect(find.text('Riwayat pencarian'), findsOneWidget);
        expect(find.text('Kota 0'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        searchViewModel.dispose();
        favoritesViewModel.dispose();
      },
    );
  });
}
