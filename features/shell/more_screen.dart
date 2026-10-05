import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../auth/auth_controller.dart';
import 'app_top_bar.dart';

/// The website sidebar's remaining items (History, Advisories, Profile), plus language
/// and logout, in the sidebar's nav-row style.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final code = ref.watch(localeControllerProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(children: [
          _Row(icon: LucideIcons.history, label: t.t('layout.nav.history'), onTap: () => context.go(Routes.history), rowKey: const Key('more-history')),
          _Row(icon: LucideIcons.triangleAlert, label: t.t('layout.nav.advisories'), onTap: () => context.go(Routes.advisories), rowKey: const Key('more-advisories')),
          _Row(icon: LucideIcons.user, label: t.t('layout.nav.profile'), onTap: () => context.go(Routes.profile), rowKey: const Key('more-profile')),
        ]),
        const SizedBox(height: 16),
        _Card(children: [
          HeaderLanguageButton(
            child: _Row(
              icon: LucideIcons.globe,
              label: t.t('layout.more.language'),
              trailing: code == 'ur' ? 'اردو' : 'English',
            ),
          ),
          _Row(
            icon: LucideIcons.logOut,
            label: t.t('layout.header.logout'),
            color: AppColors.terracotta,
            showChevron: false,
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ]),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.earth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.earth),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    this.rowKey,
    required this.label,
    this.onTap,
    this.trailing,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final Key? rowKey;
  final String label;
  final VoidCallback? onTap;
  final String? trailing;
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.charcoal;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.charcoal.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground)),
          ),
          if (trailing != null)
            Text(trailing!, style: TextStyle(fontSize: 14, color: AppColors.charcoal.withValues(alpha: 0.6))),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                size: 18, color: AppColors.charcoal.withValues(alpha: 0.4)),
          ],
        ],
      ),
    );
    return onTap == null ? row : InkWell(key: rowKey, onTap: onTap, child: row);
  }
}
