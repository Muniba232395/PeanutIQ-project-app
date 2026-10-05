import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/date_format.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/widgets/toast.dart';
import '../../auth/auth_controller.dart';
import '../../report/history_report.dart';
import '../../report/report_service.dart';
import '../data/scan_record.dart';

/// Builds and shares the PDF for one saved scan. The photo is optional: if it can't be
/// downloaded the report is shared without it.
Future<void> downloadHistoryReport(BuildContext context, WidgetRef ref, ScanRecord record) async {
  final t = ref.read(trProvider);
  final bundles = ref.read(translationBundlesProvider);
  final timezone = ref.read(authControllerProvider).user?.timezone ?? 'UTC';
  try {
    final now = DateTime.now();
    Uint8List? image;
    if (record.imageUrl.isNotEmpty) {
      try {
        image = await ref.read(apiClientProvider).getBytes(record.imageUrl);
      } on Object {
        image = null;
      }
    }
    final bytes = await buildHistoryReport(
      record: record,
      t: t,
      english: Translations('en', bundles['en']!),
      imageBytes: image,
      generatedAt: formatDate(now.toUtc(), timezone),
      fonts: await ref.read(reportFontsLoaderProvider)(t.languageCode),
    );
    await ref.read(reportSharerProvider).share(bytes, historyReportFileName(record, now));
  } on Object {
    if (context.mounted) showToast(context, t.t('history.app.downloadFailed'), type: ToastType.error);
  }
}
