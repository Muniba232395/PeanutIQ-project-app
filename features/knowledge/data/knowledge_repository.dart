import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'article.dart';

class KnowledgeRepository {
  KnowledgeRepository(this._api);

  final ApiClient _api;

  /// Farmers only ever get published articles (the backend enforces this too).
  Future<List<Article>> fetchPublished() async {
    final data = await _api.get('/knowledge/articles') as List<dynamic>;
    return [for (final item in data) Article.fromJson(item as Map<String, dynamic>)];
  }
}

final knowledgeRepositoryProvider =
    Provider<KnowledgeRepository>((ref) => KnowledgeRepository(ref.watch(apiClientProvider)));
