import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/translations.dart';
import '../theme.dart';

/// The website's English / اردو pill: gray-200 border, gray-700 text, white menu
/// with the selected language on green-50. Language names are shown in their own script.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  static const _languages = {'en': 'English', 'ur': 'اردو'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeControllerProvider);
    final iconColor = AppColors.gray700.withValues(alpha: 0.6);
    return PopupMenuButton<String>(
      key: const Key('languageSwitch'),
      initialValue: code,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 128, maxWidth: 128),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      onSelected: (value) => ref.read(localeControllerProvider.notifier).setLanguage(value),
      itemBuilder: (context) => [
        for (final entry in _languages.entries)
          PopupMenuItem(
            value: entry.key,
            padding: EdgeInsets.zero,
            height: 40,
            child: Container(
              width: double.infinity,
              height: 40,
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: entry.key == code ? AppColors.green50.withValues(alpha: 0.5) : null,
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: entry.key == code ? AppColors.forest : AppColors.gray700,
                ),
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.globe, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Text(
              _languages[code]!,
              style: const TextStyle(
                  color: AppColors.gray700, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronDown, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }
}
