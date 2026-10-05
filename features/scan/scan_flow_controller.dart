import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/translations.dart';
import '../dashboard/dashboard_providers.dart';
import '../history/history_providers.dart';
import 'data/scan_analysis_repository.dart';
import 'data/scan_repository.dart';
import 'device/photo_picker.dart';
import 'scan_kind.dart';

enum ScanPhase { idle, analyzing, complete }

enum ScanStartOutcome { ok, cancelled, pickFailed, failed }

class ScanStartResult {
  const ScanStartResult(this.outcome, [this.error]);

  final ScanStartOutcome outcome;

  /// Why the analysis failed (not a seed/crop photo, AI busy, offline...), for describeError.
  final Object? error;
}

class ScanFlowState {
  const ScanFlowState(this.phase, [this.imagePath, this.analysis]);

  const ScanFlowState.idle() : this(ScanPhase.idle);

  final ScanPhase phase;
  final String? imagePath;

  /// Set when complete.
  final ScanAnalysis? analysis;
}

/// One flow per kind. Not auto-disposed, so switching tabs mid-analysis doesn't lose it.
class ScanFlowController extends Notifier<ScanFlowState> {
  ScanFlowController(this.kind);

  final ScanKind kind;

  @override
  ScanFlowState build() => const ScanFlowState.idle();

  Future<ScanStartResult> start(PhotoSource source) async {
    final String? path;
    try {
      path = await ref.read(photoPickerProvider).pick(source);
    } on Object {
      return const ScanStartResult(ScanStartOutcome.pickFailed);
    }
    if (path == null) return const ScanStartResult(ScanStartOutcome.cancelled);

    state = ScanFlowState(ScanPhase.analyzing, path);
    final ScanAnalysis analysis;
    try {
      analysis = await ref
          .read(scanRepositoryProvider)
          .analyze(kind, path, ref.read(localeControllerProvider));
    } on Object catch (e) {
      // No fake results: back to the upload card, and the screen explains what went wrong.
      if (state.phase == ScanPhase.analyzing && state.imagePath == path) state = const ScanFlowState.idle();
      return ScanStartResult(ScanStartOutcome.failed, e);
    }
    // A reset during analysis wins.
    if (state.phase == ScanPhase.analyzing && state.imagePath == path) {
      state = ScanFlowState(ScanPhase.complete, path, analysis);
    }
    // The backend added the scan to History and logged an activity; show both next time.
    ref.invalidate(historyProvider);
    ref.invalidate(activitiesProvider);
    return const ScanStartResult(ScanStartOutcome.ok);
  }

  void reset() => state = const ScanFlowState.idle();
}

final scanFlowProvider =
    NotifierProvider.family<ScanFlowController, ScanFlowState, ScanKind>(ScanFlowController.new);
