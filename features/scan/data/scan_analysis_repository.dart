import 'dart:ui';

/// A titled step in a result (seed actions, disease treatments).
class AnalysisStep {
  const AnalysisStep(this.title, this.detail);

  factory AnalysisStep.fromJson(Map<String, dynamic> json) =>
      AnalysisStep('${json['title'] ?? ''}', '${json['detail'] ?? ''}');

  final String title;
  final String detail;
}

List<AnalysisStep> _steps(Object? list) => [
      for (final item in (list as List?) ?? const []) AnalysisStep.fromJson(item as Map<String, dynamic>),
    ];

int _int(Object? v) => (v as num?)?.round() ?? 0;

/// What the backend's AI (Gemini) found in a scan photo. Texts are in the language the scan was made in.
sealed class ScanAnalysis {
  const ScanAnalysis();

  /// AI confidence, 0-100.
  int get confidencePct;
}

class SeedAnalysis extends ScanAnalysis {
  const SeedAnalysis({
    required this.totalSeeds,
    required this.healthyPct,
    required this.underdevelopedPct,
    required this.damagedPct,
    required this.diseasedPct,
    required this.grade,
    required this.germinationPct,
    required this.sizeUniformityPct,
    required this.colorConsistencyPct,
    required this.confidencePct,
    required this.summary,
    required this.actions,
  });

  factory SeedAnalysis.fromJson(Map<String, dynamic> json) {
    final p = (json['percentages'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SeedAnalysis(
      totalSeeds: _int(json['total_seeds']),
      healthyPct: _int(p['healthy']),
      underdevelopedPct: _int(p['underdeveloped']),
      damagedPct: _int(p['damaged']),
      diseasedPct: _int(p['diseased']),
      grade: '${json['grade'] ?? '-'}',
      germinationPct: _int(json['germination_pct']),
      sizeUniformityPct: _int(json['size_uniformity_pct']),
      colorConsistencyPct: _int(json['color_consistency_pct']),
      confidencePct: _int(json['confidence_pct']),
      summary: '${json['summary'] ?? ''}',
      actions: _steps(json['actions']),
    );
  }

  final int totalSeeds;
  final int healthyPct;
  final int underdevelopedPct;
  final int damagedPct;
  final int diseasedPct;
  final String grade;
  final int germinationPct;
  final int sizeUniformityPct;
  final int colorConsistencyPct;
  @override
  final int confidencePct;
  final String summary;
  final List<AnalysisStep> actions;

  /// A or B: fit for planting.
  bool get goodLot => grade == 'A' || grade == 'B';

  /// The website's four classes and colours.
  List<({String key, int value, Color color})> get breakdown => [
        (key: 'seed.data.healthy', value: healthyPct, color: const Color(0xFF22C55E)),
        (key: 'seed.data.underdeveloped', value: underdevelopedPct, color: const Color(0xFFEAB308)),
        (key: 'seed.data.damaged', value: damagedPct, color: const Color(0xFFF97316)),
        (key: 'seed.data.diseased', value: diseasedPct, color: const Color(0xFFEF4444)),
      ];
}

class DiseaseAnalysis extends ScanAnalysis {
  const DiseaseAnalysis({
    required this.category,
    required this.conditionEn,
    required this.condition,
    required this.confidencePct,
    required this.affectedPct,
    required this.severityStage,
    required this.outbreakRisk,
    required this.explanation,
    required this.urgentAction,
    required this.treatments,
    required this.prevention,
  });

  factory DiseaseAnalysis.fromJson(Map<String, dynamic> json) => DiseaseAnalysis(
        category: '${json['category'] ?? 'other'}',
        conditionEn: '${json['condition_en'] ?? ''}',
        condition: '${json['condition'] ?? json['condition_en'] ?? ''}',
        confidencePct: _int(json['confidence_pct']),
        affectedPct: _int(json['affected_pct']),
        severityStage: _int(json['severity_stage']).clamp(0, 4),
        outbreakRisk: '${json['outbreak_risk'] ?? 'medium'}',
        explanation: '${json['explanation'] ?? ''}',
        urgentAction: '${json['urgent_action'] ?? ''}',
        treatments: _steps(json['treatments']),
        prevention: '${json['prevention'] ?? ''}',
      );

  /// healthy | disease | pest | nutrient | other
  final String category;
  final String conditionEn;

  /// The condition's name in the scan's language.
  final String condition;
  @override
  final int confidencePct;
  final int affectedPct;

  /// 0 none, 1 early, 2 moderate, 3 severe, 4 critical.
  final int severityStage;

  /// low | medium | high
  final String outbreakRisk;
  final String explanation;
  final String urgentAction;
  final List<AnalysisStep> treatments;
  final String prevention;

  bool get healthy => category == 'healthy';
}
