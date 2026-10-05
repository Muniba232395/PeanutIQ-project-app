import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/theme.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sub_page_header.dart';
import 'data/scan_record.dart';
import 'history_providers.dart';
import 'widgets/scan_detail_sheet.dart';
import 'widgets/scan_record_card.dart';
import '../../core/layout.dart';

/// Port of HistoryReports: filter chips, scan cards, detail sheet, PDF download.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _filters = ['All', 'Seed Intelligence', 'Disease Intelligence'];
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final history = ref.watch(historyProvider);
    return RefreshIndicator(
      color: AppColors.forest,
      onRefresh: () => ref.refresh(historyProvider.future).then((_) {}, onError: (_) {}),
      child: ListView(
        key: const Key('historyScroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: pageBottomPadding),
        children: [
          SubPageHeader(title: t.t('history.title'), subtitle: t.t('history.subtitle')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _filters)
                  _FilterChip(
                    key: Key('filter-$f'),
                    label: t.t(switch (f) {
                      'All' => 'history.tabAll',
                      'Seed Intelligence' => 'history.tabSeed',
                      _ => 'history.tabDisease',
                    }),
                    active: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: switch (history) {
              AsyncData(:final value) => _List(
                  records: [for (final r in value) if (_filter == 'All' || r.type == _filter) r],
                ),
              AsyncError() => SectionCard(child: SectionError(onRetry: () => ref.invalidate(historyProvider))),
              _ => const SectionLoading(),
            },
          ),
        ],
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.records});

  final List<ScanRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.earth),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.funnel, size: 48, color: AppColors.slate300),
            const SizedBox(height: 12),
            Text(t.t('history.noRecords'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.slate900)),
            const SizedBox(height: 4),
            Text(t.t('history.tryFilters'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.slate500)),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < records.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          ScanRecordCard(record: records[i], onOpen: () => showScanDetailSheet(context, records[i])),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.forest : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: active ? AppColors.forest : AppColors.slate200)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.slate600)),
        ),
      ),
    );
  }
}
