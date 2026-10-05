import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../dashboard_providers.dart';

/// Port of CropLifecycle: five stages, a progress line, and a pulsing current stage.
/// While the crop profile is unknown the website defaults to 'pegging'; so does this.
class CropLifecycleCard extends ConsumerWidget {
  const CropLifecycleCard({super.key});

  static const _stages = [
    (id: 'sowing', icon: LucideIcons.nut),
    (id: 'flowering', icon: LucideIcons.flower2),
    (id: 'pegging', icon: LucideIcons.bean),
    (id: 'podFill', icon: LucideIcons.package),
    (id: 'harvesting', icon: LucideIcons.tractor),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final stage = ref.watch(cropProfileProvider).value?.stage ?? 'pegging';
    final current = _stages.indexWhere((s) => s.id == stage);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(icon: LucideIcons.leaf, title: t.t('dashboard.app.lifecycleTitle')),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            // min-w-[480px], scrolls sideways on narrow screens.
            final width = math.max(480.0, constraints.maxWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Room for the current stage's glow and ping, which the scroll view would clip.
              padding: const EdgeInsets.symmetric(vertical: 16),
              clipBehavior: Clip.none,
              child: SizedBox(
                width: width,
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: width * 0.1,
                      end: width * 0.1,
                      top: 21,
                      height: 6,
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.earth, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    PositionedDirectional(
                      start: width * 0.1,
                      top: 21,
                      height: 6,
                      width: width * 0.8 * (math.max(0, current) / 4),
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _stages.length; i++)
                          Expanded(
                            child: _Step(
                              icon: _stages[i].icon,
                              label: t.t('dashboard.app.stages.${_stages[i].id}'),
                              completed: current > i,
                              isCurrent: current == i,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.completed, required this.isCurrent});

  final IconData icon;
  final String label;
  final bool completed;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final faded = AppColors.charcoal.withValues(alpha: 0.4);
    final circle = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: completed ? AppColors.forest : (isCurrent ? Colors.white : AppColors.earth),
        shape: BoxShape.circle,
        border: Border.all(color: completed || isCurrent ? AppColors.forest : AppColors.earth, width: 3),
        boxShadow: isCurrent
            ? [BoxShadow(color: AppColors.forest.withValues(alpha: 0.3), blurRadius: 15)]
            : const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Icon(icon,
          size: 20, color: completed ? Colors.white : (isCurrent ? AppColors.forest : faded)),
    );
    return Column(
      children: [
        if (isCurrent) _CurrentStage(child: circle) else circle,
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: completed ? AppColors.charcoal : (isCurrent ? AppColors.forest : faded),
          ),
        ),
      ],
    );
  }
}

/// scale-110 with animate-pulse on the icon and an animate-ping ring.
class _CurrentStage extends StatefulWidget {
  const _CurrentStage({required this.child});

  final Widget child;

  @override
  State<_CurrentStage> createState() => _CurrentStageState();
}

class _CurrentStageState extends State<_CurrentStage> with SingleTickerProviderStateMixin {
  late final AnimationController _ping =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ping,
            builder: (context, _) => Transform.scale(
              scale: 1 + _ping.value,
              child: Opacity(
                opacity: 0.2 * (1 - _ping.value),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.forest, width: 2),
                  ),
                ),
              ),
            ),
          ),
          Transform.scale(scale: 1.1, child: widget.child),
        ],
      ),
    );
  }
}
