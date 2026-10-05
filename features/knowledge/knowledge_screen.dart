import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/errors.dart';
import '../../core/i18n/translations.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/section_card.dart';
import 'data/kb_ask_ai_repository.dart';
import 'knowledge_providers.dart';
import 'widgets/ai_answer_panel.dart';
import 'widgets/article_card.dart';
import 'widgets/category_chips.dart';
import 'widgets/kb_search_box.dart';
import '../../core/layout.dart';

enum _AiState { idle, thinking, complete }

/// Port of KnowledgeBase.jsx for farmers (read-only; see the Phase 5 plan's rulings).
class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  final _query = TextEditingController();
  int? _categoryId;
  bool _aiMode = false;
  _AiState _aiState = _AiState.idle;
  String? _answer;
  int _askCount = 0;

  @override
  void initState() {
    super.initState();
    // Category names are per language, so the website resets the filter on a language change.
    ref.listenManual(localeControllerProvider, (_, _) => setState(() => _categoryId = null));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _ask(String query) async {
    if (!_aiMode || query.trim().isEmpty) return;
    final t = ref.read(trProvider);
    final ask = ++_askCount;
    setState(() => _aiState = _AiState.thinking);
    String answer;
    try {
      answer = await ref.read(kbAskAiRepositoryProvider).ask(query, t);
    } on Object catch (e) {
      answer = describeError(e, t);
    }
    if (!mounted || ask != _askCount) return;
    setState(() {
      _answer = answer;
      _aiState = _AiState.complete;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final articles = ref.watch(articlesProvider);
    final categories = kbCategories(t);
    final all = articles.value ?? const [];
    String? categoryName;
    for (final c in categories) {
      if (c.id == _categoryId) categoryName = c.name;
    }
    return RefreshIndicator(
      color: AppColors.forest,
      onRefresh: () => ref.refresh(articlesProvider.future).then((_) {}, onError: (_) {}),
      child: ListView(
        key: const Key('kbScroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, pageBottomPadding),
        children: [
          Text(t.t('kb.title'),
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.slate900, letterSpacing: -0.75)),
          const SizedBox(height: 8),
          Text(t.t('kb.subtitle'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate600)),
          const SizedBox(height: 16),
          KbSearchBox(
            controller: _query,
            aiMode: _aiMode,
            onModeChanged: (ai) => setState(() => _aiMode = ai),
            onChanged: (_) => setState(() {}),
            onSubmitted: _ask,
          ),
          if (_aiMode && _aiState != _AiState.idle) ...[
            const SizedBox(height: 16),
            AiAnswerPanel(
              thinking: _aiState == _AiState.thinking,
              answer: _answer,
              onClose: () => setState(() => _aiState = _AiState.idle),
            ),
          ],
          const SizedBox(height: 24),
          CategoryChips(
            allLabel: t.t('kb.allArticles'),
            allCount: all.length,
            categories: [
              for (final c in categories) (id: c.id, name: c.name, count: all.where((a) => a.category == c.name).length),
            ],
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: 16),
          switch (articles) {
            AsyncData(:final value) => () {
                final filtered = filterArticles(value, query: _query.text, category: categoryName);
                if (filtered.isEmpty) return _Empty(t: t);
                return Column(
                  children: [
                    for (var i = 0; i < filtered.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      ArticleCard(
                        article: filtered[i],
                        onTap: () => context.go('${Routes.knowledge}/${filtered[i].id}'),
                      ),
                    ],
                  ],
                );
              }(),
            AsyncError() => SectionCard(child: SectionError(onRetry: () => ref.invalidate(articlesProvider))),
            _ => const SectionLoading(),
          },
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Icon(LucideIcons.bookOpen, size: 48, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(t.t('kb.noArticles'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.slate900)),
          const SizedBox(height: 4),
          Text(t.t('kb.tryAdjusting'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.slate500)),
        ],
      ),
    );
  }
}
