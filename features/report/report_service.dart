import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Hands a finished PDF to Android's share sheet (save to Files, WhatsApp, print...).
abstract interface class ReportSharer {
  Future<void> share(Uint8List bytes, String filename);
}

class PrintingReportSharer implements ReportSharer {
  const PrintingReportSharer();

  @override
  Future<void> share(Uint8List bytes, String filename) => Printing.sharePdf(bytes: bytes, filename: filename);
}

final reportSharerProvider = Provider<ReportSharer>((ref) => const PrintingReportSharer());

class ReportFonts {
  const ReportFonts({required this.base, required this.bold, this.fallback = const []});

  final pw.Font base;
  final pw.Font bold;
  final List<pw.Font> fallback;
}

/// Bundled fonts for the PDF: Inter, or Noto Naskh Arabic for Urdu (the pdf package can't
/// shape Nastaliq). Returns null if they can't be read; the report then uses English + Helvetica.
Future<ReportFonts?> loadReportFonts(String languageCode) async {
  Future<pw.Font> font(String file) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
  try {
    final inter = await font('Inter-400.ttf');
    final interBold = await font('Inter-700.ttf');
    if (languageCode != 'ur') return ReportFonts(base: inter, bold: interBold);
    return ReportFonts(
      base: await font('NotoNaskhArabic-400.ttf'),
      bold: await font('NotoNaskhArabic-700.ttf'),
      fallback: [inter, interBold],
    );
  } on Object {
    return null;
  }
}

final reportFontsLoaderProvider =
    Provider<Future<ReportFonts?> Function(String languageCode)>((ref) => loadReportFonts);

/// Reads the scanned photo for the report (a provider so widget tests can skip file I/O).
final reportImageLoaderProvider = Provider<Future<Uint8List?> Function(String? path)>(
  (ref) => (path) async => path == null ? null : File(path).readAsBytes(),
);
