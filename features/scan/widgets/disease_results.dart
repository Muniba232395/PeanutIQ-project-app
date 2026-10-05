import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../data/scan_analysis_repository.dart';
import 'result_card.dart';
import 'seed_results.dart' show AiNote, ScanImageFrame;

/// Port of DiseaseIntelligence's "complete" view, filled with the AI's analysis of the photo.
class DiseaseResults extends ConsumerWidget {
  const DiseaseResults({super.key, required this.imagePath, required this.analysis});

  final String? imagePath;
  final DiseaseAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final a = analysis;
    final pct = {'pct': a.confidencePct};
    final riskColor = switch (a.outbreakRisk) {
      'high' => AppColors.red500,
      'medium' => AppColors.orange500,
      _ => AppColors.forest,
    };
    final mainColor = a.healthy ? AppColors.forest : AppColors.terracotta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard(
          color: mainColor,
          titleColor: mainColor,
          title: t.t(a.healthy ? 'disease.app.healthyTitle' : 'disease.app.detectedTitle'),
          value: a.condition,
          description: t.t('disease.app.category.${a.category}'),
          figure: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: a.healthy ? AppColors.green50 : AppColors.red50,
              border: Border.all(color: mainColor),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.crosshair, size: 14, color: mainColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(t.t('disease.app.confidence', args: pct),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mainColor)),
                ),
              ],
            ),
          ),
        ),
        if (!a.healthy) ...[
          const SizedBox(height: 24),
          _StatusCard(
            color: AppColors.orange400,
            titleColor: AppColors.orange500,
            title: t.t('disease.severityTitle'),
            value: t.t('disease.app.severity.${a.severityStage}'),
            description: t.t('disease.app.affected', args: {'pct': a.affectedPct}),
            figure: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: i < a.severityStage ? AppColors.orange400 : AppColors.gray200,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _StatusCard(
            color: riskColor,
            titleColor: riskColor,
            title: t.t('disease.riskTitle'),
            value: t.t('disease.app.risk.${a.outbreakRisk}'),
            figure: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.08), shape: BoxShape.circle, border: Border.all(color: riskColor)),
              child: Icon(LucideIcons.triangleAlert, size: 28, color: riskColor),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('disease.analysisTitle'),
          child: ScanImageFrame(path: imagePath),
        ),
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('disease.app.symptomsTitle'),
          icon: LucideIcons.info,
          titleColor: mainColor,
          gap: 16,
          child: Text(a.explanation, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.charcoal)),
        ),
        if (a.urgentAction.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: a.healthy ? AppColors.forest : riskColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: a.healthy ? AppColors.forest : riskColor)),
                  child: Icon(a.healthy ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
                      size: 24, color: a.healthy ? AppColors.forest : riskColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.t('disease.app.nowTitle'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: a.healthy ? AppColors.forest : riskColor)),
                      const SizedBox(height: 4),
                      Text(a.urgentAction, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.charcoal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        ResultCard(
          title: t.t('disease.managementTitle'),
          icon: LucideIcons.shield,
          child: Column(
            children: [
              for (final (i, step) in [
                ...a.treatments,
                if (a.prevention.isNotEmpty) AnalysisStep(t.t('disease.app.preventionTitle'), a.prevention),
              ].indexed) ...[
                if (i > 0) const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sand.withValues(alpha: 0.5),
                    border: Border.all(color: AppColors.earth.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(step.title,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(step.detail,
                          style: TextStyle(
                              fontSize: 14, height: 1.6, color: AppColors.charcoal.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AiNote(text: t.t('disease.app.aiNote')),
      ],
    );
  }
}

/// Coloured-border status card with a 4px top strip (detected / severity / risk).
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.color,
    required this.titleColor,
    required this.title,
    required this.value,
    required this.figure,
    this.description,
  });

  final Color color;
  final Color titleColor;
  final String title;
  final String value;
  final Widget figure;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, spreadRadius: -4, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Text(title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                SizedBox(height: 64, child: Center(child: figure)),
                const SizedBox(height: 8),
                Text(value,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: titleColor)),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.charcoal.withValues(alpha: 0.7))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
