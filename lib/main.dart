import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/location_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/services/geocoding_api_service.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/weather_api_service.dart';
import 'viewmodels/favorites_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);

  runApp(
    MultiProvider(
      providers: [
        // Service & storage
        Provider<LocalStorageService>.value(value: storage),
        Provider<WeatherApiService>(create: (_) => WeatherApiService()),
        Provider<GeocodingApiService>(create: (_) => GeocodingApiService()),

        // Repository sebagai perantara service dan ViewModel
        Provider<WeatherRepository>(
          create: (context) => WeatherRepository(
            context.read<WeatherApiService>(),
          ),
        ),
        Provider<LocationRepository>(
          create: (context) => LocationRepository(
            context.read<GeocodingApiService>(),
            context.read<LocalStorageService>(),
          ),
        ),

        // ViewModel
        ChangeNotifierProvider<WeatherViewModel>(
          create: (context) => WeatherViewModel(
            context.read<WeatherRepository>(),
            context.read<LocationRepository>(),
          )..init(),
        ),
        ChangeNotifierProvider<SearchViewModel>(
          create: (context) => SearchViewModel(
            context.read<LocationRepository>(),
          )..loadHistory(),
        ),
        ChangeNotifierProvider<FavoritesViewModel>(
          create: (context) => FavoritesViewModel(
            context.read<LocationRepository>(),
          )..load(),
        ),
      ],
      child: const WeatherApp(),
    ),
  );
}
