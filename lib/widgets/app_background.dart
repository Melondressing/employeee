import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.15,
          colors: [Color(0xFF0C0704), Color(0xFF1A120C)],
          stops: [0.08, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 72,
            left: 28,
            child: IgnorePointer(
              child: _blob(220, const Color(0x20F6B36C)),
            ),
          ),
          Positioned(
            bottom: 54,
            right: 26,
            child: IgnorePointer(
              child: _blob(200, const Color(0x20E5A545)),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.82),
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}
