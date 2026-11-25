import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/aqi_helper.dart';
import '../../data/models/air_quality.dart';
import 'glass_card.dart';

/// Kartu kualitas udara dengan bar gradien dan penanda nilai.
class AirQualityCard extends StatelessWidget {
  final AirQuality airQuality;

  const AirQualityCard({super.key, required this.airQuality});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = airQuality.usAqi == null
        ? 'Tidak tersedia'
        : '${airQuality.category} ${airQuality.usAqi}';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kualitas udara',
                  style: textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            airQuality.description,
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          if (airQuality.usAqi != null) ...[
            const SizedBox(height: 14),
            _AqiBar(aqi: airQuality.usAqi!),
          ],
        ],
      ),
    );
  }
}

class _AqiBar extends StatelessWidget {
  final int aqi;

  const _AqiBar({required this.aqi});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerX =
              (constraints.maxWidth - 12) * AqiHelper.position(aqi);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 5,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      colors: AqiHelper.barColors,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerX,
                top: 0,
                child: Container(
                  width: 12,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
