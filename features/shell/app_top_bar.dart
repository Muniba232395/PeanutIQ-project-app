import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/initials_avatar.dart';
import '../auth/auth_controller.dart';

/// The website's UserLayout header at phone width: white, 64px, earth bottom border,
/// logo at the start; language globe, notifications bell and avatar menu at the end.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.earth))),
          child: const Row(
            children: [
              AppLogo(size: 24, iconColor: AppColors.forest, leafColor: AppColors.forest),
              SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Wordmark(fontSize: 18, color: AppColors.darkText, accent: AppColors.forest),
                ),
              ),
              Spacer(),
              HeaderLanguageButton(),
              SizedBox(width: 8),
              _NotificationsButton(),
              SizedBox(width: 8),
              _AvatarMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header menus: white, 2px earth border, rounded-xl, no shadow.
ShapeBorder get _headerMenuShape => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.earth, width: 2),
    );

const _menuItemStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal);

class HeaderLanguageButton extends ConsumerWidget {
  const HeaderLanguageButton({super.key, this.child});

  /// Custom trigger (the More screen's Language row); defaults to the header globe.
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      key: child == null ? const Key('headerLanguageButton') : null,
      tooltip: '',
      elevation: 0,
      shape: _headerMenuShape,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 128, maxWidth: 128),
      onSelected: (code) => ref.read(localeControllerProvider.notifier).setLanguage(code),
      itemBuilder: (context) => const [
        // The website's header menu labels both languages in English.
        PopupMenuItem(value: 'en', height: 40, child: Text('English', style: _menuItemStyle)),
        PopupMenuItem(value: 'ur', height: 40, child: Text('Urdu', style: _menuItemStyle)),
      ],
      child: child ??
          Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(LucideIcons.globe, size: 20, color: AppColors.charcoal.withValues(alpha: 0.7)),
          ),
    );
  }
}

class _NotificationsButton extends ConsumerWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkResponse(
      key: const Key('notificationsButton'),
      radius: 20,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (_) => const _NotificationsSheet(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(LucideIcons.bell, size: 20, color: AppColors.charcoal.withValues(alpha: 0.7)),
      ),
    );
  }
}

/// The website's notifications dropdown. The list is always empty there too.
class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              border: Border(bottom: BorderSide(color: AppColors.earth)),
            ),
            child: Text(t.t('layout.header.notifications'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(LucideIcons.bell, size: 32, color: AppColors.gray300),
                const SizedBox(height: 8),
                Text(t.t('layout.header.noNotifications'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AvatarAction { profile, logout }

class _AvatarMenu extends ConsumerWidget {
  const _AvatarMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final name = ref.watch(authControllerProvider.select((s) => s.user?.name));
    return PopupMenuButton<_AvatarAction>(
      key: const Key('avatarButton'),
      tooltip: '',
      elevation: 0,
      shape: _headerMenuShape,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 192, maxWidth: 192),
      onSelected: (action) {
        switch (action) {
          case _AvatarAction.profile:
            context.go(Routes.profile);
          case _AvatarAction.logout:
            ref.read(authControllerProvider.notifier).logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AvatarAction.profile,
          height: 40,
          child: Row(children: [
            const Icon(LucideIcons.user, size: 16, color: AppColors.charcoal),
            const SizedBox(width: 8),
            Flexible(
              child: Text(t.t('layout.header.viewProfile'),
                  style: _menuItemStyle, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        PopupMenuItem(
          value: _AvatarAction.logout,
          height: 40,
          child: Row(children: [
            const Icon(LucideIcons.logOut, size: 16, color: AppColors.terracotta),
            const SizedBox(width: 8),
            Flexible(
              child: Text(t.t('layout.header.logout'),
                  style: _menuItemStyle.copyWith(color: AppColors.terracotta),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InitialsAvatar(name: name),
            const SizedBox(width: 2),
            Icon(LucideIcons.chevronDown, size: 16, color: AppColors.charcoal.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
