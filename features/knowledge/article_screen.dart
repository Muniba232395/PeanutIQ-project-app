import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/date_format.dart';
import '../../core/i18n/translations.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/section_card.dart';
import 'data/article.dart';
import 'knowledge_providers.dart';
import '../../core/layout.dart';

/// The website's article view (selectedArticle).
class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final articles = ref.watch(articlesProvider);
    Article? article;
    for (final a in articles.value ?? const <Article>[]) {
      if (a.id == id) article = a;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = InkWell(
      onTap: () => context.canPop() ? context.pop() : context.go(Routes.knowledge),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(rtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft, size: 16, color: AppColors.gray500),
            const SizedBox(width: 8),
            Flexible(
              child: Text(t.t('kb.back'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray500)),
            ),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, pageBottomPadding),
      children: [
        SectionCard(
          child: switch (articles) {
            AsyncLoading() when article == null => const SectionLoading(),
            _ when article == null => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  back,
                  const SizedBox(height: 24),
                  Text(t.t('kb.app.notFound'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.gray600)),
                ],
              ),
            _ => _ArticleBody(article: article, back: back),
          },
        ),
      ],
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article, required this.back});

  final Article article;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    const meta = TextStyle(fontSize: 14, color: AppColors.gray500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: back),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(6)),
              child: Text(article.category.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.bookOpen, size: 16, color: AppColors.gray500),
                const SizedBox(width: 4),
                Flexible(child: Text(article.author, style: meta)),
              ],
            ),
            Text(formatDueDate(article.createdAt), textDirection: TextDirection.ltr, style: meta),
          ],
        ),
        const SizedBox(height: 16),
        Text(article.title,
            style: const TextStyle(fontSize: 30, height: 1.2, fontWeight: FontWeight.w900, color: AppColors.gray900)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsetsDirectional.only(start: 16),
          decoration: const BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: AppColors.gray200, width: 4)),
          ),
          child: Text(article.excerpt,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: AppColors.gray600)),
        ),
        const SizedBox(height: 32),
        Text(article.content, style: const TextStyle(fontSize: 18, height: 2, color: AppColors.gray800)),
      ],
    );
  }
}
