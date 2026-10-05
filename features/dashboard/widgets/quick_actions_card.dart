import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';

class QuickActionsCard extends ConsumerWidget {
  const QuickActionsCard({super.key});

  static const _actions = [
    (icon: LucideIcons.bean, key: 'dashboard.seedQuality', bg: AppColors.green50, fg: AppColors.forest, route: Routes.seed),
    (icon: LucideIcons.scanSearch, key: 'dashboard.diseaseId', bg: AppColors.blue50, fg: AppColors.blue600, route: Routes.disease),
    (icon: LucideIcons.bookOpen, key: 'dashboard.knowledgeBase', bg: AppColors.teal50, fg: AppColors.teal600, route: Routes.knowledge),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(icon: LucideIcons.activity, title: t.t('dashboard.quickActions')),
          const SizedBox(height: 24),
          for (var i = 0; i < _actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go(_actions[i].route),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.earth.withValues(alpha: 0.7)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _actions[i].bg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
                      ),
                      child: Icon(_actions[i].icon, size: 24, color: _actions[i].fg),
                    ),
                    const SizedBox(height: 16),
                    Text(t.t(_actions[i].key),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
