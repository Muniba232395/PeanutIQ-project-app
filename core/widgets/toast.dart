import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

enum ToastType { success, error, warning, info }

/// Port of the website's ToastContext: one toast at a time, white card with a coloured
/// start edge, icon in a tinted circle, bold gray-900 message, optional gray-500 subtext,
/// gray-400 close button. Auto-hides after 3s.
void showToast(
  BuildContext context,
  String message, {
  String? subtext,
  ToastType type = ToastType.success,
}) {
  final (edge, iconBackground, iconColor, icon) = switch (type) {
    ToastType.success => (AppColors.forest, AppColors.emerald100, AppColors.forest, LucideIcons.check),
    ToastType.error => (AppColors.red500, AppColors.red100, AppColors.red600, LucideIcons.triangleAlert),
    ToastType.warning =>
      (AppColors.amber500, AppColors.amber100, AppColors.amber600, LucideIcons.triangleAlert),
    ToastType.info => (AppColors.blue500, AppColors.blue100, AppColors.blue600, LucideIcons.info),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    duration: const Duration(seconds: 3),
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    content: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 40, spreadRadius: -10, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: Colors.white,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: edge),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
                          child: Icon(icon, size: 20, color: iconColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message,
                                  style: const TextStyle(
                                      color: AppColors.gray900,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              if (subtext != null) ...[
                                const SizedBox(height: 4),
                                Text(subtext,
                                    style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: messenger.hideCurrentSnackBar,
                          child: const Icon(LucideIcons.x, size: 16, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
}
