import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/weather_code_mapper.dart';
import '../../data/models/daily_forecast.dart';
import 'glass_card.dart';
import 'temperature_line_chart.dart';

/// Kartu prakiraan multi-hari dengan mode grafik garis dan daftar.
class DailyForecastCard extends StatelessWidget {
  static const double _itemWidth = 84;

  final List<DailyForecast> days;
  final bool showLineChart;
  final ValueChanged<bool> onModeChanged;

  const DailyForecastCard({
    super.key,
    required this.days,
    required this.showLineChart,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prakiraan multi-hari',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
              _ModeToggle(
                showLineChart: showLineChart,
                onChanged: onModeChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (days.isEmpty)
            Text(
              'Prakiraan beberapa hari belum tersedia.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          else if (showLineChart)
            _LineMode(days: days, itemWidth: _itemWidth)
          else
            _ListMode(days: days),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showDetails(context),
              child: const Text('Lihat detail'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.78;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Prakiraan 7 hari',
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: days.length,
                    separatorBuilder: (_, _) => Divider(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final condition = WeatherCodeMapper.label(
                        day.weatherCode,
                      );
                      final rain = day.precipitationProbabilityMax;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          WeatherCodeMapper.icon(day.weatherCode),
                          size: 26,
                        ),
                        title: Text(
                          DateFormat(
                            'EEEE, d MMMM',
                            'id_ID',
                          ).format(day.date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$condition · ${day.temperatureMax.round()}° / '
                            '${day.temperatureMin.round()}° · '
                            'Hujan ${rain == null ? '-' : '$rain%'}\n'
                            'Terbit ${_formatTime(day.sunrise)} · '
                            'Terbenam ${_formatTime(day.sunset)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    return DateFormat('HH.mm').format(time);
  }
}

class _ModeToggle extends StatelessWidget {
  final bool showLineChart;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.showLineChart,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Garis',
            selected: showLineChart,
            onTap: () => onChanged(true),
          ),
          _ModeButton(
            label: 'Daftar',
            selected: !showLineChart,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LineMode extends StatelessWidget {
  final List<DailyForecast> days;
  final double itemWidth;

  const _LineMode({required this.days, required this.itemWidth});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: days.length * itemWidth,
        child: Column(
          children: [
            Row(
              children: days.asMap().entries.map((entry) {
                return SizedBox(
                  width: itemWidth,
                  child: _DayHeader(day: entry.value, index: entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 2),
            Row(
              children: days.map((day) {
                return SizedBox(
                  width: itemWidth,
                  child: Center(
                    child: Text(
                      '${day.temperatureMax.round()}°',
                      style: textTheme.titleLarge,
                    ),
                  ),
                );
              }).toList(),
            ),
            TemperatureLineChart(days: days, itemWidth: itemWidth),
            Row(
              children: days.map((day) {
                return SizedBox(
                  width: itemWidth,
                  child: Center(
                    child: Text(
                      '${day.temperatureMin.round()}°',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DailyForecast day;
  final int index;

  const _DayHeader({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dayLabel = index == 0
        ? 'Hari ini'
        : index == 1
        ? 'Besok'
        : DateFormat('E', 'id_ID').format(day.date);
    final dateLabel = DateFormat('d MMM', 'id_ID').format(day.date);
    final condition = WeatherCodeMapper.label(day.weatherCode);
    final rain = day.precipitationProbabilityMax;

    return SizedBox(
      height: 106,
      child: Column(
        children: [
          Text(
            dayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: Text(
              condition,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(height: 1.1),
            ),
          ),
          Icon(
            WeatherCodeMapper.icon(day.weatherCode),
            size: 22,
            color: Colors.white,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 11,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                rain == null ? '-' : '$rain%',
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListMode extends StatelessWidget {
  final List<DailyForecast> days;

  const _ListMode({required this.days});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: days.asMap().entries.map((entry) {
        final day = entry.value;
        final index = entry.key;
        return Column(
          children: [
            if (index > 0)
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _DayRow(day: day, index: index),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyForecast day;
  final int index;

  const _DayRow({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dayLabel = index == 0
        ? 'Hari ini'
        : index == 1
        ? 'Besok'
        : DateFormat('E', 'id_ID').format(day.date);
    final dateLabel = DateFormat('d MMM', 'id_ID').format(day.date);
    final condition = WeatherCodeMapper.label(day.weatherCode);
    final rain = day.precipitationProbabilityMax;

    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayLabel, style: textTheme.titleMedium),
              Text(
                dateLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          WeatherCodeMapper.icon(day.weatherCode),
          size: 22,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                condition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 11,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rain == null ? '-' : '$rain%',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${day.temperatureMax.round()}°',
              style: textTheme.titleMedium,
            ),
            Text(
              '${day.temperatureMin.round()}°',
              style: textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
