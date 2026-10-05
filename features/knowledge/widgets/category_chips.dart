import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// The website's category list at phone width: a sideways-scrolling row of chips with counts.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.allLabel,
    required this.allCount,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final String allLabel;
  final int allCount;
  final List<({int id, String name, int count})> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _Chip(
            key: const Key('kbCategory-all'),
            label: allLabel,
            count: allCount,
            active: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            _Chip(
              key: Key('kbCategory-${c.id}'),
              label: c.name,
              count: c.count,
              active: selectedId == c.id,
              onTap: () => onSelected(c.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.count, required this.active, required this.onTap});

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.forest : Colors.white,
      elevation: active ? 3 : 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? AppColors.forest : AppColors.earth),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.charcoal)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white : AppColors.earth,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.forest)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
