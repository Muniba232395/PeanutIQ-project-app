import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'robot_face.dart';

/// The panel's big robot: floating, with rotating technical rings; tap to record.
/// While recording it glows gold, grows a little and sends out ping rings.
class RobotHero extends StatefulWidget {
  const RobotHero({super.key, required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  State<RobotHero> createState() => _RobotHeroState();
}

class _RobotHeroState extends State<RobotHero> with TickerProviderStateMixin {
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  late final AnimationController _ping =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    _float.dispose();
    _spin.dispose();
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    return GestureDetector(
      key: const Key('assistantRobotHero'),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _spin, _ping]),
        builder: (context, _) => Transform.translate(
          offset: Offset(0, -8 * Curves.easeInOut.transform(_float.value)),
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // spin 10s (64px dashed), reverse spin 15s (128px gold arcs)
                Transform.rotate(
                  angle: 2 * math.pi * (_spin.value * 3),
                  child: const CustomPaint(size: Size.square(64), painter: _DashedRing(Color(0x1AFFFFFF))),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                Transform.rotate(
                  angle: -2 * math.pi * (_spin.value * 2),
                  child: const CustomPaint(size: Size.square(128), painter: _GoldArcs()),
                ),
                Transform.scale(
                  scale: recording ? 1.1 : 1,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: recording ? AppColors.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: recording ? AppColors.gold.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        recording
                            ? BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 40)
                            : const BoxShadow(color: Color(0x4D000000), blurRadius: 30),
                      ],
                    ),
                    child: const RobotFace(size: 28),
                  ),
                ),
                if (recording)
                  for (final delay in const [0.0, 0.33])
                    Builder(builder: (context) {
                      final v = (_ping.value + delay) % 1;
                      return Opacity(
                        opacity: (1 - v) * 0.75,
                        child: Transform.scale(
                          scale: 1 + v,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 2),
                            ),
                          ),
                        ),
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    const dashes = 24;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, 2 * math.pi * i / dashes, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// border-t border-b in gold/30: two arcs at the top and bottom.
class _GoldArcs extends CustomPainter {
  const _GoldArcs();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    canvas.drawArc(rect, -math.pi * 3 / 4, math.pi / 2, false, paint);
    canvas.drawArc(rect, math.pi / 4, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
