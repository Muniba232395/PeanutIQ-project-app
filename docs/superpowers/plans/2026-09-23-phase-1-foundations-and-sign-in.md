# Phase 1: Foundations and Sign-in — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a runnable Android Flutter app that does four things:
- signs a farmer in with email + OTP;
- walks new farmers through profile setup;
- remembers the session between launches;
- switches English/Urdu (right-to-left).

It also shows the maintenance screen when the backend returns 503. After sign-in it lands on a placeholder Home screen, which Phase 2 replaces with the real tab shell.

**Architecture:**
- **Riverpod** holds app state:
  - `AuthController` (session)
  - `LocaleController` (language)
  - `MaintenanceMode` (503 flag)
- **Dio `ApiClient`**:
  - adds the bearer token to requests;
  - maps failures to typed `AppException`s;
  - reports 401 and 503 through callbacks.
- **go_router** routing: navigation is state-driven. A pure `appRedirect()` function decides the screen from auth and maintenance state, so screens rarely navigate themselves.
- **Translations:** the website's i18next JSON files, read by a small in-house `Translations` class.

**Tech Stack:**
- Flutter 3.47 / Dart 3.13 (Android only)
- flutter_riverpod, go_router, dio
- flutter_secure_storage, shared_preferences
- google_fonts, intl, lucide_icons_flutter
- flutter_localizations

**Spec:** `docs/superpowers/specs/2026-09-23-flutter-farmer-app-design.md` (sections 1–7 and 9–11 apply to this phase).

## Global Constraints

**Repo and project**
- Repo: `/Users/abdulrazzaq/Documents/PeanutIQ-Mobile`, with the Flutter project at the repo root.
- Dart package name: `peanutiq`. Android `applicationId`: `com.peanutiq.app`. App label: `PeanutIQ`.
- Android only. Don't add iOS, web or desktop platforms. minSdk ≥ 23.
- **Commit messages:** no `Co-Authored-By` or other Claude attribution lines.
- **Web repo is read-only:** `/Users/abdulrazzaq/Documents/PeanutIQ`. Only copy files out of it.

**Backend**
- API base URL: `String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api/v1')`.
- The server stores language as `'english' | 'urdu'`. The app uses the codes `'en' | 'ur'`.
- A 401 on a path starting `/auth/` is a normal error (`/auth/verify-otp` returns `401 {"detail":"Invalid OTP"}`). A 401 anywhere else logs out.
- Any 503 turns on maintenance mode.

**Behaviour**
- Farmers only. A user with role `admin` or `researcher` who verifies an OTP sees `auth.app.farmersOnly` and is not signed in: no token is stored.
- Login is **email only**. Trim the value; valid when it matches `^[^\s@]+@[^\s@]+\.[^\s@]+$`.
- Farm regions, verbatim and in order: `Attock, Punjab`, `Chakwal, Punjab`, `Rawalpindi, Punjab`, `Talagang, Punjab`.
- Storage keys:

  | Key | Where | Holds |
  |---|---|---|
  | `peanutiq_token` | secure storage | login token |
  | `peanutiq_user` | prefs | user JSON |
  | `preferredLanguage` | prefs | `en` or `ur` |

**Theme colours (hex, verbatim)**

| Name | Hex |
|---|---|
| sand | `F9FAFC` |
| forest | `07571C` |
| terracotta | `E07A5F` |
| charcoal | `3D4035` |
| earth | `E5E7EB` |
| gold | `F0C169` |
| bannerGreen | `0F5A27` |
| lime | `A3D977` |
| authButton | `324329` |
| authButtonPressed | `1A2315` |
| darkText | `1D2B15` |
| chartTerracotta | `C05A3B` |
| healthGood | `22C55E` |
| healthAverage | `EAB308` |
| healthPoor / danger | `EF4444` |
| seedOrange | `F97316` |
| avatar | `2D5A27` |
| muted | `6B7280` |
| info | `3B82F6` |

**Translations**
- Translation files use i18next syntax: nested keys and `{{name}}` placeholders.
- UI text always comes from `Translations.t(key)`. Never hardcode user-visible English in widgets.
- Exceptions to that rule: the language names `English` and `اردو`, and the `PeanutIQ` wordmark.

## Review Focus

These are the failure modes a farmer is most likely to hit. Each is pinned by a test in the task that owns the code:

1. **Wrong OTP code.** Expected: the user sees "Invalid OTP" and stays on the OTP screen; they are *not* treated as an expired session.
   - Tests: `api_client_test` "401 on /auth path", and `auth_flow_test` "wrong OTP".
