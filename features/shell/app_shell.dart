import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/theme.dart';
import '../assistant/floating_assistant.dart';
import 'app_top_bar.dart';

/// Tab scaffold: website header on top, bottom tabs styled like the website's sidebar
/// (active item forest with white icon, others charcoal at 70%).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell, required this.location});

  final StatefulNavigationShell navigationShell;

  /// Current route; the assistant closes when it changes.
  final String location;

  static const _tabs = [
    (icon: LucideIcons.layoutDashboard, labelKey: 'layout.tabs.home'),
    (icon: LucideIcons.bean, labelKey: 'layout.tabs.seed'),
    (icon: LucideIcons.scanSearch, labelKey: 'layout.tabs.disease'),
    (icon: LucideIcons.bookOpen, labelKey: 'layout.tabs.knowledge'),
    (icon: LucideIcons.menu, labelKey: 'layout.tabs.more'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final current = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: const AppTopBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          navigationShell,
          FloatingAssistant(location: location),
        ],
      ),
      bottomNavigationBar: Container(
        key: const Key('tabBar'),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.earth)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabItem(
                    key: Key('tab-$i'),
                    icon: _tabs[i].icon,
                    label: t.t(_tabs[i].labelKey),
                    active: i == current,
                    // Tapping the current tab again returns it to its first screen.
                    onTap: () => navigationShell.goBranch(i, initialLocation: i == current),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({super.key, required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = AppColors.charcoal.withValues(alpha: 0.7);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: active ? AppColors.forest : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 20, color: active ? Colors.white : inactive),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? AppColors.forest : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
