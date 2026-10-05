import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/i18n/translations.dart';

/// Knowledge Base "Ask AI".
abstract interface class KbAskAiRepository {
  Future<String> ask(String query, Translations t);
}

/// The real one: Gemini through the backend, which answers from the published articles.
class ApiKbAskAiRepository implements KbAskAiRepository {
  ApiKbAskAiRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> ask(String query, Translations t) async {
    final data = await _api.post('/knowledge/ask',
        timeout: const Duration(seconds: 60),
        data: {'query': query.trim(), 'language': t.languageCode}) as Map<String, dynamic>;
    return data['answer'] as String;
  }
}

/// Demo mode: the website's canned answers. After 2 seconds it picks one of three by keyword.
class CannedKbAskAiRepository implements KbAskAiRepository {
  const CannedKbAskAiRepository({this.delay = const Duration(seconds: 2)});

  final Duration delay;

  @override
  Future<String> ask(String query, Translations t) async {
    await Future<void>.delayed(delay);
    final q = query.toLowerCase();
    if (q.contains('leaf spot') || q.contains('بیماری') || q.contains('دھبے')) {
      return t.t('kb.aiResponses.disease');
    }
    if (q.contains('seed') || q.contains('sow') || q.contains('بیج')) {
      return t.t('kb.aiResponses.seed');
    }
    return t.t('kb.aiResponses.general');
  }
}

final kbAskAiRepositoryProvider = Provider<KbAskAiRepository>((ref) => ref.watch(demoModeProvider)
    ? const CannedKbAskAiRepository()
    : ApiKbAskAiRepository(ref.watch(apiClientProvider)));
