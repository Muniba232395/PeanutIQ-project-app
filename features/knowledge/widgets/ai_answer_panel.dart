import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api_client.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';

/// The website's purple "AI Reasoning" panel.
class AiAnswerPanel extends ConsumerWidget {
  const AiAnswerPanel({super.key, required this.thinking, required this.answer, required this.onClose});

  final bool thinking;
  final String? answer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.purple50,
        border: Border.all(color: AppColors.purple100),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: thinking
          ? Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.purple700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.t('kb.aiThinking'),
                      style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.purple700)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 20, color: AppColors.purple900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.t('kb.aiRec'),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.purple900)),
                    ),
                    InkResponse(
                      key: const Key('kbAiClose'),
                      onTap: onClose,
                      child: const Icon(LucideIcons.x, size: 20, color: AppColors.purple400),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(answer ?? '', style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.purple800)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: AppColors.purple600),
                    const SizedBox(width: 4),
                    Expanded(
                      // Real AI answers can't claim to come from official protocols; demo mode keeps the website's line.
                      child: Text(t.t(ref.watch(demoModeProvider) ? 'kb.derivedInfo' : 'kb.app.aiDisclaimer'),
                          style: const TextStyle(fontSize: 12, color: AppColors.purple600)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
