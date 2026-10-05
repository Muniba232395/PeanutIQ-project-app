import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/i18n/translations.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/data/dashboard_repository.dart';
import '../scan/device/photo_picker.dart';
import 'data/assistant_brain.dart';
import 'device/audio_playback.dart';
import 'device/voice_recorder.dart';

enum ChatSender { user, ai }

enum ChatKind { text, image, audio }

enum InputMode { idle, recording, reviewingAudio, reviewingImage }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    this.kind = ChatKind.text,
    this.text,
    this.key,
    this.path,
    this.isGreeting = false,
  });

  final int id;
  final ChatSender sender;
  final ChatKind kind;

  /// Fixed text (user messages and text replies, resolved when sent, like the website).
  final String? text;

  /// An `assistant.*` key, rendered in the current assistant language (image replies).
  final String? key;

  /// Image or audio file.
  final String? path;
  final bool isGreeting;

  ChatMessage withKey(String newKey) =>
      ChatMessage(id: id, sender: sender, kind: kind, text: text, key: newKey, path: path, isGreeting: isGreeting);

  /// Fixed text instead of a key (a reply arriving in place of "Thinking...").
  ChatMessage withText(String newText) =>
      ChatMessage(id: id, sender: sender, kind: kind, text: newText, path: path, isGreeting: isGreeting);
}

class AssistantState {
  const AssistantState({
    this.open = false,
    this.language = 'en',
    this.messages = const [],
    this.mode = InputMode.idle,
    this.previewImagePath,
    this.audioPath,
    this.playingPath,
  });

  final bool open;

  /// The assistant's own language ('en' | 'ur'), separate from the app language.
  final String language;
  final List<ChatMessage> messages;
  final InputMode mode;
  final String? previewImagePath;
  final String? audioPath;
  final String? playingPath;

  AssistantState copyWith({
    bool? open,
    String? language,
    List<ChatMessage>? messages,
    InputMode? mode,
    String? Function()? previewImagePath,
    String? Function()? audioPath,
    String? Function()? playingPath,
  }) =>
      AssistantState(
        open: open ?? this.open,
        language: language ?? this.language,
        messages: messages ?? this.messages,
        mode: mode ?? this.mode,
        previewImagePath: previewImagePath == null ? this.previewImagePath : previewImagePath(),
        audioPath: audioPath == null ? this.audioPath : audioPath(),
        playingPath: playingPath == null ? this.playingPath : playingPath(),
      );
}

/// The website's canned reply delays.
class AssistantTiming {
  const AssistantTiming({
    this.reply = const Duration(milliseconds: 1500),
    this.analyzing = const Duration(milliseconds: 500),
    this.result = const Duration(milliseconds: 3500),
  });

  final Duration reply;

  /// "Analyzing image..." appears this long after sending a photo...
  final Duration analyzing;

  /// ...and becomes the result this long after sending.
  final Duration result;
}

final assistantTimingProvider = Provider<AssistantTiming>((ref) => const AssistantTiming());

/// Port of FloatingAgent's logic. Replies come from [AssistantBrain]: Gemini through the
/// backend, or the website's canned replies in demo mode.
class AssistantController extends Notifier<AssistantState> {
  int _nextId = 2;
  StreamSubscription<void>? _playbackDone;

  @override
  AssistantState build() {
    ref.onDispose(() => _playbackDone?.cancel());
    return const AssistantState(messages: [ChatMessage(id: 1, sender: ChatSender.ai, isGreeting: true)]);
  }

  /// Translations for the assistant's own language.
  Translations get texts {
    final bundles = ref.read(translationBundlesProvider);
    return Translations(state.language, bundles[state.language]!, fallback: bundles['en']);
  }

  void open() => state = state.copyWith(open: true);

  void close() => state = state.copyWith(open: false);

  void toggleLanguage() => state = state.copyWith(language: state.language == 'ur' ? 'en' : 'ur');

  void resetLanguage() => state = state.copyWith(language: 'en');

  Future<void> sendText(String text) async {
    final message = text.trim();
    if (message.isEmpty) return;
    final language = state.language;
    final history = _history();
    _log('Text Interactions', message.length > 30 ? '${message.substring(0, 30)}...' : message);
    _add(ChatMessage(id: _nextId++, sender: ChatSender.user, text: message));
    final pending = _addPending('thinking');
    await _answer(pending, () => _brain.chat(message, language: language, history: history));
  }

