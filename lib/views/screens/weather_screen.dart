import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/weather_gradients.dart';
import '../../core/utils/weather_code_mapper.dart';
import '../../data/models/current_weather.dart';
import '../../data/models/daily_forecast.dart';
import '../../data/models/weather_data.dart';
import '../../viewmodels/view_state.dart';
import '../../viewmodels/weather_viewmodel.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/detail_tile.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hourly_forecast_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/temperature_hero.dart';
import 'search_screen.dart';

/// Layar utama cuaca. Satu halaman scroll dengan background gradien.
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherViewModel>(
      builder: (context, viewModel, _) {
        final weather = viewModel.weather;
        final colors = weather == null
            ? WeatherGradients.forCode(0, isDay: true)
            : WeatherGradients.forCode(
                weather.current.weatherCode,
                isDay: weather.current.isDay,
              );

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
            tooltip: 'Cari kota',
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(Icons.playlist_add_rounded),
          ),
          body: GradientBackground(
            colors: colors,
            child: SafeArea(
              bottom: false,
              child: SizedBox.expand(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(context, viewModel, weather),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    WeatherViewModel viewModel,
    WeatherData? weather,
  ) {
    if (weather == null) {
      switch (viewModel.state) {
        case ViewState.initial:
        case ViewState.loading:
          return const LoadingView(key: ValueKey('loading'));
        case ViewState.error:
          return ErrorView(
            key: const ValueKey('error'),
            message:
                viewModel.errorMessage ??
                'Gagal memuat data cuaca. Silakan coba lagi.',
            onRetry: viewModel.retry,
          );
        case ViewState.empty:
          return EmptyView(
            key: const ValueKey('empty'),
            icon: Icons.cloud_off_rounded,
            message: 'Data cuaca untuk lokasi ini belum tersedia.',
            actionLabel: 'Muat ulang',
            onAction: viewModel.retry,
          );
        case ViewState.success:
          return EmptyView(
            key: const ValueKey('success-empty'),
            icon: Icons.cloud_off_rounded,
            message: 'Data cuaca tidak ditemukan.',
            actionLabel: 'Muat ulang',
            onAction: viewModel.retry,
          );
      }
    }

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: viewModel.refresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF2D7DD2),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SizedBox(
                width: double.infinity,
                child: _WeatherContent(
                  viewModel: viewModel,
                  weather: weather,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  final WeatherViewModel viewModel;
  final WeatherData weather;

  const _WeatherContent({required this.viewModel, required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final condition = WeatherCodeMapper.label(current.weatherCode);
    final airQuality = viewModel.airQuality;
    final minTemperature = viewModel.todayMin;
    final maxTemperature = viewModel.todayMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          locationName: weather.location.name,
          fullLocationName: weather.location.displayName,
          onSettings: () => _showSettings(context, viewModel),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: Center(
            child: TemperatureHero(temperature: current.temperature),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: [
            Text(
              '$condition  '
              '${minTemperature == null ? '-' : '${minTemperature.round()}°'} / '
              '${maxTemperature == null ? '-' : '${maxTemperature.round()}°'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (airQuality?.usAqi != null)
              Text(
                'Kualitas udara: ${airQuality!.usAqi} – ${airQuality.category}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        HourlyForecastCard(items: viewModel.hourlyItems),
        const SizedBox(height: 12),
        DailyForecastCard(
          days: weather.daily,
          showLineChart: viewModel.showLineChart,
          onModeChanged: viewModel.toggleChartMode,
        ),
        if (airQuality != null) ...[
          const SizedBox(height: 12),
          AirQualityCard(airQuality: airQuality),
        ],
        const SizedBox(height: 12),
        _DetailGrid(current: current, today: viewModel.today),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showSettings(BuildContext context, WeatherViewModel viewModel) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengaturan',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.location?.displayName ?? 'Lokasi tidak diketahui',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Segarkan data'),
                  subtitle: const Text('Muat ulang data cuaca dari Open-Meteo'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    viewModel.refresh();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Tentang aplikasi'),
                  subtitle: const Text('Aplikasi cuaca Responsi Flutter'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showAboutDialog(
                      context: context,
                      applicationName: 'Cuaca',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Data cuaca dan pencarian kota: Open-Meteo',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String locationName;
  final String fullLocationName;
  final VoidCallback onSettings;

  const _Header({
    required this.locationName,
    required this.fullLocationName,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: fullLocationName,
            child: Text(
              locationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GlassIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Pengaturan',
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final CurrentWeather current;
  final DailyForecast? today;

  const _DetailGrid({required this.current, required this.today});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      DetailTile(
        icon: Icons.wb_sunny_outlined,
        label: 'UV',
        value: current.uvIndex == null
            ? '-'
            : '${current.uvIndex!.round()}',
        unit: _uvLabel(current.uvIndex),
      ),
      DetailTile(
        icon: Icons.thermostat_rounded,
        label: 'Terasa seperti',
        value: '${current.apparentTemperature.round()}°',
      ),
      DetailTile(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.relativeHumidity}',
        unit: '%',
      ),
      DetailTile(
        icon: Icons.air_rounded,
        label: 'Angin',
        value: '${current.windSpeed.round()}',
        unit: 'km/h',
      ),
      DetailTile(
        icon: Icons.speed_rounded,
        label: 'Tekanan udara',
        value: '${current.surfacePressure.round()}',
        unit: 'hPa',
      ),
      DetailTile(
        icon: Icons.visibility_outlined,
        label: 'Jarak pandang',
        value: current.visibility == null
            ? '-'
            : (current.visibility! / 1000).toStringAsFixed(1),
        unit: 'km',
      ),
      DetailTile(
        icon: Icons.umbrella_outlined,
        label: 'Peluang hujan',
        value: today?.precipitationProbabilityMax?.toString() ?? '-',
        unit: '%',
      ),
      DetailTile(
        icon: Icons.grain_rounded,
        label: 'Curah hujan',
        value: current.precipitation.toStringAsFixed(1),
        unit: 'mm',
      ),
      DetailTile(
        icon: Icons.wb_twilight,
        label: 'Matahari',
        value:
            '${_formatTime(today?.sunrise)} / ${_formatTime(today?.sunset)}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tiles
              .map(
                (tile) => SizedBox(width: tileWidth, child: tile),
              )
              .toList(),
        );
      },
    );
  }

  String _uvLabel(double? uv) {
    if (uv == null) return '-';
    if (uv <= 2) return 'Sangat lemah';
    if (uv <= 5) return 'Lemah';
    if (uv <= 7) return 'Sedang';
    if (uv <= 10) return 'Kuat';
    return 'Ekstrem';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    return DateFormat('HH.mm').format(time);
  }
}
