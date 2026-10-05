import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/date_format.dart';
import '../../core/errors.dart';
import '../../core/i18n/translations.dart';
import '../../core/theme.dart';
import '../../core/widgets/toast.dart';
import '../auth/auth_controller.dart';
import '../report/report_builder.dart';
import '../report/report_service.dart';
import 'data/scan_analysis_repository.dart';
import 'device/photo_picker.dart';
import 'scan_flow_controller.dart';
import 'scan_kind.dart';
import 'widgets/analyzing_view.dart';
import 'widgets/disease_results.dart';
import 'widgets/seed_results.dart';
import 'widgets/upload_card.dart';
import '../../core/layout.dart';

/// Seed Intelligence and Disease Intelligence: upload → analyzing → results.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key, required this.kind});

  final ScanKind kind;

  Future<void> _start(BuildContext context, WidgetRef ref, PhotoSource source) async {
    final t = ref.read(trProvider);
    final result = await ref.read(scanFlowProvider(kind).notifier).start(source);
    if (!context.mounted) return;
    switch (result.outcome) {
      case ScanStartOutcome.pickFailed:
        showToast(context, t.t('scan.app.cameraUnavailable'), type: ToastType.error);
      case ScanStartOutcome.failed:
        showToast(context, describeError(result.error!, t), type: ToastType.error);
      case ScanStartOutcome.ok:
      case ScanStartOutcome.cancelled:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final flow = ref.watch(scanFlowProvider(kind));
    final p = kind.prefix;
    return ListView(
      key: const Key('scanScroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, pageBottomPadding),
      children: [
        Text(t.t('$p.title'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
        const SizedBox(height: 4),
        Text(t.t('$p.subtitle'),
            style: TextStyle(fontSize: 14, color: AppColors.charcoal.withValues(alpha: 0.7))),
        if (flow.phase == ScanPhase.complete) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.sand,
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.earth, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                onPressed: () => ref.read(scanFlowProvider(kind).notifier).reset(),
                icon: const Icon(LucideIcons.refreshCcw, size: 16),
                label: Text(t.t('seed.newAnalysis')),
              ),
              _DownloadReportButton(kind: kind, imagePath: flow.imagePath, analysis: flow.analysis!),
            ],
          ),
        ],
        const SizedBox(height: 24),
        switch (flow.phase) {
          ScanPhase.idle => UploadCard(kind: kind, onPick: (source) => _start(context, ref, source)),
          ScanPhase.analyzing => AnalyzingView(kind: kind, imagePath: flow.imagePath),
          ScanPhase.complete => switch (flow.analysis!) {
              SeedAnalysis a => SeedResults(imagePath: flow.imagePath, analysis: a),
              DiseaseAnalysis a => DiseaseResults(imagePath: flow.imagePath, analysis: a),
            },
        },
      ],
    );
  }
}

/// Builds the PDF report and opens the share sheet (the website used window.print()).
class _DownloadReportButton extends ConsumerStatefulWidget {
  const _DownloadReportButton({required this.kind, required this.imagePath, required this.analysis});

  final ScanKind kind;
  final String? imagePath;
  final ScanAnalysis analysis;

  @override
  ConsumerState<_DownloadReportButton> createState() => _DownloadReportButtonState();
}

class _DownloadReportButtonState extends ConsumerState<_DownloadReportButton> {
  bool _busy = false;

  Future<void> _download() async {
    final t = ref.read(trProvider);
    final bundles = ref.read(translationBundlesProvider);
    final timezone = ref.read(authControllerProvider).user?.timezone ?? 'UTC';
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final bytes = await buildScanReport(
        kind: widget.kind,
        analysis: widget.analysis,
        t: t,
        english: Translations('en', bundles['en']!),
        imageBytes: await ref.read(reportImageLoaderProvider)(widget.imagePath),
        generatedAt: formatDate(now.toUtc(), timezone),
        fonts: await ref.read(reportFontsLoaderProvider)(t.languageCode),
      );
      await ref.read(reportSharerProvider).share(bytes, reportFileName(widget.kind, now));
    } on Object {
      if (mounted) showToast(context, t.t('scan.app.shareFailed'), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    return FilledButton.icon(
      key: const Key('downloadReport'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        disabledBackgroundColor: AppColors.forest.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
      ),
      onPressed: _busy ? null : _download,
      icon: _busy
          ? const SizedBox.square(
              dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(LucideIcons.download, size: 16),
      label: Text(t.t('seed.downloadReport')),
    );
  }
}
