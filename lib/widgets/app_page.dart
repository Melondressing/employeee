import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.maxWidth = defaultMaxWidth,
    this.padding = const EdgeInsets.all(16),
    this.fillHeight = false,
  });

  static const defaultMaxWidth = 520.0;
  static const compactMaxWidth = 430.0;
  static const loginMaxWidth = 460.0;

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            width: double.infinity,
            height: fillHeight && constraints.hasBoundedHeight
                ? math.max(0, constraints.maxHeight - padding.vertical)
                : null,
            child: child,
          ),
        );

        content = Padding(padding: padding, child: content);

        return Align(
          alignment: Alignment.topCenter,
          child: content,
        );
      },
    );
  }
}
