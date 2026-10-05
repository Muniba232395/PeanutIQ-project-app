import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// Title row for screens pushed from the More tab: back arrow + page title.
class SubPageHeader extends StatelessWidget {
  const SubPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canPop = GoRouter.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            IconButton(
              key: const Key('subPageBack'),
              onPressed: () => context.pop(),
              icon: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? LucideIcons.chevronRight
                    : LucideIcons.chevronLeft,
                color: AppColors.charcoal,
              ),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: textTheme.titleLarge?.copyWith(
                          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.charcoal)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14, color: AppColors.charcoal.withValues(alpha: 0.7))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
