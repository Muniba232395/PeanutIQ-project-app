import 'package:flutter/material.dart';

import '../theme.dart';

/// Initials the way ui-avatars.com builds them for the website: parentheses and
/// non-Latin characters stripped, first letters of the first two words (or the first two
/// letters of a single word), uppercase. Urdu-only names fall back to their first letter;
/// empty names use the website's default "Farmer User".
String avatarInitials(String? name) {
  final raw = (name ?? '').trim();
  if (raw.isEmpty) return 'FU';
  final latin = raw
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'[^a-zA-Z ]'), '')
      .trim()
      .split(RegExp(r' +'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (latin.isEmpty) return raw.characters.first;
  if (latin.length == 1) return latin.first.substring(0, latin.first.length.clamp(1, 2)).toUpperCase();
  return (latin[0][0] + latin[1][0]).toUpperCase();
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 32});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.avatar, shape: BoxShape.circle),
      child: Text(
        avatarInitials(name),
        style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w500),
      ),
    );
  }
}
