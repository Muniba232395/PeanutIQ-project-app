import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../data/scan_record.dart';
import 'history_download.dart';
import 'scan_image.dart';
import 'status_badge.dart';
import 'type_chip.dart';

class ScanRecordCard extends ConsumerWidget {
  const ScanRecordCard({super.key, required this.record, required this.onOpen});

  final ScanRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.earth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScanNetworkImage(url: record.imageUrl),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: StatusBadge(status: record.status, translucent: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TypeAndDate(record: record),
                  const SizedBox(height: 8),
                  Text(record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.slate100),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.sand,
                      foregroundColor: AppColors.forest,
                      side: const BorderSide(color: AppColors.earth),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => downloadHistoryReport(context, ref, record),
                    icon: const Icon(LucideIcons.download, size: 16),
                    label: Text(t.t('history.downloadPdf')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
