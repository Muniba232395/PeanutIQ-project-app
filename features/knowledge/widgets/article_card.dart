import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/date_format.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../data/article.dart';

class ArticleCard extends ConsumerWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 20, spreadRadius: -4, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.earth),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Decorative quarter circle in the top-end corner.
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.05),
                    borderRadius: const BorderRadiusDirectional.only(bottomStart: Radius.circular(128))
                        .resolve(Directionality.of(context)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(article.category.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.bookOpen, size: 16, color: AppColors.forest.withValues(alpha: 0.7)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(article.author,
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.slate100),
                          ),
                          child: Text(formatDueDate(article.createdAt),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate400)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 20, height: 1.35, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                    const SizedBox(height: 12),
                    Text(article.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.slate600)),
                    const SizedBox(height: 24),
                    Divider(height: 1, color: AppColors.earth.withValues(alpha: 0.6)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(t.t('kb.app.readArticle'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest)),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.forest.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                              size: 16, color: AppColors.forest),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
