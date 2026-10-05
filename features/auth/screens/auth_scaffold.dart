import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/language_switch.dart';

/// The website's AuthLayout at phone width: sand page, green logo and wordmark at the
/// top-start, language pill at the top-end, form centred below. Everything scrolls
/// together so large text or an open keyboard never overflows.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  static const _topBarExtent = 72.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const _TopBar(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - _topBarExtent),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ConstrainedBox(
                        // max-w-[360px] in the website's forms
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppLogo(size: 28, iconColor: AppColors.forest, leafColor: AppColors.forest),
        SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Wordmark(fontSize: 20, color: AppColors.charcoal, accent: AppColors.forest),
            ),
          ),
        ),
        SizedBox(width: 12),
        LanguageSwitch(),
      ],
    );
  }
}

/// text-2xl font-extrabold text-[#324329] tracking-tight
TextStyle? authTitleStyle(TextTheme textTheme) => textTheme.headlineSmall?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: AppColors.authButton,
      letterSpacing: -0.6,
    );

/// text-sm text-gray-500 font-medium
TextStyle? authSubtitleStyle(TextTheme textTheme) => textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.gray500,
    );

/// text-[13px] text-gray-500 font-medium
TextStyle? authFooterStyle(TextTheme textTheme) => textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.gray500,
    );
