import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;   // kept for API compat, unused
  final double radius;
  final VoidCallback? onTap;
  final bool noPadding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10,
    this.radius = 6,
    this.onTap,
    this.noPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = noPadding
        ? child
        : Padding(
            padding: padding ?? const EdgeInsets.all(14),
            child: child,
          );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.bgInverse.withOpacity(0.04),
          highlightColor: AppColors.bgInverse.withOpacity(0.02),
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Sfondo principale dell'app — bianco piatto, nessun glow.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: child,
    );
  }
}
