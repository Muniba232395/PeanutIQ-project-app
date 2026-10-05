import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/date_format.dart';
import '../../core/i18n/translations.dart';
import '../../core/theme.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sub_page_header.dart';
import '../auth/auth_controller.dart';
import 'advisories_providers.dart';
import 'data/advisory.dart';
import '../../core/layout.dart';

/// Port of Advisories.jsx.
class AdvisoriesScreen extends ConsumerWidget {
  const AdvisoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final advisories = ref.watch(advisoryListProvider);
    return RefreshIndicator(
      color: AppColors.forest,
      onRefresh: () => ref.refresh(advisoryListProvider.future).then((_) {}, onError: (_) {}),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: pageBottomPadding),
        children: [
          SubPageHeader(title: t.t('advisories.title'), subtitle: t.t('advisories.subtitle')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: switch (advisories) {
              AsyncData(:final value) when value.isEmpty => _Empty(t: t),
              AsyncData(:final value) => Column(
                  children: [
                    for (var i = 0; i < value.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _AdvisoryCard(advisory: value[i]),
                    ],
                  ],
                ),
              AsyncError() => SectionCard(child: SectionError(onRetry: () => ref.invalidate(advisoryListProvider))),
              _ => const SectionLoading(),
            },
          ),
        ],
      ),
    );
  }
}

class _AdvisoryCard extends ConsumerWidget {
  const _AdvisoryCard({required this.advisory});

  final Advisory advisory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timezone = ref.watch(authControllerProvider.select((s) => s.user?.timezone)) ?? 'UTC';
    final (edge, icon) = switch (advisory.severity) {
      'high' => (AppColors.red500, LucideIcons.triangleAlert),
      'medium' => (AppColors.yellow500, LucideIcons.info),
      _ => (AppColors.blue500, LucideIcons.info),
    };
    final isAlert = advisory.type == 'alert';
    return Container(
      key: Key('advisory-${advisory.severity}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: edge),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 20, color: edge),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(advisory.title,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.clock, size: 14, color: AppColors.slate500),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(formatDate(advisory.createdAt, timezone),
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAlert ? AppColors.red50 : AppColors.blue50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      // The website shows the raw type in capitals, untranslated.
                      child: Text(advisory.type.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAlert ? AppColors.red700 : AppColors.blue700)),
                    ),
                    const SizedBox(height: 12),
                    Text(advisory.message,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.slate600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Icon(LucideIcons.leaf, size: 48, color: AppColors.forest.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(t.t('advisories.emptyTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate900)),
          const SizedBox(height: 8),
          Text(t.t('advisories.emptyDesc'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.slate500)),
        ],
      ),
    );
  }
}
