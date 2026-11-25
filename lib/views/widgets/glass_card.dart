import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Kartu transparan dengan sudut membulat, dipakai di seluruh layar.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.cardRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.glassColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: child,
    );
  }
}

/// Tombol ikon bulat semi-transparan untuk header dan app bar.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppTheme.glassColor,
          shape: CircleBorder(
            side: BorderSide(color: AppTheme.glassBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 23),
            ),
          ),
        ),
      ),
    );
  }
}
