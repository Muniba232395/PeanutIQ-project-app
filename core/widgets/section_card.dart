import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/translations.dart';
import '../theme.dart';

/// The website's flat-card: white, 1px earth border, rounded-2xl, soft shadow, p-6.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.earth),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, spreadRadius: -4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Section heading: 20px icon (forest, stroke 2.5 on the website) + 17px bold charcoal title.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.icon, required this.title, this.iconColor = AppColors.forest});

  final IconData icon;
  final String title;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
        ),
      ],
    );
  }
}

/// "Read more →" style link. The arrow flips in RTL.
class ArrowLink extends StatelessWidget {
  const ArrowLink({super.key, required this.label, required this.onTap, this.color = AppColors.forest});

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(width: 4),
            Icon(rtl ? LucideIcons.arrowLeft : LucideIcons.arrowRight, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of a section whose data failed to load.
class SectionError extends ConsumerWidget {
  const SectionError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(t.t('dashboard.app.loadFailed'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.charcoal.withValues(alpha: 0.7))),
          TextButton(onPressed: onRetry, child: Text(t.t('common.retry'))),
        ],
      ),
    );
  }
}

class SectionLoading extends StatelessWidget {
  const SectionLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
}
