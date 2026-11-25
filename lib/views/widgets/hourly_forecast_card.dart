import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/weather_code_mapper.dart';
import '../../viewmodels/weather_viewmodel.dart';
import 'glass_card.dart';

/// Kartu jam-per-jam yang bisa digeser horizontal.
class HourlyForecastCard extends StatelessWidget {
  final List<HourlyItem> items;

  const HourlyForecastCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return GlassCard(
        child: Text(
          'Data per jam belum tersedia.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 2),
          itemBuilder: (context, index) {
            final item = items[index];
            return _HourlyItemView(item: item);
          },
        ),
      ),
    );
  }
}

class _HourlyItemView extends StatelessWidget {
  final HourlyItem item;

  const _HourlyItemView({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final timeLabel = item.isNow
        ? 'Sekarang'
        : DateFormat('HH.mm').format(item.time);

    return Semantics(
      label: _semanticLabel(timeLabel),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: item.isNow ? Colors.white : AppTheme.textSecondary,
                fontWeight: item.isNow ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            Icon(_iconFor(item), size: 28, color: Colors.white),
            Text(
              item.temperature == null
                  ? '-'
                  : '${item.temperature!.round()}°',
              style: textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(HourlyItem item) {
    switch (item.type) {
      case HourlyItemType.sunrise:
        return Icons.wb_twilight;
      case HourlyItemType.sunset:
        return Icons.nights_stay;
      case HourlyItemType.weather:
        return WeatherCodeMapper.icon(
          item.weatherCode ?? 0,
          isDay: item.isDay,
        );
    }
  }

  String _semanticLabel(String timeLabel) {
    switch (item.type) {
      case HourlyItemType.sunrise:
        return '$timeLabel, matahari terbit';
      case HourlyItemType.sunset:
        return '$timeLabel, matahari terbenam';
      case HourlyItemType.weather:
        final condition = WeatherCodeMapper.label(item.weatherCode ?? 0);
        final temperature = item.temperature == null
            ? ''
            : ', ${item.temperature!.round()} derajat';
        return '$timeLabel, $condition$temperature';
    }
  }
}
