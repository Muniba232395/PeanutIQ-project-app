import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../data/scan_analysis_repository.dart';
import 'result_card.dart';

/// Port of SeedIntelligence's "complete" view, filled with the AI's analysis of the photo.
class SeedResults extends ConsumerWidget {
  const SeedResults({super.key, required this.imagePath, required this.analysis});

  final String? imagePath;
  final SeedAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final muted = AppColors.charcoal.withValues(alpha: 0.7);
    final a = analysis;
    Widget stat({required Widget figure, required String titleKey, required String description}) => SectionCard(
          child: Column(
            children: [
              SizedBox(height: 80, child: Center(child: figure)),
              const SizedBox(height: 16),
              Text(t.t(titleKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
              const SizedBox(height: 4),
              Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: muted)),
            ],
          ),
        );
    const big = TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.charcoal, height: 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stat(
          figure: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.sand, shape: BoxShape.circle, border: Border.all(color: AppColors.forest)),
            child: Text(a.grade,
                key: const Key('seedGrade'),
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: a.goodLot ? AppColors.forest : AppColors.red500)),
          ),
          titleKey: 'seed.overallGrade',
          description: a.summary,
        ),
        const SizedBox(height: 24),
        stat(
          figure: Text.rich(
            TextSpan(text: '${a.germinationPct}', children: [
              TextSpan(
                  text: '%',
                  style: TextStyle(fontSize: 24, color: AppColors.charcoal.withValues(alpha: 0.4))),
            ]),
            textDirection: TextDirection.ltr,
            style: big,
          ),
          titleKey: 'seed.germination',
          description: t.t('seed.germinationDesc'),
        ),
        const SizedBox(height: 24),
        stat(
          figure: Text('${a.totalSeeds}', key: const Key('seedTotal'), style: big),
          titleKey: 'seed.totalAnalyzed',
          description: t.t('seed.app.totalDesc'),
        ),
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('seed.batchImage'),
          child: _ScanImage(
            path: imagePath,
            overlay: Container(
              decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.forest.withValues(alpha: 0.3), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('seed.uniformity'),
          padding: const EdgeInsets.all(20),
          gap: 16,
          child: Column(
            children: [
              _Bar(
                  label: t.t('seed.app.sizeUniformity'),
                  value: '${a.sizeUniformityPct}%',
                  fraction: a.sizeUniformityPct / 100),
              const SizedBox(height: 16),
              _Bar(
                  label: t.t('seed.colorCon'),
                  value: '${a.colorConsistencyPct}%',
                  fraction: a.colorConsistencyPct / 100),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('seed.breakdown'),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      // Recharts draws counter-clockwise from 3 o'clock; fl_chart draws clockwise,
                      // so start at 3 o'clock with the slices reversed to get the same picture.
                      startDegreeOffset: 0,
                      centerSpaceRadius: 60,
                      sectionsSpace: 6, // recharts paddingAngle 5
                      sections: [
                        for (final item in a.breakdown.reversed)
                          if (item.value > 0)
                          PieChartSectionData(value: item.value.toDouble(), color: item.color, radius: 20, showTitle: false),
                      ],
                    )),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${a.healthyPct}%',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontSize: 28, height: 1, fontWeight: FontWeight.w900, color: AppColors.charcoal)),
                        const SizedBox(height: 4),
                        Text(t.t('seed.data.healthy').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest, letterSpacing: 1.2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (final item in a.breakdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                          width: 12, height: 12, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(t.t(item.key),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted)),
                      ),
                      Text('${item.value}%',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('seed.actions'),
          icon: LucideIcons.bean,
          gap: 16,
          child: Column(
            children: [
              for (final (i, step) in a.actions.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                // The first step carries the verdict: green for a good lot, red otherwise.
                i == 0
                    ? _ActionRow(
                        icon: a.goodLot ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
                        iconColor: a.goodLot ? AppColors.forest : AppColors.red500,
                        background: a.goodLot ? AppColors.green50 : AppColors.red50,
                        border: a.goodLot ? AppColors.green200 : AppColors.red500,
                        title: step.title,
                        body: step.detail,
                      )
                    : _ActionRow(
                        icon: LucideIcons.lightbulb,
                        iconColor: AppColors.charcoal,
                        background: AppColors.sand,
                        border: AppColors.gray200,
                        title: step.title,
                        body: step.detail,
                      ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AiNote(text: t.t('seed.app.aiNote')),
      ],
    );
  }
}

/// The photo in a 256px sand frame with a 2px earth border, plus an overlay.
class _ScanImage extends StatelessWidget {
  const _ScanImage({required this.path, required this.overlay});

  final String? path;
  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 256,
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.earth, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (path != null) Image.file(File(path!), fit: BoxFit.cover),
          overlay,
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.fraction});

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label, style: TextStyle(fontSize: 14, color: AppColors.charcoal.withValues(alpha: 0.7)))),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.sand,
            border: Border.all(color: AppColors.earth),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.border,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color border;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 20, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' $body'),
              ]),
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared by the disease view.
class ScanImageFrame extends StatelessWidget {
  const ScanImageFrame({super.key, required this.path, this.overlay = const SizedBox.shrink()});

  final String? path;
  final Widget overlay;

  @override
  Widget build(BuildContext context) => _ScanImage(path: path, overlay: overlay);
}

/// The small "this is an AI estimate" line under results.
class AiNote extends StatelessWidget {
  const AiNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 14, color: AppColors.charcoal.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                key: const Key('aiNote'),
                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.charcoal.withValues(alpha: 0.6))),
          ),
        ],
      );
}
