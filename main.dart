import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/date_format.dart';
import 'core/i18n/translations.dart';
import 'core/storage.dart';
import 'features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimeZones();
  final prefs = await SharedPreferences.getInstance();
  final bundles = await loadTranslationBundles();
  final container = ProviderContainer(
    // No automatic retries: screens show a Retry button instead of hammering a server
    // that is down or in maintenance.
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      translationBundlesProvider.overrideWithValue(bundles),
    ],
  );
  // The splash screen shows until this finishes; the router then redirects.
  unawaited(container.read(authControllerProvider.notifier).restore());
  runApp(
    UncontrolledProviderScope(container: container, child: const PeanutApp()),
  );
}
