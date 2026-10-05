import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/i18n/translations.dart';
import '../assistant_controller.dart' show AssistantTiming, assistantTimingProvider;

/// One earlier message, sent as context.
class AiTurn {
  const AiTurn(this.role, this.text);

  /// 'user' or 'model'.
  final String role;
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
}

class AiReply {
  const AiReply(this.reply, {this.transcript});

  final String reply;

  /// For voice messages: what the assistant heard.
  final String? transcript;
}

/// Where the assistant's replies come from.
abstract interface class AssistantBrain {
  Future<AiReply> chat(String message, {required String language, required List<AiTurn> history});

  /// A photo or a voice message (an .m4a recording).
  Future<AiReply> media(String path, {required bool isAudio, required String language, required List<AiTurn> history});
}

/// The real assistant: the backend's Gemini endpoints.
class ApiAssistantBrain implements AssistantBrain {
  ApiAssistantBrain(this._api);

  final ApiClient _api;

  /// The backend retries busy models for up to 45 s.
  static const timeout = Duration(seconds: 60);

  @override
  Future<AiReply> chat(String message, {required String language, required List<AiTurn> history}) async {
    final data = await _api.post('/assistant/chat', timeout: timeout, data: {
      'message': message,
      'language': language,
      'history': [for (final turn in history) turn.toJson()],
    }) as Map<String, dynamic>;
    return AiReply(data['reply'] as String);
  }

  @override
  Future<AiReply> media(String path,
      {required bool isAudio, required String language, required List<AiTurn> history}) async {
    final data = await _api.postMultipart(
      '/assistant/media',
      fields: {'language': language, 'history': jsonEncode([for (final turn in history) turn.toJson()])},
      filePath: path,
      contentType: isAudio ? 'audio/mp4' : _imageType(path),
      timeout: timeout,
    ) as Map<String, dynamic>;
    final transcript = (data['transcript'] as String?)?.trim();
    return AiReply(data['reply'] as String, transcript: transcript == null || transcript.isEmpty ? null : transcript);
  }

  static String _imageType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

/// Demo mode (no backend): the website's canned replies, after its delays.
class CannedAssistantBrain implements AssistantBrain {
  CannedAssistantBrain(this._bundles, this._timing);

  final Map<String, Map<String, dynamic>> _bundles;
  final AssistantTiming _timing;

  Translations _t(String language) =>
      Translations(language, _bundles[language] ?? _bundles['en']!, fallback: _bundles['en']);

  @override
  Future<AiReply> chat(String message, {required String language, required List<AiTurn> history}) async {
    await Future<void>.delayed(_timing.reply);
    return AiReply(_t(language).t('assistant.textReply'));
  }

  @override
  Future<AiReply> media(String path,
      {required bool isAudio, required String language, required List<AiTurn> history}) async {
    await Future<void>.delayed(isAudio ? _timing.reply : _timing.result);
    return AiReply(_t(language).t(isAudio ? 'assistant.textReply' : 'assistant.imageResult'));
  }
}

final assistantBrainProvider = Provider<AssistantBrain>((ref) => ref.watch(demoModeProvider)
    ? CannedAssistantBrain(ref.watch(translationBundlesProvider), ref.watch(assistantTimingProvider))
    : ApiAssistantBrain(ref.watch(apiClientProvider)));
