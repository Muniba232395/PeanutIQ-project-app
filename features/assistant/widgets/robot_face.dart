import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Port of the website's RobotFace SVG (viewBox 100x100).
class RobotFace extends StatelessWidget {
  const RobotFace({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _RobotFacePainter());
}

class _RobotFacePainter extends CustomPainter {
  const _RobotFacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(const Offset(50, 50), 45, ring);
    canvas.drawCircle(const Offset(50, 50), 35, ring);
    final gold = Paint()..color = AppColors.gold;
    canvas.drawLine(
      const Offset(50, 20),
      const Offset(50, 12),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(50, 10), 3, gold);
    final head = Rect.fromCircle(center: const Offset(50, 55), radius: 30);
    canvas.drawCircle(
      const Offset(50, 55),
      30,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4), // fx/fy 30%
          radius: 1,
          colors: [Color(0xFFF9FAFB), Color(0xFFE5E7EB)],
        ).createShader(head),
    );
    final forest = Paint()..color = AppColors.forest;
    for (final r in const [
      Rect.fromLTWH(38, 45, 4, 12),
      Rect.fromLTWH(58, 45, 4, 12),
      Rect.fromLTWH(42, 68, 16, 4),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), forest);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
