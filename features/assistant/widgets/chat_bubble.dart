import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../auth/auth_controller.dart';
import '../assistant_controller.dart';
import 'waveform.dart';

/// One chat message. User messages sit on the right, AI messages on the left (the website
/// fixes the row direction to LTR); the text inside follows the assistant's language.
class ChatBubble extends ConsumerWidget {
  const ChatBubble({super.key, required this.message, required this.texts, required this.onOpenImage});

  final ChatMessage message;
  final Translations texts;
  final ValueChanged<String> onOpenImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDirection = texts.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final width = MediaQuery.sizeOf(context).width;
    if (message.sender == ChatSender.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.9 * 0.85),
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.earth,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 15, offset: Offset(0, 10))],
          ),
          child: switch (message.kind) {
            ChatKind.image => GestureDetector(
                onTap: () => onOpenImage(message.path!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Image.file(File(message.path!), fit: BoxFit.cover),
                  ),
                ),
              ),
            ChatKind.audio => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.text ?? '', textDirection: _directionOf(message.text ?? '', textDirection), style: _userText),
                  const SizedBox(height: 8),
                  _VoiceNote(path: message.path!),
                ],
              ),
            ChatKind.text => Text(message.text ?? '', textDirection: _directionOf(message.text ?? '', textDirection), style: _userText),
          },
        ),
      );
    }

    const aiStyle = TextStyle(color: AppColors.sand, fontSize: 14, height: 1.6);
    final Widget content;
    if (message.isGreeting) {
      final name = (ref.watch(authControllerProvider.select((s) => s.user?.name)) ?? '').trim();
      final shown = name.isEmpty ? texts.t('assistant.defaultName') : name;
      final parts = texts.t('assistant.greeting').split('{{name}}');
      content = Text.rich(
        TextSpan(children: [
          TextSpan(text: parts.first),
          TextSpan(text: shown, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
          if (parts.length > 1) TextSpan(text: parts.sublist(1).join()),
        ]),
        textDirection: textDirection,
        style: aiStyle,
      );
    } else {
      final text = message.key != null ? texts.t('assistant.${message.key}') : (message.text ?? '');
      // Translated replies follow the panel's language; stored text keeps its own direction.
      final direction = message.key != null ? textDirection : _directionOf(text, textDirection);
      content = Text(text, textDirection: direction, style: aiStyle);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: width * 0.9 * 0.9),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: content,
      ),
    );
  }

  static const _userText = TextStyle(color: AppColors.forest, fontSize: 14, fontWeight: FontWeight.w700);
}

/// Play/pause for a sent voice note (the website uses the browser's audio controls).
class _VoiceNote extends ConsumerWidget {
  const _VoiceNote({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(assistantControllerProvider.select((s) => s.playingPath == path));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          onTap: () => ref.read(assistantControllerProvider.notifier).togglePlayback(path),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.forest, shape: BoxShape.circle),
            child: Icon(playing ? LucideIcons.pause : LucideIcons.play, size: 16, color: AppColors.gold),
          ),
        ),
        const SizedBox(width: 8),
        Waveform(animate: playing, height: 20),
      ],
    );
  }
}

final _rtlScript = RegExp('[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');

/// Direction of a message's own text: an English message stays left-to-right in the
/// Urdu panel (otherwise its trailing "..." jumps to the start), and Urdu stays right-to-left.
TextDirection _directionOf(String text, TextDirection fallback) {
  if (_rtlScript.hasMatch(text)) return TextDirection.rtl;
  if (RegExp('[A-Za-z]').hasMatch(text)) return TextDirection.ltr;
  return fallback;
}