  /// Starts or stops recording. Returns false if the microphone permission was refused.
  Future<bool> toggleRecording() async {
    final recorder = ref.read(voiceRecorderProvider);
    if (state.mode == InputMode.recording) {
      final path = await recorder.stop();
      state = state.copyWith(mode: InputMode.reviewingAudio, audioPath: () => path);
      return true;
    }
    if (state.mode != InputMode.idle) return true;
    if (!await recorder.hasPermission()) return false;
    await recorder.start();
    state = state.copyWith(mode: InputMode.recording);
    return true;
  }

  /// Returns false when the camera or gallery couldn't be opened. Cancelling is not an error.
  Future<bool> pickPhoto(PhotoSource source) async {
    try {
      final path = await ref.read(photoPickerProvider).pick(source);
      if (path != null) {
        state = state.copyWith(mode: InputMode.reviewingImage, previewImagePath: () => path);
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> discard() async {
    await _stopPlayback();
    state = state.copyWith(mode: InputMode.idle, previewImagePath: () => null, audioPath: () => null);
  }

  Future<void> sendReview() async {
    final image = state.previewImagePath;
    final audio = state.audioPath;
    final t = texts;
    final language = state.language;
    final history = _history();
    await _stopPlayback();
    state = state.copyWith(mode: InputMode.idle, previewImagePath: () => null, audioPath: () => null);

    if (image != null) {
      _log('Query Copilot', 'Sent an image for analysis');
      _add(ChatMessage(id: _nextId++, sender: ChatSender.user, kind: ChatKind.image, path: image));
      final pending = _addPending('analyzingImage');
      await _answer(pending, () => _brain.media(image, isAudio: false, language: language, history: history));
    } else if (audio != null) {
      _log('Voice Advisory', 'Completed');
      final voiceId = _nextId++;
      _add(ChatMessage(
        id: voiceId,
        sender: ChatSender.user,
        kind: ChatKind.audio,
        path: audio,
        text: t.t('assistant.voiceSent'),
      ));
      final pending = _addPending('thinking');
      await _answer(pending, () async {
        final reply = await _brain.media(audio, isAudio: true, language: language, history: history);
        // Show what the assistant heard in place of "Voice message sent".
        if (reply.transcript != null) _replace(voiceId, (m) => m.withText('🎤 ${reply.transcript}'));
        return reply;
      });
    }
  }

  AssistantBrain get _brain => ref.read(assistantBrainProvider);

  /// The last few exchanged texts, as context for the next reply.
  List<AiTurn> _history() => [
        for (final m in state.messages)
          if (!m.isGreeting && m.key == null && m.kind == ChatKind.text && (m.text ?? '').isNotEmpty)
            AiTurn(m.sender == ChatSender.user ? 'user' : 'model', m.text!),
      ].reversed.take(10).toList().reversed.toList();

  /// An AI bubble showing an `assistant.*` key ("Thinking...") until the reply replaces it.
  int _addPending(String key) {
    final id = _nextId++;
    _add(ChatMessage(id: id, sender: ChatSender.ai, key: key));
    return id;
  }

  /// Replaces the pending bubble with the reply, or with an error in the assistant's language.
  /// The reply still arrives if the panel was closed meanwhile.
  Future<void> _answer(int pendingId, Future<AiReply> Function() ask) async {
    try {
      final reply = await ask();
      _replace(pendingId, (m) => m.withText(reply.reply));
    } on Object catch (e) {
      _replace(pendingId, (m) => m.withText(describeError(e, texts)));
    }
  }

  void _replace(int id, ChatMessage Function(ChatMessage) change) {
    state = state.copyWith(messages: [for (final m in state.messages) m.id == id ? change(m) : m]);
  }

  Future<void> togglePlayback(String path) async {
    final player = ref.read(audioPlaybackProvider);
    if (state.playingPath == path) {
      await _stopPlayback();
      return;
    }
    _playbackDone ??= player.completed.listen((_) => state = state.copyWith(playingPath: () => null));
    await player.play(path);
    state = state.copyWith(playingPath: () => path);
  }

  Future<void> _stopPlayback() async {
    if (state.playingPath == null) return;
    await ref.read(audioPlaybackProvider).pause();
    state = state.copyWith(playingPath: () => null);
  }

  void _add(ChatMessage message) => state = state.copyWith(messages: [...state.messages, message]);

  /// Best effort, like the website: failures are ignored.
  void _log(String action, String details) {
    unawaited(() async {
      try {
        await ref.read(dashboardRepositoryProvider).logActivity(action, details);
        ref.invalidate(activitiesProvider);
      } on Object {
        // ignore
      }
    }());
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(AssistantController.new);
