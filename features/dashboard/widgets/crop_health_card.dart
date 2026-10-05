import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../dashboard_providers.dart';

/// The website's crop health donut (conic gradient) with legend. The donut uses
/// #22c55e/#eab308/#ef4444 while the legend dots use forest/yellow-400/red-500 — copied as-is.
class CropHealthCard extends ConsumerWidget {
  const CropHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final async = ref.watch(cropProfileProvider);
    final profile = async.value;
    final good = profile?.goodPct ?? 0;
    final average = profile?.averagePct ?? 0;
    final poor = profile?.poorPct ?? 0;
    final total = good + average + poor;

    PieChartSectionData section(int value, Color color) =>
        PieChartSectionData(value: value.toDouble(), color: color, radius: 12, showTitle: false);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(icon: LucideIcons.wheat, title: t.t('dashboard.cropHealthTitle')),
          const SizedBox(height: 24),
          if (async.hasError)
            SectionError(onRetry: () => ref.invalidate(cropProfileProvider))
          else
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 16,
                children: [
                  SizedBox.square(
                    dimension: 144,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 0,
                          centerSpaceRadius: 60,
                          sections: total == 0
                              ? [section(1, AppColors.earth)]
                              : [
                                  if (good > 0) section(good, AppColors.healthGood),
                                  if (average > 0) section(average, AppColors.healthAverage),
                                  if (poor > 0) section(poor, AppColors.healthPoor),
                                ],
                        )),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$good%',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 28, height: 1, fontWeight: FontWeight.w900, color: AppColors.charcoal)),
                            const SizedBox(height: 4),
                            Text(t.t('dashboard.good').toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                    letterSpacing: 1.2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend(color: AppColors.forest, label: t.t('dashboard.good'), pct: good),
                        const SizedBox(height: 14),
                        _Legend(color: AppColors.yellow400, label: t.t('dashboard.average'), pct: average),
                        const SizedBox(height: 14),
                        _Legend(color: AppColors.red500, label: t.t('dashboard.poor'), pct: poor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ArrowLink(label: t.t('dashboard.viewFullReport'), onTap: () => context.go(Routes.history)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.pct});

  final Color color;
  final String label;
  final int pct;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.charcoal);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(label, style: style),
        const SizedBox(width: 16),
        Opacity(opacity: 0.7, child: Text('$pct%', textDirection: TextDirection.ltr, style: style)),
      ],
    );
  }
}