2. **Email typed with surrounding spaces** (the keyboard's autocomplete adds a trailing space). Expected: it is trimmed and accepted.
   - Tests: `validators_test` and `auth_flow_test` "existing farmer".
3. **App reopened with no internet.** Expected: the farmer stays signed in with the cached profile and is not logged out.
   - Test: `auth_controller_test` "offline restore".
4. **Token expires while using the app.** Expected: back to Login, with the token and cached user wiped.
   - Tests: `auth_controller_test` "401 during restore" and "401 mid-session".
5. **Backend in maintenance at launch.** Expected:
   - the maintenance screen shows the expected end time;
   - "Check Status" returns to Home once maintenance is over;
   - "Sign out" leads to Login, not back to Maintenance.
   - Test: `maintenance_screen_test`.

---

## File map (created in this phase)

```
pubspec.yaml                          deps + assets
android/app/build.gradle.kts          applicationId
android/app/src/main/AndroidManifest.xml    label, INTERNET permission
android/app/src/debug/AndroidManifest.xml   cleartext HTTP (debug only)
android/app/src/profile/AndroidManifest.xml cleartext HTTP (profile only)
assets/translations/en.json, ur.json  copied from web repo, then merged with phase keys
tool/merge_translations.py            deep-merges a {"en":{},"ur":{}} file into assets
tool/translations/phase1.json         new keys for this phase
lib/main.dart                         bootstrap ProviderContainer, restore session, runApp
lib/app.dart                          PeanutApp (MaterialApp.router)
lib/core/config.dart                  apiBaseUrl
lib/core/errors.dart                  AppException hierarchy + describeError()
lib/core/storage.dart                 TokenStore, SecureTokenStore, AppPrefs + providers
lib/core/maintenance_mode.dart        MaintenanceMode notifier
lib/core/api_client.dart              ApiClient + providers
lib/core/i18n/translations.dart       Translations, LocaleController, language mapping, providers
lib/core/theme.dart                   AppColors, buildAppTheme()
lib/core/router.dart                  appRedirect(), routerProvider
lib/core/widgets/app_logo.dart        AppLogo, Wordmark
lib/core/widgets/app_button.dart      AppButton
lib/core/widgets/language_switch.dart LanguageSwitch
lib/core/widgets/toast.dart           ToastType, showToast()
lib/features/auth/data/app_user.dart
lib/features/auth/data/auth_repository.dart
lib/features/auth/auth_controller.dart
lib/features/auth/validators.dart     isValidEmail, nameInputFormatter
lib/features/auth/farm_regions.dart
lib/features/auth/screens/auth_scaffold.dart
lib/features/auth/screens/splash_screen.dart
lib/features/auth/screens/login_screen.dart
lib/features/auth/screens/otp_screen.dart
lib/features/auth/screens/profile_setup_screen.dart
lib/features/auth/widgets/otp_input.dart
lib/features/maintenance/maintenance_repository.dart
lib/features/maintenance/maintenance_screen.dart
lib/features/home/home_placeholder_screen.dart
test/helpers/fake_adapter.dart
test/helpers/test_env.dart
test/core/translations_test.dart
test/core/api_client_test.dart
test/core/router_test.dart
test/features/auth/validators_test.dart
test/features/auth/auth_controller_test.dart
test/features/auth/auth_flow_test.dart
test/features/maintenance/maintenance_screen_test.dart
README.md
```

---

### Task 1: Scaffold the Flutter project

**Files:**
- Create: the Flutter project at the repo root (`flutter create`)
- Modify: `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/debug/AndroidManifest.xml` and `android/app/src/profile/AndroidManifest.xml` (replace the generated ones)
- Create: `assets/translations/en.json`, `assets/translations/ur.json`, `tool/merge_translations.py`, `tool/translations/phase1.json`
- Delete: `test/widget_test.dart`

**Interfaces:**
- Produces:
  - the package `peanutiq`;
  - the asset path `assets/translations/{en,ur}.json` (declared in pubspec);
  - the script `python3 tool/merge_translations.py <file>`, which later phases reuse.

- [ ] **Step 1: Create the project**

The repo already contains `docs/` and a `.gitignore` holding only `.DS_Store`. Remove that `.gitignore` so Flutter generates its own:

```bash
cd /Users/abdulrazzaq/Documents/PeanutIQ-Mobile
rm .gitignore
flutter create --project-name peanutiq --org com.peanutiq --platforms android .
echo ".DS_Store" >> .gitignore
rm test/widget_test.dart
```

Expected: `All done!`, and `lib/main.dart`, `android/` and `pubspec.yaml` exist.

- [ ] **Step 2: Add dependencies**

```bash
flutter pub add flutter_riverpod go_router dio flutter_secure_storage shared_preferences google_fonts intl lucide_icons_flutter
flutter pub add flutter_localizations --sdk=flutter
```

Expected: `Changed N dependencies!` with no version-solving failure. If `intl` conflicts with `flutter_localizations`, run `flutter pub add intl:any`.

- [ ] **Step 3: Declare the assets**

In `pubspec.yaml`, under the existing `flutter:` key (next to `uses-material-design: true`), add:

```yaml
  assets:
    - assets/translations/
```

- [ ] **Step 4: Configure Android**

In `android/app/build.gradle.kts`, change the `applicationId` line inside `defaultConfig` to:

```kotlin
        applicationId = "com.peanutiq.app"
```

Check `minSdk` in the same block. `minSdk = flutter.minSdkVersion` is fine, because it is ≥ 23 in Flutter 3.47. If it is a literal below 23, set it to `23`.

In `android/app/src/main/AndroidManifest.xml`:
- change `android:label="peanutiq"` to `android:label="PeanutIQ"`;
- add the following as the first child of `<manifest ...>`, above `<application`:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

Replace **both** `android/app/src/debug/AndroidManifest.xml` and `android/app/src/profile/AndroidManifest.xml` with the following. Plain `http://` to the local backend is then allowed only in non-release builds:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application android:usesCleartextTraffic="true"/>
</manifest>
```

- [ ] **Step 5: Copy the translations from the web repo**

```bash
mkdir -p assets/translations tool/translations
cp /Users/abdulrazzaq/Documents/PeanutIQ/src/locales/en.json assets/translations/en.json
cp /Users/abdulrazzaq/Documents/PeanutIQ/src/locales/ur.json assets/translations/ur.json
```

- [ ] **Step 6: Write the merge tool**

Create `tool/merge_translations.py`:

```python
#!/usr/bin/env python3
"""Deep-merge extra translation keys into assets/translations/{en,ur}.json.

Usage: python3 tool/merge_translations.py tool/translations/phase1.json
The input file has the shape {"en": {...}, "ur": {...}}. Existing keys are overwritten.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = value


def main(path):
    extra = json.loads(Path(path).read_text(encoding="utf-8"))
    for code, keys in extra.items():
        target = ROOT / "assets" / "translations" / f"{code}.json"
        data = json.loads(target.read_text(encoding="utf-8"))
        merge(data, keys)
        target.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"updated {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main(sys.argv[1])
```

- [ ] **Step 7: Add the Phase 1 keys**

Create `tool/translations/phase1.json`:

```json
{
  "en": {
    "auth": {
      "mockup": {
        "welcome": "Welcome Back!",
        "loginDesc": "Login to continue your journey"
      },
      "login": { "sendOtp": "Send OTP" },
      "signup": { "sendOtp": "Send OTP" },
      "app": {
        "tagline": "Growing a better tomorrow",
        "taglineDesc": "Smart solutions for modern farming. Manage, Monitor and Maximize your yield with technology.",
        "featureSmart": "Smart Farming",
        "featureHealth": "Crop Health",
        "featureYield": "Better Yield",
        "emailPlaceholder": "Email address",
        "emailInvalid": "Please enter a valid email address",
        "farmersOnly": "This app is for farmers. Admins and researchers, please use the PeanutIQ website.",
        "saveFailed": "Failed to update profile"
      }
    },
    "common": {
      "networkError": "Check your internet connection and try again.",
      "serverError": "Something went wrong. Please try again.",
      "retry": "Retry",
      "logout": "Log out"
    },
    "maintenance": {
      "title": "We'll be right back!",
      "desc": "PeanutIQ is currently undergoing scheduled maintenance to improve your experience.",
      "expected": "Expected Completion",
      "check": "Check Status",
      "checking": "Checking...",
      "signOut": "Sign out and return to login"
    }
  },
  "ur": {
    "auth": {
      "app": {
        "tagline": "ایک بہتر کل کی شروعات",
        "taglineDesc": "جدید زراعت کے لیے سمارٹ حل۔ ٹیکنالوجی کے ذریعے اپنی پیداوار کا انتظام، نگرانی اور اضافہ کریں۔",
        "featureSmart": "سمارٹ زراعت",
        "featureHealth": "فصل کی صحت",
        "featureYield": "بہتر پیداوار",
        "emailPlaceholder": "ای میل ایڈریس",
        "emailInvalid": "براہ کرم درست ای میل ایڈریس درج کریں",
        "farmersOnly": "یہ ایپ کسانوں کے لیے ہے۔ ایڈمنز اور محققین براہ کرم PeanutIQ ویب سائٹ استعمال کریں۔",
        "saveFailed": "پروفائل اپ ڈیٹ نہیں ہو سکی"
      }
    },
    "common": {
      "networkError": "اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔",
      "serverError": "کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔",
      "retry": "دوبارہ کوشش کریں",
      "logout": "لاگ آؤٹ"
    },
    "maintenance": {
      "title": "ہم جلد واپس آئیں گے!",
      "desc": "آپ کے تجربے کو بہتر بنانے کے لیے PeanutIQ پر اس وقت طے شدہ دیکھ بھال جاری ہے۔",
      "expected": "متوقع تکمیل",
      "check": "حالت چیک کریں",
      "checking": "چیک ہو رہا ہے...",
      "signOut": "سائن آؤٹ کریں اور لاگ ان پر واپس جائیں"
    }
  }
}
```

Run:

```bash
python3 tool/merge_translations.py tool/translations/phase1.json
```

Expected output:

```
updated assets/translations/en.json
updated assets/translations/ur.json
```

(`ur.json` already has `auth.mockup.*` and `auth.login.sendOtp`/`auth.signup.sendOtp`. That's why only `en` needs them.)

- [ ] **Step 8: Verify that it builds**

```bash
flutter analyze
flutter build apk --debug
```

Expected:
- `flutter analyze`: `No issues found!`
- the build: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter Android project with deps and translations"
```

---

### Task 2: Translations and language state

**Files:**
- Create: `lib/core/storage.dart`, `lib/core/i18n/translations.dart`, `test/helpers/test_env.dart` (first version), `test/core/translations_test.dart`

**Interfaces:**
- Produces:

  | Symbol | Signature / contract |
  |---|---|
  | `TokenStore` | `read()`, `write(String)`, `clear()` |
  | `SecureTokenStore` | the real `TokenStore`, using flutter_secure_storage |
  | `AppPrefs` | `userJson` / `setUserJson(String?)`; `language` / `setLanguage(String)` |
  | storage providers | `sharedPreferencesProvider` (must be overridden), `appPrefsProvider`, `tokenStoreProvider` |
  | `Translations` | `Translations(String languageCode, Map<String, dynamic> strings, {Map<String, dynamic>? fallback})` |
  | `Translations.t` | `String t(String key, {Map<String, Object?> args = const {}, String? fallback})` |
  | `Translations.raw` | `Object? raw(String key)` |
  | `Translations.isRtl` | `bool get isRtl` |
  | `supportedLanguageCodes` | `['en', 'ur']` |
  | `TranslationBundles` | `typedef TranslationBundles = Map<String, Map<String, dynamic>>` |
  | `loadTranslationBundles` | `Future<TranslationBundles> loadTranslationBundles([AssetBundle? bundle])` |
  | language mapping | `String? languageCodeFromServer(String? value)`; `String serverLanguageFromCode(String code)` |
  | `LocaleController` | `setLanguage(String code)`; getter `hasSavedPreference` |
  | locale providers | `localeControllerProvider` (state = `'en' \| 'ur'`), `translationBundlesProvider` (must be overridden), `trProvider` (`Translations`) |
  | test helpers | `MemoryTokenStore`, `loadTestBundles()` in `test/helpers/test_env.dart` |

- [ ] **Step 1: Write `lib/core/storage.dart`**

The next step's test depends on this file.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the JWT lives. Abstract so tests can use an in-memory store.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'peanutiq_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Non-secret preferences, same keys as the website's localStorage.
class AppPrefs {
  AppPrefs(this._prefs);

  static const _userKey = 'peanutiq_user';
  static const _languageKey = 'preferredLanguage';
  final SharedPreferences _prefs;

  String? get userJson => _prefs.getString(_userKey);

  Future<void> setUserJson(String? json) async {
    if (json == null) {
      await _prefs.remove(_userKey);
    } else {
      await _prefs.setString(_userKey, json);
    }
  }

  String? get language => _prefs.getString(_languageKey);

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_languageKey, code);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);

final appPrefsProvider = Provider<AppPrefs>(
  (ref) => AppPrefs(ref.watch(sharedPreferencesProvider)),
);

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
```

- [ ] **Step 2: Write the test helpers**

Create `test/helpers/test_env.dart`. Task 3 extends this file.

```dart
import 'dart:convert';
import 'dart:io';

import 'package:peanutiq/core/i18n/translations.dart';
import 'package:peanutiq/core/storage.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

/// Reads the real translation files from disk (tests run from the project root).
TranslationBundles loadTestBundles() => {
      for (final code in supportedLanguageCodes)
        code: jsonDecode(File('assets/translations/$code.json').readAsStringSync())
            as Map<String, dynamic>,
    };
```

- [ ] **Step 3: Write the failing test**

Create `test/core/translations_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/core/i18n/translations.dart';
import 'package:peanutiq/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_env.dart';

void main() {
  group('Translations', () {
    final en = {
      'auth': {'otp': {'title': 'Verify Account'}},
      'dashboard': {'welcome': 'Welcome back, {{name}}! Farm in {{ location }}.'},
      'kb': {'categories': [{'id': 1, 'name': 'Cultivation'}]},
      'onlyEnglish': 'English only',
    };
    final ur = {
      'auth': {'otp': {'title': 'اکاؤنٹ کی تصدیق کریں'}},
    };

    test('looks up nested keys with dot paths', () {
      expect(Translations('en', en).t('auth.otp.title'), 'Verify Account');
    });

    test('fills {{name}} placeholders, with or without spaces', () {
      final text = Translations('en', en)
          .t('dashboard.welcome', args: {'name': 'Ali', 'location': 'Attock'});
      expect(text, 'Welcome back, Ali! Farm in Attock.');
    });

    test('leaves unknown placeholders untouched', () {
      expect(Translations('en', en).t('dashboard.welcome', args: {'name': 'Ali'}),
          'Welcome back, Ali! Farm in {{ location }}.');
    });

    test('falls back to English, then to the fallback text, then to the key', () {
      final t = Translations('ur', ur, fallback: en);
      expect(t.t('auth.otp.title'), 'اکاؤنٹ کی تصدیق کریں');
      expect(t.t('onlyEnglish'), 'English only');
      expect(t.t('missing.key', fallback: 'Default'), 'Default');
      expect(t.t('missing.key'), 'missing.key');
    });

    test('raw returns lists and maps', () {
      expect(Translations('en', en).raw('kb.categories'), isA<List<dynamic>>());
    });

    test('isRtl is true only for Urdu', () {
      expect(Translations('ur', ur).isRtl, isTrue);
      expect(Translations('en', en).isRtl, isFalse);
    });
  });

  group('language mapping', () {
    test('maps server values case-insensitively', () {
      expect(languageCodeFromServer('urdu'), 'ur');
      expect(languageCodeFromServer('Urdu'), 'ur');
      expect(languageCodeFromServer('ENGLISH'), 'en');
      expect(languageCodeFromServer(null), isNull);
      expect(languageCodeFromServer('french'), isNull);
    });

    test('maps app codes to server values', () {
      expect(serverLanguageFromCode('ur'), 'urdu');
      expect(serverLanguageFromCode('en'), 'english');
    });
  });

  group('LocaleController', () {
    Future<ProviderContainer> container(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        translationBundlesProvider.overrideWithValue(loadTestBundles()),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('defaults to English with no saved preference', () async {
      final c = await container({});
      expect(c.read(localeControllerProvider), 'en');
      expect(c.read(localeControllerProvider.notifier).hasSavedPreference, isFalse);
    });

    test('uses and persists the saved language', () async {
      final c = await container({'preferredLanguage': 'ur'});
      expect(c.read(localeControllerProvider), 'ur');
      await c.read(localeControllerProvider.notifier).setLanguage('en');
      expect(c.read(localeControllerProvider), 'en');
      expect(c.read(appPrefsProvider).language, 'en');
    });

    test('trProvider follows the current language', () async {
      final c = await container({});
      expect(c.read(trProvider).t('auth.otp.title'), 'Verify Account');
      await c.read(localeControllerProvider.notifier).setLanguage('ur');
      expect(c.read(trProvider).t('auth.otp.title'), 'اکاؤنٹ کی تصدیق کریں');
    });
  });

  test('every Phase 1 key exists in both languages', () {
    const keys = [
      'auth.mockup.welcome', 'auth.mockup.loginDesc', 'auth.login.sendOtp',
      'auth.login.noAccount', 'auth.login.signupLink', 'auth.signup.title',
      'auth.signup.subtitle', 'auth.signup.sendOtp', 'auth.signup.hasAccount',
      'auth.signup.loginLink', 'auth.otp.title', 'auth.otp.subtitle',
      'auth.otp.errorLength', 'auth.otp.errorInvalid', 'auth.otp.submitBtn',
      'auth.otp.notReceived', 'auth.otp.resendBtn', 'auth.otp.changeContact',
      'auth.profileSetup.title', 'auth.profileSetup.subtitle',
      'auth.profileSetup.fullName', 'auth.profileSetup.namePlaceholder',
      'auth.profileSetup.farmLocation', 'auth.profileSetup.locationPlaceholder',
      'auth.profileSetup.languagePreference', 'auth.profileSetup.langEnglish',
      'auth.profileSetup.langUrdu', 'auth.profileSetup.submitBtn',
      'auth.app.tagline', 'auth.app.taglineDesc', 'auth.app.featureSmart',
      'auth.app.featureHealth', 'auth.app.featureYield', 'auth.app.emailPlaceholder',
      'auth.app.emailInvalid', 'auth.app.farmersOnly', 'auth.app.saveFailed',
      'common.networkError', 'common.serverError', 'common.retry', 'common.logout',
      'maintenance.title', 'maintenance.desc', 'maintenance.expected',
      'maintenance.check', 'maintenance.checking', 'maintenance.signOut',
      'dashboard.welcome',
    ];
    final bundles = loadTestBundles();
    for (final code in supportedLanguageCodes) {
      final t = Translations(code, bundles[code]!);
      for (final key in keys) {
        expect(t.raw(key), isA<String>(), reason: '$code is missing $key');
      }
    }
  });
}
```

- [ ] **Step 4: Run the test to confirm it fails**

Run: `flutter test test/core/translations_test.dart`

Expected: a compilation error, because `package:peanutiq/core/i18n/translations.dart` does not exist yet.

- [ ] **Step 5: Implement `lib/core/i18n/translations.dart`**

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';

const supportedLanguageCodes = ['en', 'ur'];

typedef TranslationBundles = Map<String, Map<String, dynamic>>;

/// Reads the website's i18next JSON: nested keys, `{{name}}` placeholders,
/// and English as the fallback language.
class Translations {
  Translations(this.languageCode, this._strings, {Map<String, dynamic>? fallback})
      : _fallback = fallback;

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
```

- [ ] **Step 6: Run the test to confirm it passes**

Run: `flutter test test/core/translations_test.dart`

Expected: `All tests passed!`

If "every Phase 1 key exists" fails, the merge in Task 1, Step 7 was skipped or incomplete. Fix `tool/translations/phase1.json` and rerun the merge; don't edit the test.

- [ ] **Step 7: Commit**

```bash
git add lib/core/storage.dart lib/core/i18n test/helpers/test_env.dart test/core/translations_test.dart
git commit -m "feat: i18next-compatible translations, language state and storage"
```

---

### Task 3: API client, errors and maintenance flag

**Files:**
- Create: `lib/core/config.dart`, `lib/core/errors.dart`, `lib/core/maintenance_mode.dart`, `lib/core/api_client.dart`, `test/helpers/fake_adapter.dart`, `test/core/api_client_test.dart`
- Create a stub (Task 4 replaces it): `lib/features/auth/auth_controller.dart`

**Interfaces:**
- Consumes: `TokenStore`, `tokenStoreProvider` (Task 2); `Translations` (Task 2).
- Produces:

  | Symbol | Signature / contract |
  |---|---|
  | `apiBaseUrl` | `const String` |
  | `AppException` | `sealed class` |
  | error types | `NetworkException()`, `UnauthorizedException()`, `MaintenanceException()`, `ServerException({required int statusCode, String? detail})` |
  | `describeError` | `String describeError(Object error, Translations t)` |
  | `MaintenanceMode` | `enter()`, `exit()` |
  | `maintenanceModeProvider` | `NotifierProvider<MaintenanceMode, bool>` |
  | `ApiClient` | constructor `ApiClient({required String baseUrl, required TokenStore tokenStore, required void Function() onUnauthorized, required void Function() onMaintenance, HttpClientAdapter? adapter})` |
  | `ApiClient` methods | `get(path, {query})`, `post(path, {data})`, `put(path, {data})`, `delete(path)`. Each returns `Future<dynamic>` (the decoded JSON body) and throws `AppException` on failure. |
  | API providers | `httpAdapterProvider` (`Provider<HttpClientAdapter?>`, default null; tests override it), `apiClientProvider` |
  | `FakeAdapter` | `on(method, path, status, [body])`, `failConnection`, `requests` |

- [ ] **Step 1: Write the fake HTTP adapter for tests**

Create `test/helpers/fake_adapter.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Serves canned JSON responses keyed by 'METHOD /path'. Unknown routes return 404.
class FakeAdapter implements HttpClientAdapter {
  final Map<String, ({int status, Object? body})> _routes = {};
  final List<RequestOptions> requests = [];
  bool failConnection = false;

  void on(String method, String path, int status, [Object? body]) {
    _routes['$method $path'] = (status: status, body: body);
  }

  /// Requests made to [path] (any method), oldest first.
  List<RequestOptions> requestsTo(String path) =>
      requests.where((r) => r.path == path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failConnection) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    final route = _routes['${options.method} ${options.path}'] ??
        (status: 404, body: {'detail': 'Not Found'});
    return ResponseBody.fromString(
      jsonEncode(route.body),
      route.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: Write the failing test**

Create `test/core/api_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/core/api_client.dart';
import 'package:peanutiq/core/errors.dart';
import 'package:peanutiq/core/i18n/translations.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_env.dart';

void main() {
  late FakeAdapter adapter;
  late int unauthorizedCalls;
  late int maintenanceCalls;

  ApiClient client({String? token}) => ApiClient(
        baseUrl: 'http://test/api/v1',
        tokenStore: MemoryTokenStore(token),
        adapter: adapter,
        onUnauthorized: () => unauthorizedCalls++,
        onMaintenance: () => maintenanceCalls++,
      );

  setUp(() {
    adapter = FakeAdapter();
    unauthorizedCalls = 0;
    maintenanceCalls = 0;
  });

  test('sends the bearer token when one is stored', () async {
    adapter.on('GET', '/users/me', 200, {'id': 'u1'});
    await client(token: 'abc').get('/users/me');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('sends no Authorization header without a token', () async {
    adapter.on('POST', '/auth/request-otp', 200, {'message': 'ok'});
    await client().post('/auth/request-otp', data: {'identifier': 'a@b.co'});
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(adapter.requests.single.data, {'identifier': 'a@b.co'});
  });

  test('returns the decoded JSON body', () async {
    adapter.on('GET', '/users/me', 200, {'id': 'u1', 'name': 'Ali'});
    final body = await client(token: 't').get('/users/me');
    expect(body, {'id': 'u1', 'name': 'Ali'});
  });

  test('401 on a protected path logs out and throws UnauthorizedException', () async {
    adapter.on('GET', '/users/me', 401, {'detail': 'Could not validate credentials'});
    await expectLater(client(token: 'old').get('/users/me'),
        throwsA(isA<UnauthorizedException>()));
    expect(unauthorizedCalls, 1);
  });

  test('401 on an /auth path is a normal error with the server detail', () async {
    adapter.on('POST', '/auth/verify-otp', 401, {'detail': 'Invalid OTP'});
    await expectLater(
      client().post('/auth/verify-otp', data: {'identifier': 'a@b.co', 'otp': '000000'}),
      throwsA(isA<ServerException>()
          .having((e) => e.statusCode, 'statusCode', 401)
          .having((e) => e.detail, 'detail', 'Invalid OTP')),
    );
    expect(unauthorizedCalls, 0);
  });

  test('503 switches on maintenance and throws MaintenanceException', () async {
    adapter.on('GET', '/users/me', 503, {'detail': 'System under maintenance'});
    await expectLater(client(token: 't').get('/users/me'),
        throwsA(isA<MaintenanceException>()));
    expect(maintenanceCalls, 1);
  });

  test('validation errors with a list detail become ServerException without detail', () async {
    adapter.on('POST', '/auth/request-otp', 422, {
      'detail': [
        {'msg': 'value is not a valid email address'},
      ],
    });
    await expectLater(
      client().post('/auth/request-otp', data: {'identifier': 'x'}),
      throwsA(isA<ServerException>()
          .having((e) => e.statusCode, 'statusCode', 422)
          .having((e) => e.detail, 'detail', isNull)),
    );
  });

  test('connection failures become NetworkException', () async {
    adapter.failConnection = true;
    await expectLater(client().get('/users/me'), throwsA(isA<NetworkException>()));
  });

  group('describeError', () {
    final t = Translations('en', loadTestBundles()['en']!);

    test('uses the server detail when present', () {
      expect(describeError(const ServerException(statusCode: 400, detail: 'OTP expired'), t),
          'OTP expired');
    });

    test('uses friendly text for network and unknown errors', () {
      expect(describeError(const NetworkException(), t),
          'Check your internet connection and try again.');
      expect(describeError(const ServerException(statusCode: 500), t),
          'Something went wrong. Please try again.');
      expect(describeError(StateError('boom'), t), 'Something went wrong. Please try again.');
    });
  });
}
```

- [ ] **Step 3: Run the test to confirm it fails**

Run: `flutter test test/core/api_client_test.dart`

Expected: a compilation error, because `api_client.dart` and `errors.dart` do not exist yet.

- [ ] **Step 4: Implement config, errors and the maintenance flag**

`lib/core/config.dart`:

```dart
/// Backend base URL. Override per build, for example:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000/api/v1
/// The default reaches a backend on the host machine from the Android emulator.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
```

`lib/core/errors.dart`:

```dart
import 'i18n/translations.dart';

sealed class AppException implements Exception {
  const AppException();
}

/// No response at all: offline, DNS failure, timeout.
class NetworkException extends AppException {
  const NetworkException();

  @override
  String toString() => 'NetworkException';
}

/// The session token was rejected (401 outside /auth/*).
class UnauthorizedException extends AppException {
  const UnauthorizedException();

  @override
  String toString() => 'UnauthorizedException';
}

/// The backend is in a maintenance window (503).
class MaintenanceException extends AppException {
  const MaintenanceException();

  @override
  String toString() => 'MaintenanceException';
}

/// Any other non-2xx response. [detail] is FastAPI's `detail` when it is a string.
class ServerException extends AppException {
  const ServerException({required this.statusCode, this.detail});

  final int statusCode;
  final String? detail;

  @override
  String toString() => 'ServerException($statusCode, $detail)';
}

String describeError(Object error, Translations t) => switch (error) {
      NetworkException() => t.t('common.networkError'),
      ServerException(detail: final String detail) => detail,
      _ => t.t('common.serverError'),
    };
```

`lib/core/maintenance_mode.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the backend reports a maintenance window. The router sends the user to /maintenance.
class MaintenanceMode extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;

  void exit() => state = false;
}

final maintenanceModeProvider =
    NotifierProvider<MaintenanceMode, bool>(MaintenanceMode.new);
```

- [ ] **Step 5: Add the temporary `AuthController` stub**

`apiClientProvider` refers to `authControllerProvider`, which Task 4 builds. Create `lib/features/auth/auth_controller.dart` with this stub for now; **Task 4 replaces the whole file**:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Temporary stub, replaced in Task 4.
class AuthController extends Notifier<void> {
  @override
  void build() {}

  void handleUnauthorized() {}
}

final authControllerProvider = NotifierProvider<AuthController, void>(AuthController.new);
```

- [ ] **Step 6: Implement `lib/core/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import 'config.dart';
import 'errors.dart';
import 'maintenance_mode.dart';
import 'storage.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    required void Function() onUnauthorized,
    required void Function() onMaintenance,
    HttpClientAdapter? adapter,
  })  : _tokenStore = tokenStore,
        _onUnauthorized = onUnauthorized,
        _onMaintenance = onMaintenance,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _tokenStore.read();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }

  final Dio _dio;
  final TokenStore _tokenStore;
  final void Function() _onUnauthorized;
  final void Function() _onMaintenance;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  AppException _map(DioException e) {
    final response = e.response;
    if (response == null) return const NetworkException();
    final status = response.statusCode ?? 0;
    if (status == 503) {
      _onMaintenance();
      return const MaintenanceException();
    }
    if (status == 401 && !e.requestOptions.path.startsWith('/auth/')) {
      _onUnauthorized();
      return const UnauthorizedException();
    }
    final data = response.data;
    final detail = data is Map && data['detail'] is String ? data['detail'] as String : null;
    return ServerException(statusCode: status, detail: detail);
  }
}

/// Tests override this with a FakeAdapter. null means Dio's real network adapter.
final httpAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      baseUrl: apiBaseUrl,
      tokenStore: ref.watch(tokenStoreProvider),
      adapter: ref.watch(httpAdapterProvider),
      onUnauthorized: () => ref.read(authControllerProvider.notifier).handleUnauthorized(),
      onMaintenance: () => ref.read(maintenanceModeProvider.notifier).enter(),
    ));
```

- [ ] **Step 7: Run the test to confirm it passes**

Run: `flutter test test/core/api_client_test.dart`

Expected: `All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add lib/core test/helpers/fake_adapter.dart test/core/api_client_test.dart lib/features/auth/auth_controller.dart
git commit -m "feat: dio API client with typed errors, 401 and 503 handling"
```

---

### Task 4: User model, auth repository and AuthController

**Files:**
- Create: `lib/features/auth/data/app_user.dart`, `lib/features/auth/data/auth_repository.dart`
- Replace: `lib/features/auth/auth_controller.dart` (the stub from Task 3)
- Modify: `test/helpers/test_env.dart` (add `createTestContainer` and `userJson`)
- Test: `test/features/auth/auth_controller_test.dart`

**Interfaces:**
- Consumes:
  - `ApiClient`, `apiClientProvider`, `AppException` and its subclasses (Task 3);
  - `TokenStore`, `tokenStoreProvider`, `AppPrefs`, `appPrefsProvider`, `localeControllerProvider`, `languageCodeFromServer`, `serverLanguageFromCode` (Task 2).
- Produces:

  | Symbol | Signature / contract |
  |---|---|
  | `AppUser` | fields `id`, `identifier`, `name` (String?), `role`, `farmLocation` (String?), `languagePreference`, `timezone`; `fromJson`, `toJson`, getters `isFarmer`, `hasFarmLocation` |
  | `AuthRepository` | `requestOtp(String email)`; `verifyOtp(String email, String otp)` returns `Future<({String token, AppUser user})>`; `fetchMe()`; `updateMe(Map<String, dynamic>)` |
  | `authRepositoryProvider` | provides `AuthRepository` |
  | `AuthStatus` | `enum { unknown, signedOut, signedIn }` |
  | `AuthState` | fields `status`, `user`, `needsProfileSetup`; constructors `AuthState.unknown()`, `AuthState.signedOut()`, `AuthState.signedIn(user, {needsProfileSetup})` |
  | `VerifyOutcome` | `enum { signedIn, blockedRole }` |
  | `AuthController` | `restore()`; `requestOtp(String email)`; `verifyOtp({required String email, required String otp, required bool isSignup})` returns `Future<VerifyOutcome>`; `updateProfile({String? name, String? farmLocation, String? languageCode, String? timezone})`; `logout()`; `handleUnauthorized()` |
  | `authControllerProvider` | `NotifierProvider<AuthController, AuthState>` |
  | test helpers | `createTestContainer({FakeAdapter? adapter, MemoryTokenStore? tokens, Map<String, Object> prefs})`; `userJson({...})` |

- [ ] **Step 1: Extend the test helpers**

Replace `test/helpers/test_env.dart` with:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/core/api_client.dart';
import 'package:peanutiq/core/i18n/translations.dart';
import 'package:peanutiq/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_adapter.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

/// Reads the real translation files from disk (tests run from the project root).
TranslationBundles loadTestBundles() => {
      for (final code in supportedLanguageCodes)
        code: jsonDecode(File('assets/translations/$code.json').readAsStringSync())
            as Map<String, dynamic>,
    };

/// A server-shaped user object (matches the backend's UserResponse).
Map<String, dynamic> userJson({
  String role = 'farmer',
  String? farmLocation = 'Attock, Punjab',
  String language = 'english',
  String name = 'Ali',
}) =>
    {
      'id': 'u1',
      'identifier': 'ali@example.com',
      'name': name,
      'role': role,
      'farm_location': farmLocation,
      'language_preference': language,
      'timezone': 'Asia/Karachi',
      'is_active': true,
      'created_at': '2026-01-01T00:00:00',
    };

/// A ProviderContainer wired to fakes: in-memory token, mock prefs, fake HTTP.
Future<ProviderContainer> createTestContainer({
  FakeAdapter? adapter,
  MemoryTokenStore? tokens,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(sp),
    translationBundlesProvider.overrideWithValue(loadTestBundles()),
    tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
    httpAdapterProvider.overrideWithValue(adapter ?? FakeAdapter()),
  ]);
  addTearDown(container.dispose);
  return container;
}
```

- [ ] **Step 2: Write the failing test**

Create `test/features/auth/auth_controller_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/core/errors.dart';
import 'package:peanutiq/core/i18n/translations.dart';
import 'package:peanutiq/core/storage.dart';
import 'package:peanutiq/features/auth/auth_controller.dart';
import 'package:peanutiq/features/auth/data/app_user.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_env.dart';

void main() {
  late FakeAdapter adapter;
  late MemoryTokenStore tokens;

  setUp(() {
    adapter = FakeAdapter();
    tokens = MemoryTokenStore();
  });

  group('AppUser', () {
    test('parses server JSON and normalises role and language case', () {
      final user = AppUser.fromJson(userJson()..['role'] = 'Farmer'..['language_preference'] = 'Urdu');
      expect(user.role, 'farmer');
      expect(user.isFarmer, isTrue);
      expect(user.languagePreference, 'urdu');
      expect(user.hasFarmLocation, isTrue);
    });

    test('treats a blank farm location as missing', () {
      expect(AppUser.fromJson(userJson(farmLocation: '  ')).hasFarmLocation, isFalse);
      expect(AppUser.fromJson(userJson(farmLocation: null)).hasFarmLocation, isFalse);
    });

    test('toJson round-trips', () {
      final user = AppUser.fromJson(userJson());
      expect(AppUser.fromJson(user.toJson()).toJson(), user.toJson());
    });
  });

  group('restore', () {
    test('no token means signed out', () async {
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      expect(c.read(authControllerProvider).status, AuthStatus.unknown);
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
    });

    test('valid token refreshes the user from the server and caches it', () async {
      tokens.token = 'tok';
      adapter.on('GET', '/users/me', 200, userJson(name: 'Ali Khan'));
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      await c.read(authControllerProvider.notifier).restore();
      final state = c.read(authControllerProvider);
      expect(state.status, AuthStatus.signedIn);
      expect(state.user!.name, 'Ali Khan');
      expect(state.needsProfileSetup, isFalse);
      expect(jsonDecode(c.read(appPrefsProvider).userJson!)['name'], 'Ali Khan');
    });

    test("applies the server's language after refreshing", () async {
      tokens.token = 'tok';
      adapter.on('GET', '/users/me', 200, userJson(language: 'urdu'));
      final c = await createTestContainer(adapter: adapter, tokens: tokens,
          prefs: {'preferredLanguage': 'en'});
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(localeControllerProvider), 'ur');
    });

    test('401 during restore signs out and wipes the stored session', () async {
      tokens.token = 'expired';
      adapter.on('GET', '/users/me', 401, {'detail': 'Could not validate credentials'});
      final c = await createTestContainer(adapter: adapter, tokens: tokens,
          prefs: {'peanutiq_user': jsonEncode(userJson())});
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
      expect(tokens.token, isNull);
      expect(c.read(appPrefsProvider).userJson, isNull);
    });

    test('offline restore keeps the cached user signed in', () async {
      tokens.token = 'tok';
      adapter.failConnection = true;
      final c = await createTestContainer(adapter: adapter, tokens: tokens,
          prefs: {'peanutiq_user': jsonEncode(userJson(name: 'Cached Ali'))});
      await c.read(authControllerProvider.notifier).restore();
      final state = c.read(authControllerProvider);
      expect(state.status, AuthStatus.signedIn);
      expect(state.user!.name, 'Cached Ali');
      expect(tokens.token, 'tok');
    });

    test('a stored non-farmer session is signed out', () async {
      tokens.token = 'tok';
      adapter.on('GET', '/users/me', 200, userJson(role: 'admin'));
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
      expect(tokens.token, isNull);
    });
  });

  group('verifyOtp', () {
    Future<VerifyOutcome> verify(ProviderContainer c, {bool isSignup = false}) =>
        c.read(authControllerProvider.notifier).verifyOtp(
            email: ' ali@example.com ', otp: '123456', isSignup: isSignup);

    test('existing farmer is signed in and the token stored', () async {
      adapter.on('POST', '/auth/verify-otp', 200,
          {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson()});
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      expect(await verify(c), VerifyOutcome.signedIn);
      final state = c.read(authControllerProvider);
      expect(state.status, AuthStatus.signedIn);
      expect(state.needsProfileSetup, isFalse);
      expect(tokens.token, 'tok');
      expect(adapter.requestsTo('/auth/verify-otp').single.data,
          {'identifier': 'ali@example.com', 'otp': '123456'});
    });

    test('signup always goes through profile setup', () async {
      adapter.on('POST', '/auth/verify-otp', 200,
          {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson()});
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      await verify(c, isSignup: true);
      expect(c.read(authControllerProvider).needsProfileSetup, isTrue);
    });

    test('farmer without a farm location needs profile setup', () async {
      adapter.on('POST', '/auth/verify-otp', 200,
          {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(farmLocation: null)});
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      await verify(c);
      expect(c.read(authControllerProvider).needsProfileSetup, isTrue);
    });

    test('admin and researcher are blocked and nothing is stored', () async {
      for (final role in ['admin', 'researcher']) {
        adapter.on('POST', '/auth/verify-otp', 200,
            {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(role: role)});
        final c = await createTestContainer(adapter: adapter, tokens: tokens);
        await c.read(authControllerProvider.notifier).restore();
        expect(await verify(c), VerifyOutcome.blockedRole);
        expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
        expect(tokens.token, isNull);
      }
    });

    test('a language chosen on the login screen wins over the server', () async {
      adapter.on('POST', '/auth/verify-otp', 200, {
        'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(language: 'english'),
      });
      final c = await createTestContainer(adapter: adapter, tokens: tokens,
          prefs: {'preferredLanguage': 'ur'});
      await verify(c);
      expect(c.read(localeControllerProvider), 'ur');
    });

    test('with no saved language, the server language is applied', () async {
      adapter.on('POST', '/auth/verify-otp', 200, {
        'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(language: 'urdu'),
      });
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      await verify(c);
      expect(c.read(localeControllerProvider), 'ur');
    });

    test('wrong code surfaces the server error', () async {
      adapter.on('POST', '/auth/verify-otp', 401, {'detail': 'Invalid OTP'});
      final c = await createTestContainer(adapter: adapter, tokens: tokens);
      await expectLater(verify(c),
          throwsA(isA<ServerException>().having((e) => e.detail, 'detail', 'Invalid OTP')));
    });
  });

  test('requestOtp trims the email', () async {
    adapter.on('POST', '/auth/request-otp', 200, {'message': 'ok'});
    final c = await createTestContainer(adapter: adapter, tokens: tokens);
    await c.read(authControllerProvider.notifier).requestOtp('  ali@example.com ');
    expect(adapter.requestsTo('/auth/request-otp').single.data, {'identifier': 'ali@example.com'});
  });

  test('updateProfile sends server-format values and clears needsProfileSetup', () async {
    adapter.on('POST', '/auth/verify-otp', 200,
        {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(farmLocation: null)});
    adapter.on('PUT', '/users/me', 200, userJson(farmLocation: 'Chakwal, Punjab', language: 'urdu'));
    final c = await createTestContainer(adapter: adapter, tokens: tokens);
    final auth = c.read(authControllerProvider.notifier);
    await auth.verifyOtp(email: 'ali@example.com', otp: '123456', isSignup: true);
    await auth.updateProfile(name: ' Ali ', farmLocation: 'Chakwal, Punjab', languageCode: 'ur');
    expect(adapter.requestsTo('/users/me').single.data, {
      'name': 'Ali',
      'farm_location': 'Chakwal, Punjab',
      'language_preference': 'urdu',
    });
    final state = c.read(authControllerProvider);
    expect(state.needsProfileSetup, isFalse);
    expect(state.user!.farmLocation, 'Chakwal, Punjab');
    expect(c.read(localeControllerProvider), 'ur');
  });

  test('logout clears token and cached user', () async {
    adapter.on('POST', '/auth/verify-otp', 200,
        {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson()});
    final c = await createTestContainer(adapter: adapter, tokens: tokens);
    final auth = c.read(authControllerProvider.notifier);
    await auth.verifyOtp(email: 'ali@example.com', otp: '123456', isSignup: false);
    await auth.logout();
    expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
    expect(tokens.token, isNull);
    expect(c.read(appPrefsProvider).userJson, isNull);
  });

  test('401 mid-session signs out', () async {
    adapter.on('POST', '/auth/verify-otp', 200,
        {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson()});
    adapter.on('PUT', '/users/me', 401, {'detail': 'Could not validate credentials'});
    final c = await createTestContainer(adapter: adapter, tokens: tokens);
    final auth = c.read(authControllerProvider.notifier);
    await auth.verifyOtp(email: 'ali@example.com', otp: '123456', isSignup: false);
    await expectLater(auth.updateProfile(name: 'X'), throwsA(isA<UnauthorizedException>()));
    await pumpEventQueue();
    expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
    expect(tokens.token, isNull);
  });
}
```

- [ ] **Step 3: Run the test to confirm it fails**

Run: `flutter test test/features/auth/auth_controller_test.dart`

Expected: a compilation error, because `app_user.dart` does not exist yet and `AuthStatus` is undefined.

- [ ] **Step 4: Implement `lib/features/auth/data/app_user.dart`**

```dart
/// The signed-in user, as returned by /users/me and /auth/verify-otp.
class AppUser {
  const AppUser({
    required this.id,
    required this.identifier,
    required this.role,
    required this.languagePreference,
    required this.timezone,
    this.name,
    this.farmLocation,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: '${json['id']}',
        identifier: (json['identifier'] ?? json['email'] ?? '') as String,
        name: json['name'] as String?,
        role: '${json['role'] ?? 'farmer'}'.toLowerCase(),
        farmLocation: json['farm_location'] as String?,
        languagePreference: '${json['language_preference'] ?? 'english'}'.toLowerCase(),
        timezone: (json['timezone'] ?? 'UTC') as String,
      );

  final String id;
  final String identifier;
  final String? name;

  /// 'farmer' | 'admin' | 'researcher'
  final String role;
  final String? farmLocation;

  /// Server value: 'english' | 'urdu'
  final String languagePreference;
  final String timezone;

  bool get isFarmer => role == 'farmer';

  bool get hasFarmLocation => (farmLocation ?? '').trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifier': identifier,
        'name': name,
        'role': role,
        'farm_location': farmLocation,
        'language_preference': languagePreference,
        'timezone': timezone,
      };
}
```

- [ ] **Step 5: Implement `lib/features/auth/data/auth_repository.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'app_user.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// The backend creates the user if the email is new, then emails a 6-digit code.
  Future<void> requestOtp(String email) async {
    await _api.post('/auth/request-otp', data: {'identifier': email});
  }

  Future<({String token, AppUser user})> verifyOtp(String email, String otp) async {
    final data = await _api.post('/auth/verify-otp', data: {'identifier': email, 'otp': otp})
        as Map<String, dynamic>;
    return (
      token: data['access_token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AppUser> fetchMe() async =>
      AppUser.fromJson(await _api.get('/users/me') as Map<String, dynamic>);

  Future<AppUser> updateMe(Map<String, dynamic> changes) async =>
      AppUser.fromJson(await _api.put('/users/me', data: changes) as Map<String, dynamic>);
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));
```

- [ ] **Step 6: Implement `lib/features/auth/auth_controller.dart`**

This replaces the whole stub from Task 3:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/i18n/translations.dart';
import '../../core/storage.dart';
import 'data/app_user.dart';
import 'data/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

enum VerifyOutcome { signedIn, blockedRole }

class AuthState {
  const AuthState._(this.status, this.user, this.needsProfileSetup);

  const AuthState.unknown() : this._(AuthStatus.unknown, null, false);

  const AuthState.signedOut() : this._(AuthStatus.signedOut, null, false);

  const AuthState.signedIn(AppUser user, {bool needsProfileSetup = false})
      : this._(AuthStatus.signedIn, user, needsProfileSetup);

  final AuthStatus status;
  final AppUser? user;

  /// True when the router must show /profile-setup before anything else.
  final bool needsProfileSetup;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);
  AppPrefs get _prefs => ref.read(appPrefsProvider);

  /// Called once at startup: loads the stored session and refreshes it from the server.
  Future<void> restore() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      await _clearSession();
      state = const AuthState.signedOut();
      return;
    }
    final cached = _readCachedUser();
    try {
      final user = await _repo.fetchMe();
      if (!user.isFarmer) {
        await logout();
        return;
      }
      await _saveUser(user);
      await _applyServerLanguage(user);
      state = _signedIn(user);
    } on UnauthorizedException {
      await logout();
    } on Object {
      // Offline, maintenance, or an unexpected response: keep the cached session if there is one.
      // Catching everything here matters: main() doesn't await restore(), so an escaped
      // error would leave the app on the splash screen forever.
      if (cached != null) {
        state = _signedIn(cached);
      } else {
        await logout();
      }
    }
  }

  Future<void> requestOtp(String email) => _repo.requestOtp(email.trim());

  Future<VerifyOutcome> verifyOtp({
    required String email,
    required String otp,
    required bool isSignup,
  }) async {
    final result = await _repo.verifyOtp(email.trim(), otp);
    if (!result.user.isFarmer) return VerifyOutcome.blockedRole;
    await _tokens.write(result.token);
    await _saveUser(result.user);
    if (!ref.read(localeControllerProvider.notifier).hasSavedPreference) {
      await _applyServerLanguage(result.user);
    }
    state = AuthState.signedIn(
      result.user,
      needsProfileSetup: isSignup || !result.user.hasFarmLocation,
    );
    return VerifyOutcome.signedIn;
  }

  Future<void> updateProfile({
    String? name,
    String? farmLocation,
    String? languageCode,
    String? timezone,
  }) async {
    final user = await _repo.updateMe({
      if (name != null) 'name': name.trim(),
      if (farmLocation != null) 'farm_location': farmLocation,
      if (languageCode != null) 'language_preference': serverLanguageFromCode(languageCode),
      if (timezone != null) 'timezone': timezone,
    });
    await _saveUser(user);
    await _applyServerLanguage(user);
    state = _signedIn(user);
  }

  Future<void> logout() async {
    state = const AuthState.signedOut();
    await _clearSession();
  }

  /// Called by ApiClient when a protected request returns 401.
  void handleUnauthorized() {
    if (state.status == AuthStatus.signedOut) return;
    state = const AuthState.signedOut();
    unawaited(_clearSession());
  }

  AuthState _signedIn(AppUser user) =>
      AuthState.signedIn(user, needsProfileSetup: !user.hasFarmLocation);

  AppUser? _readCachedUser() {
    final json = _prefs.userJson;
    if (json == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> _saveUser(AppUser user) => _prefs.setUserJson(jsonEncode(user.toJson()));

  Future<void> _applyServerLanguage(AppUser user) async {
    final code = languageCodeFromServer(user.languagePreference);
    if (code != null) await ref.read(localeControllerProvider.notifier).setLanguage(code);
  }

  Future<void> _clearSession() async {
    await _tokens.clear();
    await _prefs.setUserJson(null);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
```

- [ ] **Step 7: Run the tests to confirm they pass**

Run: `flutter test test/features/auth/auth_controller_test.dart test/core`

Expected: `All tests passed!` (this also re-runs Task 2 and 3's tests against the real controller).

- [ ] **Step 8: Commit**

```bash
git add lib/features/auth test/helpers/test_env.dart test/features/auth/auth_controller_test.dart
git commit -m "feat: AuthController with OTP sign-in, session restore and farmer-only guard"
```

---

### Task 5: Route decisions and validators

**Files:**
- Create: `lib/features/auth/validators.dart`, `lib/features/auth/farm_regions.dart`
- Create: `lib/core/router.dart`. In this task it holds only `appRedirect`; Task 6 adds `routerProvider`.
- Test: `test/features/auth/validators_test.dart`, `test/core/router_test.dart`

**Interfaces:**
- Consumes: `AuthState`, `AuthStatus` (Task 4); `AppUser` (Task 4).
- Produces:

  | Symbol | Signature / contract |
  |---|---|
  | `isValidEmail` | `bool isValidEmail(String value)`. Trims before checking. |
  | `nameInputFormatter` | `TextInputFormatter`. Rejects edits that leave anything but letters, combining marks and spaces. |
  | `farmRegions` | `const List<String>` |
  | `appRedirect` | `String? appRedirect({required AuthState auth, required bool maintenance, required String location})` |
  | `Routes` | constants `splash`, `login`, `signup`, `verifyOtp`, `profileSetup`, `maintenance`, `home` |

- [ ] **Step 1: Write the failing tests**

`test/features/auth/validators_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/features/auth/farm_regions.dart';
import 'package:peanutiq/features/auth/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts normal addresses, including surrounding spaces', () {
      expect(isValidEmail('ali@example.com'), isTrue);
      expect(isValidEmail('  ali.khan+farm@mail.co.pk '), isTrue);
    });

    test('rejects phone numbers and malformed input', () {
      for (final bad in ['', '   ', '+92 300 1234567', 'ali@', '@example.com', 'ali@example', 'ali @x.com']) {
        expect(isValidEmail(bad), isFalse, reason: bad);
      }
    });
  });

  group('nameInputFormatter', () {
    TextEditingValue apply(String oldText, String newText) =>
        nameInputFormatter.formatEditUpdate(
          TextEditingValue(text: oldText),
          TextEditingValue(text: newText),
        );

    test('allows English and Urdu letters and spaces', () {
      expect(apply('', 'Ali Khan').text, 'Ali Khan');
      expect(apply('', 'احمد خان').text, 'احمد خان');
    });

    test('rejects digits and symbols by keeping the previous value', () {
      expect(apply('Ali', 'Ali1').text, 'Ali');
      expect(apply('Ali', 'Ali@').text, 'Ali');
    });
  });

  test('farm regions match the website', () {
    expect(farmRegions, ['Attock, Punjab', 'Chakwal, Punjab', 'Rawalpindi, Punjab', 'Talagang, Punjab']);
  });
}
```

`test/core/router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/core/router.dart';
import 'package:peanutiq/features/auth/auth_controller.dart';
import 'package:peanutiq/features/auth/data/app_user.dart';

import '../helpers/test_env.dart';

void main() {
  final farmer = AppUser.fromJson(userJson());
  const unknown = AuthState.unknown();
  const signedOut = AuthState.signedOut();
  final signedIn = AuthState.signedIn(farmer);
  final needsSetup = AuthState.signedIn(farmer, needsProfileSetup: true);

  String? go(AuthState auth, String location, {bool maintenance = false}) =>
      appRedirect(auth: auth, maintenance: maintenance, location: location);

  test('while restoring, everything shows the splash', () {
    expect(go(unknown, Routes.home), Routes.splash);
    expect(go(unknown, Routes.splash), isNull);
  });

  test('signed out users can only see auth screens', () {
    expect(go(signedOut, Routes.splash), Routes.login);
    expect(go(signedOut, Routes.home), Routes.login);
    expect(go(signedOut, Routes.profileSetup), Routes.login);
    expect(go(signedOut, Routes.login), isNull);
    expect(go(signedOut, Routes.signup), isNull);
    expect(go(signedOut, Routes.verifyOtp), isNull);
  });

  test('signed in users skip auth screens', () {
    for (final loc in [Routes.splash, Routes.login, Routes.signup, Routes.verifyOtp, Routes.profileSetup]) {
      expect(go(signedIn, loc), Routes.home, reason: loc);
    }
    expect(go(signedIn, Routes.home), isNull);
  });

  test('profile setup is forced until completed', () {
    expect(go(needsSetup, Routes.home), Routes.profileSetup);
    expect(go(needsSetup, Routes.verifyOtp), Routes.profileSetup);
    expect(go(needsSetup, Routes.profileSetup), isNull);
  });

  test('maintenance overrides everything', () {
    expect(go(signedIn, Routes.home, maintenance: true), Routes.maintenance);
    expect(go(unknown, Routes.splash, maintenance: true), Routes.maintenance);
    expect(go(signedIn, Routes.maintenance, maintenance: true), isNull);
  });

  test('leaving maintenance goes home or to login', () {
    expect(go(signedIn, Routes.maintenance), Routes.home);
    expect(go(signedOut, Routes.maintenance), Routes.login);
  });
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/features/auth/validators_test.dart test/core/router_test.dart`

Expected: a compilation error, because `validators.dart` and `router.dart` do not exist yet.

- [ ] **Step 3: Implement the validators and regions**

`lib/features/auth/validators.dart`:

```dart
import 'package:flutter/services.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// The backend's identifier is an EmailStr, so the app accepts email addresses only.
bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

final _namePattern = RegExp(r'^[\p{L}\p{M}\s]*$', unicode: true);

/// Same rule as the website's ProfileSetup: letters (any script), marks and spaces only.
final TextInputFormatter nameInputFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) => _namePattern.hasMatch(newValue.text) ? newValue : oldValue,
);
```

`lib/features/auth/farm_regions.dart`:

```dart
/// Same list as the website's FARM_REGIONS (src/utils/constants.js).
const List<String> farmRegions = [
  'Attock, Punjab',
  'Chakwal, Punjab',
  'Rawalpindi, Punjab',
  'Talagang, Punjab',
];
```

- [ ] **Step 4: Implement `appRedirect` in `lib/core/router.dart`**

```dart
import '../features/auth/auth_controller.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyOtp = '/verify-otp';
  static const profileSetup = '/profile-setup';
  static const maintenance = '/maintenance';
  static const home = '/home';
}

const _signedOutRoutes = {Routes.login, Routes.signup, Routes.verifyOtp};
const _authOnlyRoutes = {Routes.splash, ..._signedOutRoutes, Routes.profileSetup};

/// Decides where the user should be. Returns null to stay on [location].
String? appRedirect({
  required AuthState auth,
  required bool maintenance,
  required String location,
}) {
  if (maintenance) return location == Routes.maintenance ? null : Routes.maintenance;
  if (location == Routes.maintenance) {
    return auth.status == AuthStatus.signedIn ? Routes.home : Routes.login;
  }
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStatus.signedOut:
      return _signedOutRoutes.contains(location) ? null : Routes.login;
    case AuthStatus.signedIn:
      if (auth.needsProfileSetup) {
        return location == Routes.profileSetup ? null : Routes.profileSetup;
      }
      return _authOnlyRoutes.contains(location) ? Routes.home : null;
  }
}
```

- [ ] **Step 5: Run the tests to confirm they pass**

Run: `flutter test test/features/auth/validators_test.dart test/core/router_test.dart`

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/validators.dart lib/features/auth/farm_regions.dart lib/core/router.dart test/features/auth/validators_test.dart test/core/router_test.dart
git commit -m "feat: route decision function, email and name validators"
```

---

### Task 6: Theme, shared widgets, auth screens and app wiring

**Files:**
- Create:
  - `lib/core/theme.dart`
  - `lib/core/widgets/app_logo.dart`, `app_button.dart`, `language_switch.dart`, `toast.dart`
  - `lib/features/auth/widgets/otp_input.dart`
  - `lib/features/auth/screens/auth_scaffold.dart`, `splash_screen.dart`, `login_screen.dart`, `otp_screen.dart`, `profile_setup_screen.dart`
  - `lib/features/home/home_placeholder_screen.dart`
  - `lib/features/maintenance/maintenance_repository.dart`
  - `lib/features/maintenance/maintenance_screen.dart`. A minimal version here so the router compiles; Task 7 completes it.
  - `lib/app.dart`
- Modify: `lib/core/router.dart` (add `routerProvider`), `lib/main.dart` (replace)
- Test: `test/helpers/test_env.dart` (add `pumpPeanutApp`, `settle`), `test/features/auth/auth_flow_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 2–5.
- Produces:

  | Symbol | Signature / contract |
  |---|---|
  | `AppColors` | the colour constants from Global Constraints |
  | `buildAppTheme` | `ThemeData buildAppTheme(String languageCode, {bool useGoogleFonts = true})` |
  | `AppLogo` | `AppLogo({double size = 28, Color iconColor = AppColors.forest, Color leafColor = AppColors.gold})` |
  | `Wordmark` | `Wordmark({double fontSize = 22, Color color = AppColors.darkText, Color accent = AppColors.forest})` |
  | `AppButton` | `AppButton({required String label, required VoidCallback? onPressed, bool loading = false, Color? color})` |
  | `LanguageSwitch` | `LanguageSwitch({bool onDark = false})` |
  | `ToastType` | `enum { success, error, warning, info }` |
  | `showToast` | `void showToast(BuildContext context, String message, {String? subtext, ToastType type = ToastType.success})` |
  | `routerProvider` | `Provider<GoRouter>` |
  | `PeanutApp` | `PeanutApp({bool useGoogleFonts = true})` |
  | `MaintenanceStatus` | `{bool active, DateTime? endTime}` |
  | `MaintenanceRepository` | `fetchStatus()` returns `Future<MaintenanceStatus>` |
  | `maintenanceRepositoryProvider` | provides `MaintenanceRepository` |
  | test helpers | `pumpPeanutApp(tester, {FakeAdapter adapter, MemoryTokenStore? tokens, Map<String, Object> prefs})` returns `Future<ProviderContainer>`; `settle(tester)` |
  | widget keys used by tests | `Key('emailField')`, `Key('otpField')`, `Key('nameField')`, `Key('regionField')`, `Key('languageSwitch')` |

- [ ] **Step 1: Add the widget-test helpers**

Append to `test/helpers/test_env.dart`. Add these imports at the top of the file:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:peanutiq/app.dart';
import 'package:peanutiq/features/auth/auth_controller.dart';
```

Then append at the end:

```dart
/// Pumps frames for ~1s so fake HTTP futures and redirects settle.
/// Use this, not pumpAndSettle: the maintenance screen animates forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Starts the full app (real router, real screens) against fakes, then restores the session.
Future<ProviderContainer> pumpPeanutApp(
  WidgetTester tester, {
  required FakeAdapter adapter,
  MemoryTokenStore? tokens,
  Map<String, Object> prefs = const {},
}) async {
  final container = await createTestContainer(adapter: adapter, tokens: tokens, prefs: prefs);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const PeanutApp(useGoogleFonts: false),
  ));
  unawaited(container.read(authControllerProvider.notifier).restore());
  await settle(tester);
  return container;
}
```

- [ ] **Step 2: Write the failing widget test**

Create `test/features/auth/auth_flow_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peanutiq/features/auth/auth_controller.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_env.dart';

void main() {
  late FakeAdapter adapter;
  late MemoryTokenStore tokens;

  setUp(() {
    adapter = FakeAdapter();
    tokens = MemoryTokenStore();
    adapter.on('POST', '/auth/request-otp', 200, {'message': 'OTP sent successfully'});
  });

  Future<void> requestCode(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const Key('emailField')), email);
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('otpField')), code);
    await tester.pump();
    await tester.tap(find.text('Verify OTP'));
    await settle(tester);
  }

  testWidgets('with no stored session the login screen is shown', (tester) async {
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });

  testWidgets('an invalid email is rejected without calling the server', (tester) async {
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);
    await requestCode(tester, '+92 300 1234567');
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(adapter.requestsTo('/auth/request-otp'), isEmpty);
  });

  testWidgets('existing farmer: email, code, home', (tester) async {
    adapter.on('POST', '/auth/verify-otp', 200,
        {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson()});
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);

    await requestCode(tester, ' ali@example.com ');
    expect(find.text('Verify Account'), findsOneWidget);
    expect(find.text('ali@example.com'), findsOneWidget);
    expect(adapter.requestsTo('/auth/request-otp').single.data, {'identifier': 'ali@example.com'});

    await enterCode(tester, '123456');
    expect(find.textContaining('Welcome back, Ali!'), findsOneWidget);
    expect(tokens.token, 'tok');
  });

  testWidgets('wrong OTP shows the error and stays on the OTP screen', (tester) async {
    adapter.on('POST', '/auth/verify-otp', 401, {'detail': 'Invalid OTP'});
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);
    await requestCode(tester, 'ali@example.com');
    await enterCode(tester, '000000');
    expect(find.text('Verify Account'), findsOneWidget);
    expect(find.text('Invalid OTP'), findsOneWidget);
    expect(tokens.token, isNull);
  });

  testWidgets('Verify is disabled until 6 digits and letters are ignored', (tester) async {
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);
    await requestCode(tester, 'ali@example.com');
    await tester.enterText(find.byKey(const Key('otpField')), '12a4');
    await tester.pump();
    final button = tester.widget<FilledButton>(find.ancestor(
        of: find.text('Verify OTP'), matching: find.byType(FilledButton)));
    expect(button.onPressed, isNull);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('a'), findsNothing);
  });

  testWidgets('new farmer signs up through profile setup', (tester) async {
    adapter.on('POST', '/auth/verify-otp', 200, {
      'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(farmLocation: null, name: ''),
    });
    adapter.on('PUT', '/users/me', 200, userJson(farmLocation: 'Chakwal, Punjab'));
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);

    await tester.tap(find.text('Sign up'));
    await settle(tester);
    expect(find.text('Create an Account'), findsOneWidget);

    await requestCode(tester, 'ali@example.com');
    await enterCode(tester, '123456');
    expect(find.text('Complete Your Profile'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('nameField')), 'Ali 123');
    await tester.pump();
    expect(find.text('Ali 123'), findsNothing);
    await tester.enterText(find.byKey(const Key('nameField')), 'Ali');
    await tester.tap(find.byKey(const Key('regionField')));
    await settle(tester);
    await tester.tap(find.text('Chakwal, Punjab').last);
    await settle(tester);
    await tester.tap(find.text('Create Account'));
    await settle(tester);

    expect(adapter.requestsTo('/users/me').single.data, {
      'name': 'Ali',
      'farm_location': 'Chakwal, Punjab',
      'language_preference': 'english',
    });
    expect(find.textContaining('Welcome back, Ali!'), findsOneWidget);
  });

  testWidgets('admins are turned away with a message', (tester) async {
    adapter.on('POST', '/auth/verify-otp', 200,
        {'access_token': 'tok', 'token_type': 'bearer', 'user': userJson(role: 'admin')});
    final container = await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);
    await requestCode(tester, 'admin@example.com');
    await enterCode(tester, '123456');
    expect(find.textContaining('This app is for farmers'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(container.read(authControllerProvider).status, AuthStatus.signedOut);
    expect(tokens.token, isNull);
  });

  testWidgets('Urdu preference renders Urdu text right-to-left', (tester) async {
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens,
        prefs: {'preferredLanguage': 'ur'});
    expect(find.text('خوش آمدید!'), findsOneWidget);
    final context = tester.element(find.byKey(const Key('emailField')));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('the language switch changes the UI language', (tester) async {
    await pumpPeanutApp(tester, adapter: adapter, tokens: tokens);
    await tester.tap(find.byKey(const Key('languageSwitch')));
    await settle(tester);
    await tester.tap(find.text('اردو').last);
    await settle(tester);
    expect(find.text('خوش آمدید!'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test to confirm it fails**

Run: `flutter test test/features/auth/auth_flow_test.dart`

Expected: a compilation error, because `package:peanutiq/app.dart` does not exist yet.

- [ ] **Step 4: Write the theme**

`lib/core/theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const sand = Color(0xFFF9FAFC);
  static const forest = Color(0xFF07571C);
  static const terracotta = Color(0xFFE07A5F);
  static const charcoal = Color(0xFF3D4035);
  static const earth = Color(0xFFE5E7EB);
  static const gold = Color(0xFFF0C169);
  static const bannerGreen = Color(0xFF0F5A27);
  static const lime = Color(0xFFA3D977);
  static const authButton = Color(0xFF324329);
  static const authButtonPressed = Color(0xFF1A2315);
  static const darkText = Color(0xFF1D2B15);
  static const chartTerracotta = Color(0xFFC05A3B);
  static const healthGood = Color(0xFF22C55E);
  static const healthAverage = Color(0xFFEAB308);
  static const healthPoor = Color(0xFFEF4444);
  static const danger = Color(0xFFEF4444);
  static const seedOrange = Color(0xFFF97316);
  static const avatar = Color(0xFF2D5A27);
  static const muted = Color(0xFF6B7280);
  static const info = Color(0xFF3B82F6);
}

/// [useGoogleFonts] is false in tests, because google_fonts would try to download fonts.
ThemeData buildAppTheme(String languageCode, {bool useGoogleFonts = true}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.terracotta,
    surface: Colors.white,
    onSurface: AppColors.charcoal,
    error: AppColors.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.sand,
  );
  final textTheme = _textTheme(
    base.textTheme.apply(bodyColor: AppColors.charcoal, displayColor: AppColors.charcoal),
    languageCode,
    useGoogleFonts,
  );
  final radius12 = BorderRadius.circular(12);
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.earth),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
      border: border(AppColors.earth),
      enabledBorder: border(AppColors.earth),
      focusedBorder: border(AppColors.forest, 1.5),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.forest,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

TextTheme _textTheme(TextTheme base, String languageCode, bool useGoogleFonts) {
  if (!useGoogleFonts) return base;
  if (languageCode == 'ur') return GoogleFonts.notoNastaliqUrduTextTheme(base);
  final body = GoogleFonts.interTextTheme(base);
  final heading = GoogleFonts.plusJakartaSansTextTheme(base);
  return body.copyWith(
    displayLarge: heading.displayLarge,
    displayMedium: heading.displayMedium,
    displaySmall: heading.displaySmall,
    headlineLarge: heading.headlineLarge,
    headlineMedium: heading.headlineMedium,
    headlineSmall: heading.headlineSmall,
    titleLarge: heading.titleLarge,
  );
}
```

- [ ] **Step 5: Write the shared widgets**

`lib/core/widgets/app_logo.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// Port of the website's Logo: a bean with a small leaf at its top-end corner.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.iconColor = AppColors.forest,
    this.leafColor = AppColors.gold,
  });

  final double size;
  final Color iconColor;
  final Color leafColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(LucideIcons.bean, size: size, color: iconColor),
          Positioned(
            top: -size * 0.1,
            right: -size * 0.1,
            child: Transform.rotate(
              angle: -0.21,
              child: Icon(LucideIcons.leaf, size: size * 0.55, color: leafColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// "PeanutIQ" in serif, always left-to-right.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.fontSize = 22,
    this.color = AppColors.darkText,
    this.accent = AppColors.forest,
  });

  final double fontSize;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(text: 'Peanut', children: [
        TextSpan(text: 'IQ', style: TextStyle(color: accent)),
      ]),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}
```

> If `lucide_icons_flutter` exposes its class from a different import (for example `package:lucide_icons_flutter/lucide_icons_flutter.dart`), or an icon name differs, check `~/.pub-cache/hosted/pub.dev/lucide_icons_flutter-*/lib/` and adjust the import or name. Don't swap in a different icon set.

`lib/core/widgets/app_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-width primary button. Disabled while [loading] or when [onPressed] is null,
/// shown at 50% opacity like the website.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final background = color ?? AppColors.forest;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        disabledBackgroundColor: background.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(label),
    );
  }
}
```

`lib/core/widgets/language_switch.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/translations.dart';
import '../theme.dart';

/// English / اردو picker. Language names are shown in their own script.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeControllerProvider);
    final foreground = onDark ? Colors.white : AppColors.charcoal;
    return PopupMenuButton<String>(
      key: const Key('languageSwitch'),
      initialValue: code,
      onSelected: (value) => ref.read(localeControllerProvider.notifier).setLanguage(value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'ur', child: Text('اردو')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: foreground.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.globe, size: 14, color: foreground.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              code == 'ur' ? 'اردو' : 'English',
              style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: foreground.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
```

`lib/core/widgets/toast.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme.dart';

enum ToastType { success, error, warning, info }

/// Port of the website's ToastContext: one toast at a time, coloured start edge,
/// icon, optional subtext, close button, auto-hides after 3s.
void showToast(
  BuildContext context,
  String message, {
  String? subtext,
  ToastType type = ToastType.success,
}) {
  final (color, icon) = switch (type) {
    ToastType.success => (AppColors.healthGood, Icons.check_circle),
    ToastType.error => (AppColors.danger, Icons.error),
    ToastType.warning => (AppColors.healthAverage, Icons.warning_amber_rounded),
    ToastType.info => (AppColors.info, Icons.info),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    duration: const Duration(seconds: 3),
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    content: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 22),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(message,
                          style: const TextStyle(
                              color: AppColors.charcoal, fontWeight: FontWeight.w700)),
                      if (subtext != null)
                        Text(subtext,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                onPressed: messenger.hideCurrentSnackBar,
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}
```

- [ ] **Step 6: Write the OTP input**

`lib/features/auth/widgets/otp_input.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';

/// Six digit boxes backed by one invisible TextField. This gives auto-advance,
/// backspace, keyboard paste and long-press paste on Android without per-box focus juggling.
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.onChanged, this.length = 6});

  final ValueChanged<String> onChanged;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < widget.length; i++)
                _Box(
                  digit: i < code.length ? code[i] : '',
                  active: _focusNode.hasFocus &&
                      (i == code.length || (i == widget.length - 1 && code.length == widget.length)),
                ),
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const Key('otpField'),
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                ),
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.digit, required this.active});

  final String digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.forest : AppColors.earth,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.charcoal),
      ),
    );
  }
}
```

- [ ] **Step 7: Write the auth scaffold and splash screen**

`lib/features/auth/screens/auth_scaffold.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/language_switch.dart';

/// Mobile version of the website's AuthLayout: a green header (logo, tagline,
/// three features, language switch) above the form.
class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    return Scaffold(
      body: Column(
        children: [
          _AuthHeader(t: t),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bannerGreen, AppColors.forest],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppLogo(size: 28, iconColor: Colors.white, leafColor: AppColors.lime),
                  SizedBox(width: 8),
                  Wordmark(fontSize: 20, color: Colors.white, accent: AppColors.lime),
                  Spacer(),
                  LanguageSwitch(onDark: true),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                t.t('auth.app.tagline'),
                style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('auth.app.taglineDesc'),
                style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Feature(icon: LucideIcons.tractor, label: t.t('auth.app.featureSmart')),
                  _Feature(icon: LucideIcons.shieldCheck, label: t.t('auth.app.featureHealth')),
                  _Feature(icon: LucideIcons.wheat, label: t.t('auth.app.featureYield')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.lime),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/auth/screens/splash_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/widgets/app_logo.dart';

/// Shown while the stored session is being restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 56),
            SizedBox(height: 12),
            Wordmark(fontSize: 28),
            SizedBox(height: 24),
            SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Write the login/signup screen**

`lib/features/auth/screens/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../auth_controller.dart';
import '../validators.dart';
import 'auth_scaffold.dart';

/// Login and Signup are the same form (the backend creates new users on request-otp).
/// Only the copy and the "signup" flag passed to the OTP step differ.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.isSignup});

  final bool isSignup;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = ref.read(trProvider);
    final email = _email.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _error = t.t('auth.app.emailInvalid'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(email);
      if (!mounted) return;
      context.push(Uri(
        path: Routes.verifyOtp,
        queryParameters: {'email': email, if (widget.isSignup) 'signup': '1'},
      ).toString());
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e, t));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final textTheme = Theme.of(context).textTheme;
    final signup = widget.isSignup;
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.t(signup ? 'auth.signup.title' : 'auth.mockup.welcome'),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
                color: AppColors.authButton, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t.t(signup ? 'auth.signup.subtitle' : 'auth.mockup.loginDesc'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          TextField(
            key: const Key('emailField'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: t.t('auth.app.emailPlaceholder'),
              prefixIcon: const Icon(LucideIcons.mail, size: 20),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _email,
            builder: (context, value, _) => AppButton(
              label: t.t(signup ? 'auth.signup.sendOtp' : 'auth.login.sendOtp'),
              color: AppColors.authButton,
              loading: _loading,
              onPressed: value.text.trim().isEmpty ? null : _submit,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                t.t(signup ? 'auth.signup.hasAccount' : 'auth.login.noAccount'),
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              TextButton(
                onPressed: () => context.go(signup ? Routes.login : Routes.signup),
                child: Text(t.t(signup ? 'auth.signup.loginLink' : 'auth.login.signupLink')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 9: Write the OTP screen**

`lib/features/auth/screens/otp_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/toast.dart';
import '../auth_controller.dart';
import '../widgets/otp_input.dart';
import 'auth_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email, required this.isSignup});

  final String email;
  final bool isSignup;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _code = '';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.email.isEmpty) {
      // Same as the website: no email to verify means start over.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.login);
      });
    }
  }

  Future<void> _submit() async {
    final t = ref.read(trProvider);
    if (_code.length != 6) {
      setState(() => _error = t.t('auth.otp.errorLength'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final outcome = await ref.read(authControllerProvider.notifier).verifyOtp(
            email: widget.email,
            otp: _code,
            isSignup: widget.isSignup,
          );
      // On success, the router redirects to Home or Profile setup by itself.
      if (outcome == VerifyOutcome.blockedRole && mounted) {
        showToast(context, t.t('auth.app.farmersOnly'), type: ToastType.warning);
        context.go(Routes.login);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = _otpError(e, t));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _otpError(Object e, Translations t) => switch (e) {
        ServerException(detail: 'Invalid OTP') => t.t('auth.otp.errorInvalid'),
        ServerException(detail: final String detail) => detail,
        ServerException() => t.t('auth.otp.errorInvalid'),
        _ => describeError(e, t),
      };

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final textTheme = Theme.of(context).textTheme;
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.t('auth.otp.title'),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
                color: AppColors.authButton, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t.t('auth.otp.subtitle'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          OtpInput(onChanged: (code) => setState(() {
                _code = code;
                _error = null;
              })),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: t.t('auth.otp.submitBtn'),
            color: AppColors.authButton,
            loading: _loading,
            onPressed: _code.length == 6 ? _submit : null,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(t.t('auth.otp.notReceived'),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted)),
              // Inert, like the website's Resend button (spec: fidelity rule).
              TextButton(onPressed: () {}, child: Text(t.t('auth.otp.resendBtn'))),
            ],
          ),
          TextButton(
            onPressed: () => context.go(widget.isSignup ? Routes.signup : Routes.login),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(t.t('auth.otp.changeContact')),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 10: Write the profile setup screen**

`lib/features/auth/screens/profile_setup_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/toast.dart';
import '../auth_controller.dart';
import '../farm_regions.dart';
import '../validators.dart';
import 'auth_scaffold.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  String? _region;
  late String _language = ref.read(localeControllerProvider);
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty && _region != null;

  Future<void> _submit() async {
    final t = ref.read(trProvider);
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            name: _name.text,
            farmLocation: _region,
            languageCode: _language,
          );
      // The router moves to Home once needsProfileSetup is false.
    } on Object {
      if (mounted) showToast(context, t.t('auth.app.saveFailed'), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final textTheme = Theme.of(context).textTheme;
    Widget label(String key) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 14),
          child: Text(t.t(key),
              style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.muted)),
        );

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.t('auth.profileSetup.title'),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
                color: AppColors.authButton, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t.t('auth.profileSetup.subtitle'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          label('auth.profileSetup.fullName'),
          TextField(
            key: const Key('nameField'),
            controller: _name,
            inputFormatters: [nameInputFormatter],
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t.t('auth.profileSetup.namePlaceholder'),
              prefixIcon: const Icon(LucideIcons.user, size: 20),
            ),
          ),
          label('auth.profileSetup.farmLocation'),
          DropdownButtonFormField<String>(
            key: const Key('regionField'),
            initialValue: _region,
            hint: Text(t.t('auth.profileSetup.locationPlaceholder')),
            decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.mapPin, size: 20)),
            items: [
              for (final region in farmRegions)
                DropdownMenuItem(value: region, child: Text(region)),
            ],
            onChanged: (value) => setState(() => _region = value),
          ),
          label('auth.profileSetup.languagePreference'),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.languages, size: 20)),
            items: [
              DropdownMenuItem(value: 'en', child: Text(t.t('auth.profileSetup.langEnglish'))),
              DropdownMenuItem(value: 'ur', child: Text(t.t('auth.profileSetup.langUrdu'))),
            ],
            onChanged: (value) => setState(() => _language = value ?? _language),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: t.t('auth.profileSetup.submitBtn'),
            color: AppColors.authButton,
            loading: _loading,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
```

> `initialValue` replaced the deprecated `value` parameter of `DropdownButtonFormField` in Flutter 3.35. If `flutter analyze` reports it as undefined on your SDK, use `value:` instead.

- [ ] **Step 11: Write the maintenance repository, a minimal maintenance screen and the home placeholder**

`lib/features/maintenance/maintenance_repository.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class MaintenanceStatus {
  const MaintenanceStatus({required this.active, this.endTime});

  factory MaintenanceStatus.fromJson(Map<String, dynamic> json) => MaintenanceStatus(
        active: json['active'] == true,
        endTime: json['end_time'] is String ? DateTime.tryParse(json['end_time'] as String) : null,
      );

  final bool active;
  final DateTime? endTime;
}

class MaintenanceRepository {
  MaintenanceRepository(this._api);

  final ApiClient _api;

  /// Public endpoint: it never returns 503 itself.
  Future<MaintenanceStatus> fetchStatus() async => MaintenanceStatus.fromJson(
      await _api.get('/admin/system/maintenance/status') as Map<String, dynamic>);
}

final maintenanceRepositoryProvider =
    Provider<MaintenanceRepository>((ref) => MaintenanceRepository(ref.watch(apiClientProvider)));
```

`lib/features/maintenance/maintenance_screen.dart`. This is the minimal version; Task 7 replaces it:

```dart
import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
```

`lib/features/home/home_placeholder_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/widgets/app_logo.dart';
import '../auth/auth_controller.dart';

/// Temporary landing screen for Phase 1. Phase 2 replaces it with the tab shell and Dashboard.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Wordmark(fontSize: 20)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.t('dashboard.welcome',
                  args: {'name': user?.name ?? '', 'location': user?.farmLocation ?? ''}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text(t.t('common.logout')),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 12: Add `routerProvider`**

Add these imports at the top of `lib/core/router.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/home_placeholder_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import 'maintenance_mode.dart';
```

Keep the existing `import '../features/auth/auth_controller.dart';`. Then append at the end of the file:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever auth or maintenance state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(maintenanceModeProvider, (_, __) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      auth: ref.read(authControllerProvider),
      maintenance: ref.read(maintenanceModeProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen(isSignup: false)),
      GoRoute(path: Routes.signup, builder: (_, __) => const LoginScreen(isSignup: true)),
      GoRoute(
        path: Routes.verifyOtp,
        builder: (_, state) => OtpScreen(
          email: state.uri.queryParameters['email'] ?? '',
          isSignup: state.uri.queryParameters['signup'] == '1',
        ),
      ),
      GoRoute(path: Routes.profileSetup, builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: Routes.maintenance, builder: (_, __) => const MaintenanceScreen()),
      GoRoute(path: Routes.home, builder: (_, __) => const HomePlaceholderScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
```

> If the analyzer flags `(_, __)` as an unnecessary-underscores lint on Dart 3.13, use `(_, _)`. Dart 3.7+ allows repeated `_` wildcards.

- [ ] **Step 13: Write `lib/app.dart` and replace `lib/main.dart`**

`lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/translations.dart';
import 'core/router.dart';
import 'core/theme.dart';

class PeanutApp extends ConsumerWidget {
  const PeanutApp({super.key, this.useGoogleFonts = true});

  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'PeanutIQ',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildAppTheme(languageCode, useGoogleFonts: useGoogleFonts),
      // Locale 'ur' makes the whole app right-to-left.
      locale: Locale(languageCode),
      supportedLocales: [for (final code in supportedLanguageCodes) Locale(code)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
```

`lib/main.dart` (replace the generated file entirely):

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/i18n/translations.dart';
import 'core/storage.dart';
import 'features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bundles = await loadTranslationBundles();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    translationBundlesProvider.overrideWithValue(bundles),
  ]);
  // The splash screen shows until this finishes; the router then redirects.
  unawaited(container.read(authControllerProvider.notifier).restore());
  runApp(UncontrolledProviderScope(container: container, child: const PeanutApp()));
}
```

- [ ] **Step 14: Run the test to confirm it passes**

Run: `flutter test test/features/auth/auth_flow_test.dart`

Expected: `All tests passed!`

If "language switch" can't find `اردو` in the menu, the popup may need another frame: add `await tester.pump(const Duration(milliseconds: 300));` after opening it. Don't change the assertion.

- [ ] **Step 15: Run the whole suite and the analyzer**

Run: `flutter test && flutter analyze`

Expected: `All tests passed!` and `No issues found!`

- [ ] **Step 16: Commit**

```bash
git add lib test
git commit -m "feat: auth screens, theme, router and app wiring"
```

---

### Task 7: Maintenance screen

**Files:**
- Replace: `lib/features/maintenance/maintenance_screen.dart`
- Test: `test/features/maintenance/maintenance_screen_test.dart`

**Interfaces:**
- Consumes:
  - `maintenanceRepositoryProvider`, `MaintenanceStatus` (Task 6);
  - `maintenanceModeProvider` (Task 3);
  - `authControllerProvider` (Task 4);
  - `trProvider` (Task 2);
  - `AppButton` (Task 6);
  - `pumpPeanutApp`, `settle`, `userJson` (test helpers).
- Produces: `MaintenanceScreen` (no parameters).

- [ ] **Step 1: Write the failing test**

Create `test/features/maintenance/maintenance_screen_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_env.dart';

void main() {
  late FakeAdapter adapter;

  setUp(() {
    adapter = FakeAdapter();
    adapter.on('GET', '/users/me', 503, {'detail': 'System under maintenance'});
    adapter.on('GET', '/admin/system/maintenance/status', 200,
        {'active': true, 'end_time': '2026-09-23T15:30:00Z'});
  });

  Future<void> start(WidgetTester tester, MemoryTokenStore tokens) => pumpPeanutApp(
        tester,
        adapter: adapter,
        tokens: tokens,
        prefs: {'peanutiq_user': jsonEncode(userJson())},
      );

  testWidgets('503 at startup shows the maintenance screen with the end time', (tester) async {
    await start(tester, MemoryTokenStore('tok'));
    expect(find.text("We'll be right back!"), findsOneWidget);
    expect(find.text('Expected Completion'), findsOneWidget);
    expect(adapter.requestsTo('/admin/system/maintenance/status'), isNotEmpty);
  });

  testWidgets('Check Status returns home once maintenance is over', (tester) async {
    await start(tester, MemoryTokenStore('tok'));
    adapter.on('GET', '/admin/system/maintenance/status', 200, {'active': false});
    await tester.tap(find.text('Check Status'));
    await settle(tester);
    expect(find.textContaining('Welcome back, Ali!'), findsOneWidget);
  });

  testWidgets('polls the status every minute', (tester) async {
    await start(tester, MemoryTokenStore('tok'));
    final before = adapter.requestsTo('/admin/system/maintenance/status').length;
    await tester.pump(const Duration(seconds: 61));
    await settle(tester);
    expect(adapter.requestsTo('/admin/system/maintenance/status').length, before + 1);
  });

  testWidgets('Sign out goes to login, not back to maintenance', (tester) async {
    final tokens = MemoryTokenStore('tok');
    await start(tester, tokens);
    await tester.tap(find.text('Sign out and return to login'));
    await settle(tester);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(tokens.token, isNull);
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/features/maintenance/maintenance_screen_test.dart`

Expected: FAIL. `"We'll be right back!"` is not found, because the placeholder screen renders nothing.

- [ ] **Step 3: Implement the maintenance screen**

Replace `lib/features/maintenance/maintenance_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/maintenance_mode.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_button.dart';
import '../auth/auth_controller.dart';
import 'maintenance_repository.dart';

/// Shown whenever the API returns 503. Polls every 60s; when the window ends it
/// clears maintenance mode and the router moves on (Home or Login).
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  Timer? _poll;
  bool _checking = false;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _check();
    _poll = Timer.periodic(const Duration(seconds: 60), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _spin.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status = await ref.read(maintenanceRepositoryProvider).fetchStatus();
      if (!mounted) return;
      if (status.active) {
        setState(() => _endTime = status.endTime);
      } else {
        ref.read(maintenanceModeProvider.notifier).exit();
      }
    } on Object {
      // Offline or server error: keep showing this screen and try again on the next tick.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).logout();
    ref.read(maintenanceModeProvider.notifier).exit();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final textTheme = Theme.of(context).textTheme;
    final endTime = _endTime;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.forest, AppColors.earth]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.sand,
                            shape: BoxShape.circle,
                          ),
                          child: RotationTransition(
                            turns: _spin,
                            child: const Icon(LucideIcons.settings, size: 40, color: AppColors.forest),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.t('maintenance.title'),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.t('maintenance.desc'),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.charcoal.withValues(alpha: 0.7)),
                        ),
                        if (endTime != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(t.t('maintenance.expected'),
                                    style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700, color: AppColors.muted)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('hh:mm a', 'en_US').format(endTime.toLocal()),
                                  textDirection: TextDirection.ltr,
                                  style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900, color: AppColors.forest),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppButton(
                          label: t.t(_checking ? 'maintenance.checking' : 'maintenance.check'),
                          onPressed: _check,
                          loading: false,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _signOut,
                          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                          child: Text(t.t('maintenance.signOut')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/features/maintenance/maintenance_screen_test.dart`

Expected: `All tests passed!`

- [ ] **Step 5: Run the whole suite and the analyzer**

Run: `flutter test && flutter analyze`

Expected: `All tests passed!` and `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/maintenance test/features/maintenance
git commit -m "feat: maintenance screen with polling, status check and sign out"
```

---

### Task 8: README and manual check on the emulator

**Files:**
- Create: `README.md` (replacing the generated one)

- [ ] **Step 1: Write the README**

Replace `README.md` with:

````markdown
# PeanutIQ Mobile (Farmer app)

Flutter Android app for PeanutIQ farmers. It talks to the PeanutIQ FastAPI backend (a separate repo).

## Requirements
- Flutter 3.47+ (`flutter --version`)
- Android Studio (for its emulator) or an Android phone with USB debugging
- VS Code with the **Flutter** extension (recommended editor)

## Run
1. Start the backend on your Mac on port 8000.
2. Start an emulator: in VS Code, open the command palette, run "Flutter: Launch Emulator".
3. Run the app:

   ```bash
   flutter pub get
   flutter run                      # emulator: reaches the Mac at 10.0.2.2
   flutter run --dart-define=API_URL=http://<your-mac-LAN-IP>:8000/api/v1   # real phone
   ```

   In VS Code you can also press F5.

## Test
```bash
flutter test
flutter analyze
```

## Translations
Strings live in `assets/translations/{en,ur}.json` (i18next format, copied from the website).
To add keys: write a `{"en": {...}, "ur": {...}}` file under `tool/translations/`, then run:

```bash
python3 tool/merge_translations.py tool/translations/<file>.json
```

## Docs
- Design spec: `docs/superpowers/specs/`
- Implementation plans: `docs/superpowers/plans/`
````

- [ ] **Step 2: Manual check against the real backend**

With the backend running on the Mac, run `flutter run` on the Android emulator and check each of these:

1. **Launch:** the splash screen appears briefly, then Login.
2. **Language:** switch to اردو. Text becomes Urdu and the layout flips right-to-left. Switch back.
3. **Login:** enter a real email you can read and tap Send OTP. The OTP screen shows that email, and the code arrives by email.
4. **Wrong code:** enter a wrong code. "Invalid OTP" appears and you stay on the screen.
5. **Correct code:**
   - a new email goes to Profile setup: fill it in, and it continues to Home;
   - an existing farmer goes straight to Home, which shows "Welcome back, <name>!".
6. **Session restore:** fully close the app and reopen it. It goes straight to Home.
7. **Log out:** returns to Login. Reopen the app: it shows Login.
8. **Maintenance** (optional, needs an admin on the website): schedule a maintenance window covering now, then reopen the app as a farmer. The maintenance screen appears. After the window ends, tap Check Status: you return to Home.

If any step fails, fix it with a test before continuing; don't commit untested fixes.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: README with run, test and translation instructions"
```

---

## What comes next

These phases each get their own plan, written once the previous phase is merged so they can use its real code:

- **Phase 2:** tab shell, top bar, More tab, Dashboard
- **Phase 3:** Seed and Disease scan flow, PDF report
- **Phase 4:** History, Advisories
- **Phase 5:** Knowledge Base
- **Phase 6:** Profile
- **Phase 7:** AI assistant
- **Phase 8:** polish, including bundling fonts offline, app icon, and an Urdu review
