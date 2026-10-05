import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_logo.dart';

/// Full-width primary button. Disabled while [loading] or when [onPressed] is null,
/// shown at 50% opacity like the website. [showLogo] adds the small bean-and-leaf mark
/// the website puts after the label on its auth buttons.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color,
    this.showLogo = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final background = color ?? AppColors.forest;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        disabledBackgroundColor: background.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                if (showLogo) ...[
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: 0.8,
                    child: AppLogo(size: 16, iconColor: Colors.white, leafColor: Colors.white),
                  ),
                ],
              ],
            ),
    );
  }
}
