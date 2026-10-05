import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/maintenance_mode.dart';
import '../../core/theme.dart';
import '../auth/auth_controller.dart';
import 'maintenance_repository.dart';

/// Shown whenever the API returns 503. Polls every 60s; when the window ends it
/// clears maintenance mode and the router moves on (Home or Login).
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  Timer? _poll;
  bool _checking = false;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _check();
    _poll = Timer.periodic(const Duration(seconds: 60), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _spin.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status = await ref.read(maintenanceRepositoryProvider).fetchStatus();
      if (!mounted) return;
      if (status.active) {
        setState(() => _endTime = status.endTime);
      } else {
        ref.read(maintenanceModeProvider.notifier).exit();
      }
    } on Object {
      // Offline or server error: keep showing this screen and try again on the next tick.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).logout();
    ref.read(maintenanceModeProvider.notifier).exit();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final textTheme = Theme.of(context).textTheme;
    final endTime = _endTime;
    // Mirrors the website's Maintenance page: white rounded-3xl card with shadow-xl and a
    // forest-to-earth strip, charcoal text at 100/70/60%, forest button.
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 448),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.earth.withValues(alpha: 0.2)),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 25, spreadRadius: -5, offset: Offset(0, 20)),
                  BoxShadow(color: Color(0x1A000000), blurRadius: 10, spreadRadius: -6, offset: Offset(0, 8)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.forest, AppColors.earth]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.sand.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: RotationTransition(
                            turns: _spin,
                            child: const Icon(LucideIcons.settings, size: 40, color: AppColors.forest),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.t('maintenance.title'),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                              fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.charcoal),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.t('maintenance.desc'),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.charcoal.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 32),
                        if (endTime != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.sand.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.earth.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Text(t.t('maintenance.expected'),
                                    style: textTheme.bodySmall?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.charcoal.withValues(alpha: 0.6))),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('hh:mm a', 'en_US').format(endTime.toLocal()),
                                  textDirection: TextDirection.ltr,
                                  style: textTheme.titleLarge?.copyWith(
                                      fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(60),
                            disabledBackgroundColor: AppColors.forest.withValues(alpha: 0.7),
                            disabledForegroundColor: Colors.white,
                            elevation: 2,
                            textStyle: textTheme.titleMedium?.copyWith(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          onPressed: _checking ? null : _check,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_checking) ...[
                                const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(t.t(_checking ? 'maintenance.checking' : 'maintenance.check')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _signOut,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.charcoal.withValues(alpha: 0.6),
                            textStyle: textTheme.bodyMedium?.copyWith(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          child: Text(t.t('maintenance.signOut'), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
