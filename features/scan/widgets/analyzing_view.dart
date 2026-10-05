import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../scan_kind.dart';

/// The website's scanning animation: tinted photo, corner brackets, pulsing capsules,
/// and a gold scan line sweeping between 5% and 95% of the height every 3s.
class AnalyzingView extends ConsumerStatefulWidget {
  const AnalyzingView({super.key, required this.kind, required this.imagePath});

  final ScanKind kind;
  final String? imagePath;

  @override
  ConsumerState<AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends ConsumerState<AnalyzingView> with TickerProviderStateMixin {
  late final AnimationController _scan =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

  @override
  void dispose() {
    _scan.dispose();
    _pulse.dispose();
    super.dispose();
  }

  static const _dots = [
    (x: 0.30, y: 0.30, alpha: 0.8, delay: 0.0),
    (x: 0.60, y: 0.40, alpha: 0.6, delay: 0.1),
    (x: 0.45, y: 0.60, alpha: 0.9, delay: 0.3),
    (x: 0.75, y: 0.50, alpha: 0.7, delay: 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final seed = widget.kind == ScanKind.seed;
    final path = widget.imagePath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.earth, width: 2),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 224,
              child: LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth;
                const h = 224.0;
                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: AppColors.forest.withValues(alpha: 0.9))),
                    if (path != null)
                      Positioned.fill(
                        child: Opacity(opacity: 0.5, child: Image.file(File(path), fit: BoxFit.cover)),
                      ),
                    // Corner brackets, 24px in from each corner.
                    for (final (dx, dy) in const [(false, false), (true, false), (false, true), (true, true)])
                      Positioned(
                        left: dx ? null : 24,
                        right: dx ? 24 : null,
                        top: dy ? null : 24,
                        bottom: dy ? 24 : null,
                        child: Transform.flip(
                          flipX: dx,
                          flipY: dy,
                          child: const CustomPaint(size: Size.square(48), painter: _BracketPainter()),
                        ),
                      ),
                    for (final d in _dots)
                      Positioned(
                        left: w * d.x,
                        top: h * d.y,
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 1, end: 0.5).animate(
                            CurvedAnimation(parent: _pulse, curve: Interval(d.delay, 1, curve: Curves.easeInOut)),
                          ),
                          child: Container(
                            width: 12,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: d.alpha),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _scan,
                      builder: (context, _) {
                        // keyframes: 0% top 5%, 50% top 95%, 100% top 5%
                        final v = _scan.value;
                        final phase = Curves.easeInOut.transform(v < 0.5 ? v * 2 : 2 - v * 2);
                        final top = h * (0.05 + 0.9 * phase);
                        return Positioned(left: 0, right: 0, top: top - 64, child: const _ScanLine());
                      },
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Text(t.t(seed ? 'seed.analyzing' : 'disease.scanning'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
          const SizedBox(height: 4),
          Text(t.t(seed ? 'seed.analyzingDesc' : 'disease.scanningDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.charcoal.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    final glow = AppColors.gold.withValues(alpha: 0.3);
    return Column(
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [glow, glow.withValues(alpha: 0)],
            ),
          ),
        ),
        Container(
          height: 2,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            boxShadow: [BoxShadow(color: AppColors.gold, blurRadius: 20)],
          ),
        ),
        Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [glow, glow.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Top-left bracket: 4px white/80 stroke with a 16px rounded corner.
class _BracketPainter extends CustomPainter {
  const _BracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final path = Path()
      ..moveTo(2, size.height)
      ..lineTo(2, 18)
      ..arcToPoint(const Offset(18, 2), radius: const Radius.circular(16))
      ..lineTo(size.width, 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
