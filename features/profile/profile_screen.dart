import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/theme.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sub_page_header.dart';
import '../../core/widgets/toast.dart';
import '../auth/auth_controller.dart';
import '../auth/data/app_user.dart';
import '../auth/farm_regions.dart';
import '../../core/layout.dart';

/// Port of Users.jsx (the farmer's profile).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _timezones = [
    ('UTC', 'profile.app.tz.utc'),
    ('Asia/Karachi', 'profile.app.tz.karachi'),
    ('Asia/Riyadh', 'profile.app.tz.riyadh'),
    ('Europe/London', 'profile.app.tz.london'),
    ('America/New_York', 'profile.app.tz.newYork'),
  ];

  bool _editing = false;
  bool _saving = false;
  final _name = TextEditingController();
  String? _location;
  String _language = 'english';
  String _timezone = 'UTC';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _startEditing(AppUser user) => setState(() {
    _editing = true;
    _name.text = user.name ?? '';
    _location = user.hasFarmLocation ? user.farmLocation : null;
    _language = user.languagePreference == 'urdu' ? 'urdu' : 'english';
    _timezone = user.timezone;
  });

  Future<void> _save() async {
    final t = ref.read(trProvider);
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: _name.text,
            farmLocation: _location,
            languageCode: _language == 'urdu' ? 'ur' : 'en',
            timezone: _timezone,
          );
      if (!mounted) return;
      setState(() => _editing = false);
      // Read again: saving may have switched the app language.
      showToast(context, ref.read(trProvider).t('profile.app.saved'));
    } on Object {
      if (mounted) {
        showToast(context, t.t('auth.app.saveFailed'), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();
    final language = _editing ? _language : user.languagePreference;
    final timezone = _editing ? _timezone : user.timezone;

    return PopScope(
      // Back while editing cancels the edit instead of leaving the page.
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _editing) setState(() => _editing = false);
      },
      child: ListView(
        key: const Key('profileScroll'),
        padding: const EdgeInsets.only(bottom: pageBottomPadding),
        children: [
          SubPageHeader(
            title: t.t('profile.title'),
            subtitle: t.t('profile.subtitle'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _editing
                  ? _saveButton(t, const Key('profileSave'))
                  : OutlinedButton.icon(
                      key: const Key('profileEdit'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.gray700,
                        side: const BorderSide(color: AppColors.gray300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _startEditing(user),
                      icon: const Icon(LucideIcons.pencilLine, size: 16),
                      label: Text(t.t('profile.editProfile')),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _identity(t, user),
                  ),
                  _preferences(t, language: language, timezone: timezone),
                ],
              ),
            ),
          ),
          // On a phone the preferences sit below the fold, so Save is repeated at the bottom.
          if (_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _saveButton(t, const Key('profileSaveBottom')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _saveButton(Translations t, Key key) => KeyedSubtree(
    key: key,
    child: FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _saving || _name.text.trim().isEmpty ? null : _save,
      child: _saving
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(t.t('profile.saveChanges')),
    ),
  );

  Widget _identity(Translations t, AppUser user) {
    const info = TextStyle(fontSize: 14, color: AppColors.gray600);
    Widget row(IconData icon, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray400),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 15,
                spreadRadius: -3,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: InitialsAvatar(name: user.name, size: 96),
        ),
        const SizedBox(height: 16),
        if (_editing)
          TextField(
            key: const Key('profileName'),
            controller: _name,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
            decoration: const InputDecoration(
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.forest),
              ),
            ),
          )
        else
          Text(
            user.name ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          t.t('profile.roles.${user.role}', fallback: user.role),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 8),
        row(
          LucideIcons.mail,
          Text(
            user.identifier.isEmpty
                ? t.t('profile.noContact')
                : user.identifier,
            style: info,
          ),
        ),
        row(
          LucideIcons.mapPin,
          _editing
              ? PopupMenuButton<String>(
                  key: const Key('profileLocation'),
                  tooltip: '',
                  position: PopupMenuPosition.under,
                  onSelected: (v) => setState(() => _location = v),
                  itemBuilder: (_) => [
                    for (final r in farmRegions)
                      PopupMenuItem(value: r, child: Text(r)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.gray300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _location ?? t.t('profile.placeholder.location'),
                            style: info,
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.slate500,
                        ),
                      ],
                    ),
                  ),
                )
              : Text(
                  user.hasFarmLocation
                      ? user.farmLocation!
                      : t.t('profile.unknownLocation'),
                  style: info,
                ),
        ),
        // The website shows a crop type but never saves it; farmers here grow peanuts.
        row(LucideIcons.target, const Text('Peanut', style: info)),
        row(LucideIcons.user, Text('ID: ${user.id}', style: info)),
      ],
    );
  }

  Widget _preferences(
    Translations t, {
    required String language,
    required String timezone,
  }) {
    Widget pill({
      required Key key,
      required String value,
      required List<(String, String)> items,
      required ValueChanged<String> onSelected,
    }) {
      final box = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _editing ? Colors.white : AppColors.sand,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: AppColors.slate500,
            ),
          ],
        ),
      );
      return PopupMenuButton<String>(
        key: key,
        enabled: _editing,
        tooltip: '',
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (_) => [
          for (final (v, label) in items)
            PopupMenuItem(
              value: v,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
        ],
        child: Opacity(opacity: _editing ? 1 : 0.75, child: box),
      );
    }

    Widget prefRow(String title, String desc, Widget control) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray900,
          ),
        ),
        Text(
          desc,
          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
        const SizedBox(height: 8),
        control,
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        border: Border(top: BorderSide(color: AppColors.slate200)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.t('profile.accountPreferences').toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          prefRow(
            t.t('profile.languagePreference'),
            t.t('profile.languageDescription'),
            pill(
              key: const Key('profileLanguage'),
              // Capitalised like the website's `capitalize` class.
              value: language == 'urdu' ? 'Urdu' : 'English',
              items: [
                ('english', t.t('profile.english')),
                ('urdu', t.t('profile.urdu')),
              ],
              onSelected: (v) => setState(() => _language = v),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.slate200),
          ),
          prefRow(
            t.t('profile.app.timezoneTitle'),
            t.t('profile.app.timezoneDesc'),
            pill(
              key: const Key('profileTimezone'),
              value: timezone,
              items: [for (final (tz, key) in _timezones) (tz, t.t(key))],
              onSelected: (v) => setState(() => _timezone = v),
            ),
          ),
        ],
      ),
    );
  }
}
