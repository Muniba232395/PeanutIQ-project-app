import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../assistant/assistant_launcher.dart';
import '../../assistant/widgets/robot_face.dart';
import '../../auth/auth_controller.dart';
import '../dashboard_providers.dart';

/// Port of DailyAITip: floating robot, "DAILY AI TIP" with a pulsing gold dot, the tip
/// (or the website's rain fallback) addressed to the farmer, and a pulsing mic that opens
/// the assistant.
class DailyTipCard extends ConsumerStatefulWidget {
  const DailyTipCard({super.key});

  @override
  ConsumerState<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends ConsumerState<DailyTipCard> with TickerProviderStateMixin {
  // animate-float: translateY 0 → -8px → 0 over 4s.
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  // animate-pulse: opacity 1 → .5 → 1 over 2s.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final user = ref.watch(authControllerProvider).user;
    final tip = ref.watch(dailyTipProvider).value;
    final name = (user?.name ?? '').trim();
    final firstName = name.isEmpty ? t.t('dashboard.app.defaultFirstName') : name.split(' ').first;
    final pulse = Tween<double>(begin: 1, end: 0.5)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [AppColors.forest.withValues(alpha: 0.05), AppColors.forest.withValues(alpha: 0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative gold glow at the end side.
          PositionedDirectional(
            end: -60,
            top: -60,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withValues(alpha: 0.12),
                  AppColors.gold.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _float,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, -8 * Curves.easeInOut.transform(_float.value)),
                    child: child,
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 15, spreadRadius: -3, offset: Offset(0, 10)),
                      ],
                    ),
                    child: const RobotFace(size: 36),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.t('dashboard.app.tipTitle').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                  letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FadeTransition(
                            opacity: pulse,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$firstName! ${tip ?? t.t('dashboard.app.tipFallback')}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FadeTransition(
                  opacity: pulse,
                  child: InkResponse(
                    key: const Key('tipMicButton'),
                    onTap: () => ref.read(assistantLauncherProvider.notifier).open(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 15)],
                      ),
                      child: const Icon(LucideIcons.mic, size: 16, color: AppColors.forest),
                    ),
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
