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
  static const _hasAccountKey = 'peanutiq_has_account';
  final SharedPreferences _prefs;

  String? get userJson => _prefs.getString(_userKey);

  Future<void> setUserJson(String? json) async {
    if (json == null) {
      await _prefs.remove(_userKey);
    } else {
      await _prefs.setString(_userKey, json);
    }
  }

  /// True once an account has been created or used on this phone. Until then the app
  /// opens on Create Account instead of Sign In. Kept after sign-out.
  bool get hasAccount => _prefs.getBool(_hasAccountKey) ?? false;

  Future<void> setHasAccount() async {
    await _prefs.setBool(_hasAccountKey, true);
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
