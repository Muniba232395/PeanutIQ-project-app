import 'dart:typed_data';

import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/i18n/translations.dart';
import '../scan/data/scan_analysis_repository.dart';
import '../scan/scan_kind.dart';
import 'report_service.dart';

const _forest = PdfColor.fromInt(0xFF07571C);
const _charcoal = PdfColor.fromInt(0xFF3D4035);
const _muted = PdfColor.fromInt(0xFF6A7282);
const _earth = PdfColor.fromInt(0xFFE5E7EB);
const _terracotta = PdfColor.fromInt(0xFFE07A5F);
const _red = PdfColor.fromInt(0xFFFB2C36);

/// A4 width minus the 1cm margins on each side.
const _contentWidth = 21 * PdfPageFormat.cm - 2 * PdfPageFormat.cm;

String reportFileName(ScanKind kind, DateTime now) =>
    'peanutiq-${kind.name}-report-${DateFormat('yyyyMMdd-HHmm', 'en_US').format(now)}.pdf';

String stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]+>'), '');

/// The printable version of the Seed / Disease results (replaces the website's window.print()).
/// A4 with 1cm margins like the website's print CSS. Without [fonts] the built-in Helvetica
/// can't draw Urdu, so the report falls back to [english].
Future<Uint8List> buildScanReport({
  required ScanKind kind,
  required ScanAnalysis analysis,
  required Translations t,
  required Translations english,
  required Uint8List? imageBytes,
  required String generatedAt,
  ReportFonts? fonts,
}) async {
  final tr = fonts == null && t.isRtl ? english : t;
  final doc = pw.Document(
    theme: fonts == null
        ? null
        : pw.ThemeData.withFont(base: fonts.base, bold: fonts.bold, fontFallback: fonts.fallback),
  );
  final p = kind.prefix;

  pw.Widget heading(String text, {PdfColor color = _forest}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(text.toUpperCase(),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 1)),
      );
  pw.Widget body(String text) =>
      pw.Text(text, style: const pw.TextStyle(fontSize: 10, color: _charcoal, lineSpacing: 2));
  pw.Widget keyValue(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted))),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _charcoal)),
        ]),
      );
  pw.Widget bar(double fraction, PdfColor color) => pw.Container(
        height: 6,
        decoration: pw.BoxDecoration(color: _earth, borderRadius: pw.BorderRadius.circular(3)),
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: _contentWidth * fraction,
          decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(3)),
        ),
      );

  final content = <pw.Widget>[
    pw.Text(tr.t('$p.title'), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _charcoal)),
    pw.SizedBox(height: 2),
    pw.Text(tr.t('$p.subtitle'), style: const pw.TextStyle(fontSize: 10, color: _muted)),
    pw.SizedBox(height: 4),
    pw.Text('${tr.t('scan.app.generatedOn')} $generatedAt', style: const pw.TextStyle(fontSize: 9, color: _muted)),
    pw.Divider(color: _earth),
    if (imageBytes != null)
      pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Image(pw.MemoryImage(imageBytes), height: 180, width: _contentWidth, fit: pw.BoxFit.cover),
      ),
  ];

  pw.Widget step(String number, AnalysisStep step) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('$number${step.title}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _charcoal)),
          body(step.detail),
        ]),
      );

  switch (analysis) {
    case SeedAnalysis a:
      content.addAll([
        heading(tr.t('seed.overallGrade')),
        keyValue(tr.t('seed.overallGrade'), a.grade),
        body(a.summary),
        keyValue(tr.t('seed.germination'), '${a.germinationPct}%'),
        keyValue(tr.t('seed.totalAnalyzed'), '${a.totalSeeds}'),
        heading(tr.t('seed.uniformity')),
        keyValue(tr.t('seed.app.sizeUniformity'), '${a.sizeUniformityPct}%'),
        bar(a.sizeUniformityPct / 100, _forest),
        pw.SizedBox(height: 6),
        keyValue(tr.t('seed.colorCon'), '${a.colorConsistencyPct}%'),
        bar(a.colorConsistencyPct / 100, _forest),
        heading(tr.t('seed.breakdown')),
        for (final item in a.breakdown) ...[
          keyValue(tr.t(item.key), '${item.value}%'),
          bar(item.value / 100, PdfColor.fromInt(item.color.toARGB32())),
          pw.SizedBox(height: 4),
        ],
        heading(tr.t('seed.actions')),
        for (final s in a.actions) step('• ', s),
        pw.SizedBox(height: 8),
        body(tr.t('seed.app.aiNote')),
      ]);
    case DiseaseAnalysis a:
      final color = a.healthy ? _forest : _terracotta;
      content.addAll([
        heading(tr.t(a.healthy ? 'disease.app.healthyTitle' : 'disease.app.detectedTitle'), color: color),
        keyValue(tr.t(a.healthy ? 'disease.app.healthyTitle' : 'disease.app.detectedTitle'), a.condition),
        keyValue('', tr.t('disease.app.confidence', args: {'pct': a.confidencePct})),
        if (!a.healthy) ...[
          keyValue(tr.t('disease.severityTitle'), tr.t('disease.app.severity.${a.severityStage}')),
          body(tr.t('disease.app.affected', args: {'pct': a.affectedPct})),
          keyValue(tr.t('disease.riskTitle'), tr.t('disease.app.risk.${a.outbreakRisk}')),
        ],
        heading(tr.t('disease.app.symptomsTitle'), color: color),
        body(a.explanation),
        if (a.urgentAction.isNotEmpty) ...[
          heading(tr.t('disease.app.nowTitle'), color: a.healthy ? _forest : _red),
          body(a.urgentAction),
        ],
        heading(tr.t('disease.managementTitle')),
        for (final (i, s) in a.treatments.indexed) step('${i + 1}. ', s),
        if (a.prevention.isNotEmpty) step('', AnalysisStep(tr.t('disease.app.preventionTitle'), a.prevention)),
        pw.SizedBox(height: 8),
        body(tr.t('disease.app.aiNote')),
      ]);
  }

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.copyWith(
      marginLeft: PdfPageFormat.cm,
      marginRight: PdfPageFormat.cm,
      marginTop: PdfPageFormat.cm,
      marginBottom: PdfPageFormat.cm,
    ),
    textDirection: tr.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    build: (_) => content,
  ));
  return doc.save();
}
