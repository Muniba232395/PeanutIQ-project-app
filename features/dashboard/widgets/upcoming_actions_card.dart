import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/date_format.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/toast.dart';
import '../dashboard_providers.dart';
import '../data/models.dart';

/// Port of UpcomingActions: tap a task to check it off (saved to the server).
class UpcomingActionsCard extends ConsumerWidget {
  const UpcomingActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final actions = ref.watch(actionsProvider);
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
              SectionTitle(icon: LucideIcons.calendarClock, title: t.t('dashboard.app.upcomingTitle')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t.t('dashboard.app.aiRecommended').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.forest, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          switch (actions) {
            AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(t.t('dashboard.app.noActions'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray500)),
              ),
            AsyncData(:final value) => Column(
                children: [
                  for (var i = 0; i < value.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _TaskTile(item: value[i]),
                  ],
                ],
              ),
            AsyncError() => SectionError(onRetry: () => ref.invalidate(actionsProvider)),
            _ => const SectionLoading(),
          },
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.item});

  final ActionItem item;

  IconData get _icon {
    final category = item.category.toLowerCase();
    if (category.contains('irrigation')) return LucideIcons.droplets;
    if (category.contains('disease')) return LucideIcons.shield;
    return LucideIcons.sprout;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = item.isCompleted;
    final dueDate = item.dueDate;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final t = ref.read(trProvider);
        final saved = await ref.read(actionsProvider.notifier).toggle(item.id);
        if (!saved && context.mounted) {
          showToast(context, t.t('dashboard.app.toggleFailed'), type: ToastType.error);
        }
      },
      child: Opacity(
        opacity: done ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: done ? AppColors.earth.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.earth.withValues(alpha: 0.5)),
            boxShadow: done
                ? null
                : const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 2),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? AppColors.forest : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: done ? AppColors.forest : AppColors.charcoal.withValues(alpha: 0.2), width: 2),
                ),
                child: done ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: done ? AppColors.charcoal.withValues(alpha: 0.6) : AppColors.charcoal,
                        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sky50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icon, size: 14, color: AppColors.sky500),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.sky500,
                                      letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dueDate != null)
                          Text(
                            formatDueDate(dueDate),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal.withValues(alpha: 0.7)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
