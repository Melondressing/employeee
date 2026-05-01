import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppPage extends StatefulWidget {
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
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final _primaryScrollController = ScrollController();

  @override
  void dispose() {
    _primaryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _primaryScrollController,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerSignal: _handlePointerSignal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget content = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: SizedBox(
                width: double.infinity,
                height: widget.fillHeight && constraints.hasBoundedHeight
                    ? math.max(
                        0, constraints.maxHeight - widget.padding.vertical)
                    : null,
                child: widget.child,
              ),
            );

            content = Padding(padding: widget.padding, child: content);

            return Align(
              alignment: Alignment.topCenter,
              child: content,
            );
          },
        ),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (!_primaryScrollController.hasClients) return;

      final position = _primaryScrollController.position;
      final target = (position.pixels + event.scrollDelta.dy).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if (target != position.pixels) {
        position.jumpTo(target.toDouble());
      }
    });
  }
}
