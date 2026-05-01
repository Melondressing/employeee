import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8E5E0),
            Color(0xFFD4E4F7),
            Color(0xFFE6DDF5),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 72,
            left: 28,
            child: IgnorePointer(
              child: _blob(220, const Color(0x66F8C7B4)),
            ),
          ),
          Positioned(
            bottom: 54,
            right: 26,
            child: IgnorePointer(
              child: _blob(200, const Color(0x66A8DADC)),
            ),
          ),
          Positioned(
            top: 210,
            right: -24,
            child: IgnorePointer(
              child: _blob(160, const Color(0x55B4A7D6)),
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
