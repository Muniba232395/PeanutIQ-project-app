import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/date_format.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../data/scan_record.dart';

/// Type chip + calendar date, as on the website's history cards.
class TypeAndDate extends ConsumerWidget {
  const TypeAndDate({super.key, required this.record, this.large = false});

  final ScanRecord record;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final size = large ? 14.0 : 12.0;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: large ? 10 : 8, vertical: large ? 4 : 2),
          decoration: BoxDecoration(
            color: AppColors.sand,
            border: Border.all(color: AppColors.earth),
            borderRadius: BorderRadius.circular(large ? 6 : 4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(record.isSeed ? LucideIcons.bean : LucideIcons.scanSearch, size: 16, color: AppColors.forest),
              SizedBox(width: large ? 6 : 4),
              Flexible(
                child: Text(t.t(record.isSeed ? 'history.tabSeed' : 'history.tabDisease'),
                    style: TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: AppColors.forest)),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendar, size: large ? 16 : 14, color: AppColors.slate500),
            SizedBox(width: large ? 6 : 4),
            Text(formatDueDate(record.createdAt),
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: AppColors.slate500)),
          ],
        ),
      ],
    );
  }
}
