import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double radius;
  final VoidCallback? onTap;
  final bool noPadding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10,
    this.radius = 16,
    this.onTap,
    this.noPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = noPadding
        ? child
        : Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.03),
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Background scuro con glow radiali sottili — rende visibile l'effetto glass.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned(
            top: -120, left: -80,
            child: _Glow(size: 380, opacity: 0.06),
          ),
          Positioned(
            bottom: -80, right: -60,
            child: _Glow(size: 300, opacity: 0.04),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final double opacity;
  const _Glow({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}
