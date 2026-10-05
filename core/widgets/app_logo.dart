import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// Port of the website's Logo: a bean with a small leaf at its top-end corner.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.iconColor = AppColors.forest,
    this.leafColor = AppColors.gold,
  });

  final double size;
  final Color iconColor;
  final Color leafColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(LucideIcons.bean, size: size, color: iconColor),
          Positioned(
            top: -size * 0.1,
            right: -size * 0.1,
            child: Transform.rotate(
              angle: -0.21,
              child: Icon(LucideIcons.leaf, size: size * 0.55, color: leafColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// "PeanutIQ" in serif, always left-to-right.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.fontSize = 22,
    this.color = AppColors.darkText,
    this.accent = AppColors.forest,
  });

  final double fontSize;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(text: 'Peanut', children: [
        TextSpan(text: 'IQ', style: TextStyle(color: accent)),
      ]),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}
