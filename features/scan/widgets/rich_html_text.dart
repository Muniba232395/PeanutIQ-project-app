import 'package:flutter/material.dart';

/// Renders the small HTML subset used in the translation files (disease.pathologyDesc):
/// `<strong>` for bold and `<span dir="ltr">` around Latin names. Nothing else is needed.
class RichHtmlText extends StatelessWidget {
  const RichHtmlText(this.html, {super.key, this.style});

  final String html;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: parseSimpleHtml(html)), style: style);
}

final _token = RegExp(r'<(/?)(strong|b|span)([^>]*)>', caseSensitive: false);

List<InlineSpan> parseSimpleHtml(String html) {
  final spans = <InlineSpan>[];
  var bold = 0;
  var index = 0;
  void addText(String text) {
    if (text.isEmpty) return;
    spans.add(TextSpan(
      text: text.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>'),
      style: bold > 0 ? const TextStyle(fontWeight: FontWeight.w700) : null,
    ));
  }

  for (final match in _token.allMatches(html)) {
    addText(html.substring(index, match.start));
    final closing = match.group(1) == '/';
    final tag = match.group(2)!.toLowerCase();
    if (tag != 'span') bold = (bold + (closing ? -1 : 1)).clamp(0, 99);
    index = match.end;
  }
  addText(html.substring(index));
  return spans;
}
