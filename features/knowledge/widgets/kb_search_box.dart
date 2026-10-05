import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';

/// Search input plus the Search / Ask AI toggle.
class KbSearchBox extends ConsumerWidget {
  const KbSearchBox({
    super.key,
    required this.controller,
    required this.aiMode,
    required this.onModeChanged,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool aiMode;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return SectionCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('kbSearchField'),
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.slate900),
            decoration: InputDecoration(
              // The website's search input sits borderless inside the card.
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: t.t(aiMode ? 'kb.searchAiPlaceholder' : 'kb.searchPlaceholder'),
              hintStyle: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w500),
              prefixIcon: Icon(aiMode ? LucideIcons.sparkles : LucideIcons.search,
                  size: 20, color: aiMode ? AppColors.forest : AppColors.slate400),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    key: const Key('kbModeSearch'),
                    label: t.t('kb.searchBtn'),
                    active: !aiMode,
                    activeColor: Colors.white,
                    activeText: AppColors.slate900,
                    onTap: () => onModeChanged(false),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    key: const Key('kbModeAi'),
                    label: t.t('kb.askAiBtn'),
                    icon: LucideIcons.sparkles,
                    active: aiMode,
                    activeColor: AppColors.forest,
                    activeText: Colors.white,
                    onTap: () => onModeChanged(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.activeText,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final Color activeText;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeText : AppColors.slate600;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 4)],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
