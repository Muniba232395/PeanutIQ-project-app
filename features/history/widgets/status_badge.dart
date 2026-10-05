import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';

/// History status pill (getStatusColor on the website).
class StatusBadge extends ConsumerWidget {
  const StatusBadge({super.key, required this.status, this.large = false, this.translucent = false});

  final String status;
  final bool large;
  final bool translucent;

  static ({Color text, Color border, Color dot}) colorsFor(String status) => switch (status) {
        'Healthy' => (text: AppColors.forest, border: AppColors.emerald200, dot: AppColors.forest),
        'High Risk' => (text: AppColors.rose700, border: AppColors.rose200, dot: AppColors.rose500),
        'Moderate' => (text: AppColors.amber700, border: AppColors.amber200, dot: AppColors.amber500),
        // The website's class here is a typo (bg-sand0) that draws no dot; slate-400 stands in.
        _ => (text: AppColors.slate700, border: AppColors.slate200, dot: AppColors.slate400),
      };

  /// Same mapping as the website: anything other than Healthy / High Risk reads "Moderate".
  static String labelKey(String status) => switch (status) {
        'Healthy' => 'history.statusHealthy',
        'High Risk' => 'history.statusHighRisk',
        _ => 'history.statusModerate',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final c = colorsFor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: translucent ? Colors.white.withValues(alpha: 0.9) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
        boxShadow: translucent ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
          ),
          SizedBox(width: large ? 8 : 6),
          Flexible(
            child: Text(t.t(labelKey(status)),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w700, color: c.text)),
          ),
        ],
      ),
    );
  }
}
