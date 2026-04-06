import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.child,
    this.onTap,
  });

  final EdgeInsets padding;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.cardSurfaceStrong, AppColors.cardSurface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            border: Border.all(color: AppColors.glassStroke, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    return onTap == null
        ? card
        : InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: card,
          );
  }
}
