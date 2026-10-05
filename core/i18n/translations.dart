import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';

const supportedLanguageCodes = ['en', 'ur'];

typedef TranslationBundles = Map<String, Map<String, dynamic>>;

/// Reads the website's i18next JSON: nested keys, `{{name}}` placeholders,
/// and English as the fallback language.
class Translations {
  Translations(this.languageCode, this._strings, {this._fallback});

  final String languageCode;
  final Map<String, dynamic> _strings;
  final Map<String, dynamic>? _fallback;

  static final _placeholder = RegExp(r'\{\{\s*(\w+)\s*\}\}');

  bool get isRtl => languageCode == 'ur';

  /// The raw value at a dot path (a string, list or map), or null.
  Object? raw(String key) {
    final fallback = _fallback;
    return _lookup(_strings, key) ?? (fallback == null ? null : _lookup(fallback, key));
  }

  String t(String key, {Map<String, Object?> args = const {}, String? fallback}) {
    final value = raw(key);
    final text = value is String ? value : (fallback ?? key);
    if (args.isEmpty) return text;
    return text.replaceAllMapped(_placeholder, (match) {
      final name = match.group(1)!;
      return args.containsKey(name) ? '${args[name] ?? ''}' : match.group(0)!;
    });
  }

  static Object? _lookup(Map<String, dynamic> map, String key) {
    Object? node = map;
    for (final part in key.split('.')) {
      if (node is Map && node.containsKey(part)) {
        node = node[part];
      } else {
        return null;
      }
    }
    return node;
  }
}

Future<TranslationBundles> loadTranslationBundles([AssetBundle? bundle]) async {
  final source = bundle ?? rootBundle;
  return {
    for (final code in supportedLanguageCodes)
      code: jsonDecode(await source.loadString('assets/translations/$code.json'))
          as Map<String, dynamic>,
  };
}

/// The server stores 'english' | 'urdu'. The website sometimes sent capitalised forms.
String? languageCodeFromServer(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'urdu':
    case 'ur':
      return 'ur';
    case 'english':
    case 'en':
      return 'en';
    default:
      return null;
  }
}

String serverLanguageFromCode(String code) => code == 'ur' ? 'urdu' : 'english';

class LocaleController extends Notifier<String> {
  @override
  String build() {
    final saved = ref.watch(appPrefsProvider).language;
    return supportedLanguageCodes.contains(saved) ? saved! : 'en';
  }

  bool get hasSavedPreference => ref.read(appPrefsProvider).language != null;

  Future<void> setLanguage(String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    state = code;
    await ref.read(appPrefsProvider).setLanguage(code);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, String>(LocaleController.new);

final translationBundlesProvider = Provider<TranslationBundles>(
  (ref) => throw UnimplementedError('Override translationBundlesProvider in main()'),
);

final trProvider = Provider<Translations>((ref) {
  final code = ref.watch(localeControllerProvider);
  final bundles = ref.watch(translationBundlesProvider);
  return Translations(code, bundles[code]!, fallback: bundles['en']);
});
