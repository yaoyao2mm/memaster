import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AppShellBackground extends StatelessWidget {
  const AppShellBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FBFF),
            Color(0xFFF3F5FA),
            Color(0xFFEEF2F8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(
              size: 360,
              colors: const [AppColors.softBlue, Color(0x00FFFFFF)],
            ),
          ),
          Positioned(
            top: 60,
            right: -90,
            child: _GlowOrb(
              size: 280,
              colors: const [AppColors.aqua, Color(0x00FFFFFF)],
            ),
          ),
          Positioned(
            bottom: -140,
            left: 80,
            child: _GlowOrb(
              size: 320,
              colors: const [AppColors.rose, Color(0x00FFFFFF)],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

