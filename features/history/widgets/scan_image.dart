import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';

/// A saved scan photo on slate-100; shows the website's "Image Expired" when it can't load.
class ScanNetworkImage extends ConsumerWidget {
  const ScanNetworkImage({super.key, required this.url, this.large = false});

  final String url;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final expired = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.scanSearch, size: large ? 40 : 32, color: AppColors.slate400.withValues(alpha: 0.5)),
        SizedBox(height: large ? 12 : 8),
        Text(t.t('history.imageExpired').toUpperCase(),
            style: TextStyle(
                fontSize: large ? 12 : 10, fontWeight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 1)),
      ],
    );
    Widget failed(BuildContext _, Object _, StackTrace? _) => Center(child: expired);
    final uri = Uri.tryParse(url);
    // Demo-mode photos come from the app bundle (asset:) or the phone (file:).
    final Widget image = switch (uri?.scheme) {
      _ when url.isEmpty => Center(child: expired),
      'asset' => Image.asset(uri!.path.replaceFirst('/', ''),
          fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: failed),
      'file' => Image.file(File.fromUri(uri!),
          fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: failed),
      _ => Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: failed),
    };
    return ColoredBox(color: AppColors.slate100, child: image);
  }
}
