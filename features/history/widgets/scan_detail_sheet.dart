import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../report/history_report.dart' show formatConfidence;
import '../data/scan_record.dart';
import 'history_download.dart';
import 'scan_image.dart';
import 'status_badge.dart';
import 'type_chip.dart';

Future<void> showScanDetailSheet(BuildContext context, ScanRecord record) => showModalBottomSheet<void>(
      context: context,
      // Cover the tab bar too, like the website's full-page modal.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: ScanDetailSheet(record: record)),
    );

/// The website's history detail modal as a bottom sheet.
class ScanDetailSheet extends ConsumerWidget {
  const ScanDetailSheet({required this.record}) : super(key: const Key('scanDetailSheet'));

  final ScanRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final status = t.t(StatusBadge.labelKey(record.status));
    const body = TextStyle(fontSize: 14, height: 1.6, color: AppColors.slate600);
    const bold = TextStyle(fontWeight: FontWeight.w700);
    Widget bullet(InlineSpan span) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: body),
              Expanded(child: Text.rich(span, style: body)),
            ],
          ),
        );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 192,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ScanNetworkImage(url: record.imageUrl, large: true),
              PositionedDirectional(
                top: 16,
                start: 16,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest.withValues(alpha: 0.9),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () => downloadHistoryReport(context, ref, record),
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: Text(t.t('history.downloadPdf')),
                ),
              ),
              PositionedDirectional(
                top: 16,
                end: 16,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.slate700),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  TypeAndDate(record: record, large: true),
                  StatusBadge(status: record.status, large: true),
                ],
              ),
              const SizedBox(height: 16),
              Text(record.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.slate900)),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${t.t('history.reportParagraph1')} '),
                  TextSpan(text: status, style: bold),
                  TextSpan(text: ' ${t.t('history.reportClassification')}'),
                ]),
                style: body,
              ),
              const SizedBox(height: 16),
              bullet(TextSpan(children: [
                TextSpan(text: '${t.t('history.confidenceScore')} '),
                TextSpan(text: '${formatConfidence(record.confidence)}%', style: bold),
              ])),
              for (final key in ['reportListItem1', 'reportListItem2', 'reportListItem3'])
                bullet(TextSpan(text: t.t('history.$key'))),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
