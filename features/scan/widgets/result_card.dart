import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';

/// flat-card with the website's small uppercase section title (text-sm font-bold uppercase tracking-wider).
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.titleColor = AppColors.forest,
    this.padding = const EdgeInsets.all(24),
    this.gap = 24,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color titleColor;
  final EdgeInsetsGeometry padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: titleColor), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          child,
        ],
      ),
    );
  }
}
