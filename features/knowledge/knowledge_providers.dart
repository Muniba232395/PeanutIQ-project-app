import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/translations.dart';
import '../auth/auth_controller.dart';
import 'data/article.dart';
import 'data/knowledge_repository.dart';

final articlesProvider = FutureProvider<List<Article>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(knowledgeRepositoryProvider).fetchPublished();
});

/// The website's filter: category must match exactly (null = all), and the query must
/// appear in the title or excerpt, ignoring case.
List<Article> filterArticles(List<Article> articles, {required String query, String? category}) {
  final q = query.toLowerCase();
  return [
    for (final a in articles)
      if ((category == null || a.category == category) &&
          (a.title.toLowerCase().contains(q) || a.excerpt.toLowerCase().contains(q)))
        a,
  ];
}

/// kb.categories in the current language: [{id, name, count}, ...].
List<({int id, String name})> kbCategories(Translations t) {
  final raw = t.raw('kb.categories');
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map) (id: (item['id'] as num).toInt(), name: '${item['name']}'),
  ];
}
