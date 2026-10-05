import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/translations.dart';
import 'core/router.dart';
import 'core/theme.dart';

class PeanutApp extends ConsumerWidget {
  const PeanutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'PeanutIQ',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildAppTheme(languageCode),
      // Locale 'ur' makes the whole app right-to-left.
      locale: Locale(languageCode),
      supportedLocales: [for (final code in supportedLanguageCodes) Locale(code)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
