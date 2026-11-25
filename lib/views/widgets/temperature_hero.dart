import 'package:flutter/material.dart';

/// Angka suhu besar dengan simbol derajat kecil di kanan atas.
class TemperatureHero extends StatelessWidget {
  final double temperature;

  const TemperatureHero({super.key, required this.temperature});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${temperature.round()}', style: textTheme.displayLarge),
          Padding(
            padding: const EdgeInsets.only(top: 14, left: 4),
            child: Text(
              '°',
              style: textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
