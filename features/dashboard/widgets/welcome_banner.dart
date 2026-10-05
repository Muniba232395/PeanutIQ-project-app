import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/auth_controller.dart';

/// The website's welcome banner: #0F5A27 with the farm illustration (mirrored in RTL).
class WelcomeBanner extends ConsumerWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final user = ref.watch(authControllerProvider).user;
    final name = (user?.name ?? '').trim().isEmpty ? t.t('dashboard.app.defaultName') : user!.name!;
    final location = (user?.farmLocation ?? '').trim().isEmpty
        ? t.t('dashboard.defaultLocation')
        : user!.farmLocation!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.bannerGreen,
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.flip(
                flipX: rtl,
                child: Image.asset(
                  'assets/images/farm-banner-bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.t('dashboard.welcome', args: {'name': name}),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AppLogo(size: 24, iconColor: Colors.white, leafColor: AppColors.lime),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.t('dashboard.farmIntro', args: {'location': location}),
                    style: TextStyle(
                        fontSize: 13, height: 1.25, color: AppColors.green50.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
