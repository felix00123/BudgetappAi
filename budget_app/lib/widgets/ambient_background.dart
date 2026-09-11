import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Paints soft colour washes behind the app so translucent surfaces have
/// something to pick up, and flat screens gain a sense of depth.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.surface)),
        const Positioned(
          top: -140,
          left: -90,
          child: _Wash(color: AppColors.ambientOne, size: 340, strength: 0.30),
        ),
        const Positioned(
          top: 90,
          right: -120,
          child: _Wash(color: AppColors.ambientTwo, size: 300, strength: 0.18),
        ),
        const Positioned(
          bottom: -150,
          left: -70,
          child: _Wash(color: AppColors.ambientThree, size: 320, strength: 0.16),
        ),
        child,
      ],
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({
    required this.color,
    required this.size,
    required this.strength,
  });

  final Color color;
  final double size;
  final double strength;

  @override
  Widget build(BuildContext context) {
    // A radial gradient fades out on its own, so no blur filter is needed.
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: strength),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
