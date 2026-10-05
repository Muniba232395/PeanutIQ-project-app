import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// The website's 15-bar gold waveform (animate-wave: scaleY 0.4 ↔ 1 over 1.2s,
/// random heights and phases).
class Waveform extends StatefulWidget {
  const Waveform({super.key, this.animate = true, this.height = 24});

  final bool animate;
  final double height;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  final _random = math.Random(7);
  late final _bars = [
    for (var i = 0; i < 15; i++) (height: math.max(0.3, _random.nextDouble()), phase: _random.nextDouble()),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(Waveform old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final bar in _bars)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Transform.scale(
                  scaleY: widget.animate
                      ? 0.4 + 0.6 * (0.5 - 0.5 * math.cos(2 * math.pi * ((_c.value + bar.phase) % 1)))
                      : 1,
                  child: Container(
                    width: 3,
                    height: widget.height * bar.height,
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
