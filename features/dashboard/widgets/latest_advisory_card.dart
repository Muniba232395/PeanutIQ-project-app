import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/date_format.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../dashboard_providers.dart';

/// The website's "Latest Advisory" card: newest alert, time-ago chip, severity pill.
class LatestAdvisoryCard extends ConsumerWidget {
  const LatestAdvisoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final alert = ref.watch(latestAlertProvider);
    final advisory = alert.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionTitle(
                    icon: LucideIcons.triangleAlert,
                    iconColor: AppColors.red500,
                    title: t.t('dashboard.latestAdvisory')),
              ),
              if (advisory != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 12, color: AppColors.red500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(timeAgo(advisory.createdAt, t),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          switch (alert) {
            AsyncData(value: final a?) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      a.severity == 'high' ? t.t('dashboard.highPriority') : a.severity,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(a.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.red800)),
                  const SizedBox(height: 8),
                  Text(a.message,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: AppColors.charcoal.withValues(alpha: 0.8))),
                  const SizedBox(height: 20),
                ],
              ),
            AsyncData() => SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.green50, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.leaf, size: 24, color: AppColors.forest),
                      ),
                      const SizedBox(height: 12),
                      Text(t.t('dashboard.app.noAlerts'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal.withValues(alpha: 0.7))),
                      const SizedBox(height: 4),
                      Text(t.t('dashboard.app.noAlertsDesc'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.charcoal.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            AsyncError() => SectionError(onRetry: () => ref.invalidate(latestAlertProvider)),
            _ => const SectionLoading(),
          },
          ArrowLink(
            label: t.t('dashboard.readMore'),
            color: AppColors.red500,
            onTap: () => context.go(Routes.advisories),
          ),
        ],
      ),
    );
  }
}
