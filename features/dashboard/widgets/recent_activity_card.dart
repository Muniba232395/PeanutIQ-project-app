import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/date_format.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/auth_controller.dart';
import '../dashboard_providers.dart';

/// The website's recent-activity table as a phone-friendly list.
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final timezone = ref.watch(authControllerProvider.select((s) => s.user?.timezone)) ?? 'UTC';
    final activities = ref.watch(activitiesProvider);
    final muted = AppColors.charcoal.withValues(alpha: 0.7);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              SectionTitle(icon: LucideIcons.history, title: t.t('dashboard.recentActivity')),
              ArrowLink(label: t.t('dashboard.viewAllActivity'), onTap: () => context.go(Routes.history)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.earth.withValues(alpha: 0.5)),
          switch (activities) {
            AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(t.t('dashboard.activities.noActivity'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.charcoal.withValues(alpha: 0.6))),
              ),
            AsyncData(:final value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < value.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: AppColors.earth.withValues(alpha: 0.4)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value[i].action,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                          if ((value[i].details ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(value[i].details!,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted)),
                          ],
                          const SizedBox(height: 2),
                          Text(formatDate(value[i].timestamp, timezone),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            AsyncError() => SectionError(onRetry: () => ref.invalidate(activitiesProvider)),
            _ => const SectionLoading(),
          },
        ],
      ),
    );
  }
}
