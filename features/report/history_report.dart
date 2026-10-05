import 'dart:typed_data';

import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/date_format.dart';
import '../../core/i18n/translations.dart';
import '../history/data/scan_record.dart';
import '../history/widgets/status_badge.dart';
import 'report_service.dart';

const _forest = PdfColor.fromInt(0xFF07571C);
const _slate900 = PdfColor.fromInt(0xFF0F172B);
const _slate600 = PdfColor.fromInt(0xFF45556C);
const _muted = PdfColor.fromInt(0xFF6A7282);
const _contentWidth = 21 * PdfPageFormat.cm - 2 * PdfPageFormat.cm;

String historyReportFileName(ScanRecord record, DateTime now) {
  final id = record.id.length > 8 ? record.id.substring(0, 8) : record.id;
  return 'peanutiq-history-$id-${DateFormat('yyyyMMdd-HHmm', 'en_US').format(now)}.pdf';
}

/// Printable version of the website's history detail modal.
Future<Uint8List> buildHistoryReport({
  required ScanRecord record,
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
  final status = tr.t(StatusBadge.labelKey(record.status));
  final text = const pw.TextStyle(fontSize: 11, color: _slate600, lineSpacing: 3);
  final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.copyWith(
      marginLeft: PdfPageFormat.cm,
      marginRight: PdfPageFormat.cm,
      marginTop: PdfPageFormat.cm,
      marginBottom: PdfPageFormat.cm,
    ),
    textDirection: tr.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    build: (_) => [
      pw.Text(tr.t('history.title'), style: const pw.TextStyle(fontSize: 10, color: _muted)),
      pw.Text('${tr.t('scan.app.generatedOn')} $generatedAt', style: const pw.TextStyle(fontSize: 9, color: _muted)),
      pw.SizedBox(height: 12),
      if (imageBytes != null) ...[
        pw.ClipRRect(
          horizontalRadius: 8,
          verticalRadius: 8,
          child: pw.Image(pw.MemoryImage(imageBytes), height: 220, width: _contentWidth, fit: pw.BoxFit.cover),
        ),
        pw.SizedBox(height: 12),
      ],
      pw.Text(
        '${tr.t(record.isSeed ? 'history.tabSeed' : 'history.tabDisease')}  ·  ${formatDueDate(record.createdAt)}  ·  $status',
        style: pw.TextStyle(fontSize: 10, color: _forest, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.Text(record.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _slate900)),
      pw.SizedBox(height: 12),
      pw.RichText(
        text: pw.TextSpan(style: text, children: [
          pw.TextSpan(text: '${tr.t('history.reportParagraph1')} '),
          pw.TextSpan(text: status, style: bold),
          pw.TextSpan(text: ' ${tr.t('history.reportClassification')}'),
        ]),
      ),
      pw.SizedBox(height: 10),
      pw.Bullet(
        text: '${tr.t('history.confidenceScore')} ${formatConfidence(record.confidence)}%',
        style: text,
      ),
      for (final key in ['reportListItem1', 'reportListItem2', 'reportListItem3'])
        pw.Bullet(text: tr.t('history.$key'), style: text),
    ],
  ));
  return doc.save();
}

/// 94.2 → "94.2", 98.0 → "98" (the website prints the number as the backend sends it).
String formatConfidence(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toString();
