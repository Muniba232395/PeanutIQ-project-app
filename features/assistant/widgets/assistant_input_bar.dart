import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/toast.dart';
import '../../scan/device/photo_picker.dart';
import '../assistant_controller.dart';
import 'robot_face.dart';
import 'waveform.dart';

/// The panel's bottom section: text field, then the action pill (mic / camera / gallery /
/// live-listening / robot) or the review pill (discard / preview / send).
class AssistantInputBar extends ConsumerStatefulWidget {
  const AssistantInputBar({super.key, required this.texts, required this.onOpenImage});

  final Translations texts;
  final ValueChanged<String> onOpenImage;

  @override
  ConsumerState<AssistantInputBar> createState() => _AssistantInputBarState();
}

class _AssistantInputBarState extends ConsumerState<AssistantInputBar> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  AssistantController get _ctl => ref.read(assistantControllerProvider.notifier);

  void _send() {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    setState(() {});
    _ctl.sendText(text);
  }

  Future<void> _mic() async {
    final ok = await _ctl.toggleRecording();
    if (!ok && mounted) showToast(context, widget.texts.t('assistant.micDenied'), type: ToastType.error);
  }

  Future<void> _photo(PhotoSource source) async {
    final ok = await _ctl.pickPhoto(source);
    if (!ok && mounted) showToast(context, widget.texts.t('assistant.cameraError'), type: ToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    final t = widget.texts;
    final direction = t.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final recording = state.mode == InputMode.recording;
    final reviewing = state.mode == InputMode.reviewingAudio || state.mode == InputMode.reviewingImage;
    final hasText = _text.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.forest,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!recording && !reviewing) ...[
            Container(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 4, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Directionality(
                textDirection: direction,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('assistantInput'),
                        controller: _text,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        cursorColor: AppColors.gold,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: false,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          hintText: t.t('assistant.placeholder'),
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: hasText
                          ? InkResponse(
                              key: const Key('assistantSend'),
                              onTap: _send,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                child: Transform.flip(
                                  flipX: t.isRtl,
                                  child: const Icon(LucideIcons.send, size: 16, color: AppColors.forest),
                                ),
                              ),
                            )
                          : const SizedBox(width: 0, height: 40),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (reviewing) _reviewPill(state, t) else _actionPill(recording, t),
        ],
      ),
    );
  }

  Widget _circle({
    required Key key,
    required double size,
    required Color color,
    required Widget child,
    required VoidCallback onTap,
    Color? border,
    List<BoxShadow>? shadow,
  }) =>
      InkResponse(
        key: key,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border),
            boxShadow: shadow,
          ),
          child: child,
        ),
      );

  Widget _actionPill(bool recording, Translations t) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _circle(
            key: const Key('assistantMic'),
            size: 48,
            color: recording ? AppColors.gold : AppColors.sand,
            shadow: recording ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 20)] : null,
            onTap: _mic,
            child: Icon(recording ? LucideIcons.square : LucideIcons.mic, size: 20, color: AppColors.forest),
          ),
          if (!recording) ...[
            const SizedBox(width: 6),
            _circle(
              key: const Key('assistantCamera'),
              size: 40,
              color: Colors.black.withValues(alpha: 0.2),
              border: Colors.white.withValues(alpha: 0.2),
              onTap: () => _photo(PhotoSource.camera),
              child: const Icon(LucideIcons.camera, size: 16, color: AppColors.earth),
            ),
            const SizedBox(width: 6),
            _circle(
              key: const Key('assistantGallery'),
              size: 40,
              color: Colors.black.withValues(alpha: 0.2),
              border: Colors.white.withValues(alpha: 0.2),
              onTap: () => _photo(PhotoSource.gallery),
              child: const Icon(LucideIcons.image, size: 16, color: AppColors.earth),
            ),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: recording ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t.t('assistant.liveListening'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: recording ? AppColors.gold : AppColors.earth,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: recording ? 1 : 0.2,
                    child: FittedBox(fit: BoxFit.scaleDown, child: Waveform(animate: recording)),
                  ),
                ],
              ),
            ),
          ),
          // The small robot closes the panel, as on the website.
          _circle(
            key: const Key('assistantMiniRobot'),
            size: 48,
            color: Colors.white.withValues(alpha: 0.1),
            border: Colors.white.withValues(alpha: 0.3),
            onTap: () => ref.read(assistantControllerProvider.notifier).close(),
            child: const RobotFace(size: 28),
          ),
        ],
      ),
    );
  }

  Widget _reviewPill(AssistantState state, Translations t) {
    final image = state.previewImagePath;
    final audio = state.audioPath;
    final playing = audio != null && state.playingPath == audio;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _circle(
            key: const Key('assistantDiscard'),
            size: 56,
            color: AppColors.terracotta,
            onTap: _ctl.discard,
            child: const Icon(LucideIcons.trash2, size: 24, color: AppColors.sand),
          ),
          Expanded(
            child: Center(
              child: image != null
                  ? GestureDetector(
                      onTap: () => widget.onOpenImage(image),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(image), height: 48, width: 96, fit: BoxFit.cover),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _circle(
                              key: const Key('assistantPlay'),
                              size: 32,
                              color: AppColors.forest,
                              onTap: () {
                                if (audio != null) _ctl.togglePlayback(audio);
                              },
                              child: Icon(playing ? LucideIcons.pause : LucideIcons.play, size: 16, color: AppColors.gold),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(t.t('assistant.reviewReady'),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.earth, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        if (playing) const Opacity(opacity: 0.7, child: Waveform()),
                      ],
                    ),
            ),
          ),
          _circle(
            key: const Key('assistantSendReview'),
            size: 56,
            color: AppColors.gold,
            shadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 20)],
            onTap: _ctl.sendReview,
            child: const Icon(LucideIcons.send, size: 24, color: AppColors.forest),
          ),
        ],
      ),
    );
  }
}
