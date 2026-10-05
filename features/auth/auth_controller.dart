import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/i18n/translations.dart';
import '../../core/storage.dart';
import 'data/app_user.dart';
import 'data/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

enum LoginOutcome { signedIn, blockedRole }

class AuthState {
  const AuthState._(this.status, this.user, this.firstLaunch);

  const AuthState.unknown() : this._(AuthStatus.unknown, null, false);

  const AuthState.signedOut({bool firstLaunch = false})
      : this._(AuthStatus.signedOut, null, firstLaunch);

  const AuthState.signedIn(AppUser user) : this._(AuthStatus.signedIn, user, false);

  final AuthStatus status;
  final AppUser? user;

  /// Signed out on a phone that has never had an account: the router opens Create Account.
  final bool firstLaunch;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);
  AppPrefs get _prefs => ref.read(appPrefsProvider);

  /// Called once at startup: loads the stored session and refreshes it from the server.
  Future<void> restore() async {
    String? token;
    try {
      token = await _tokens.read();
    } on Object {
      // Keystore failure: treat as signed out instead of leaving the splash up forever.
      token = null;
    }
    if (token == null || token.isEmpty) {
      await logout();
      return;
    }
    final cached = _readCachedUser();
    // Show the cached session at once. A network that connects but never answers
    // (captive portal, weak signal) must not keep the farmer on the splash.
    if (cached != null && cached.isFarmer) state = AuthState.signedIn(cached);
    try {
      final user = await _repo.fetchMe();
      if (!user.isFarmer) {
        await logout();
        return;
      }
      await _saveUser(user);
      await _applyServerLanguage(user);
      state = AuthState.signedIn(user);
    } on UnauthorizedException {
      await logout();
    } on Object {
      // Offline, maintenance, or an unexpected response: keep the cached session if there is one.
      // Catching everything matters: main() doesn't await restore(), so an escaped
      // error would leave the app on the splash screen forever.
      if (cached == null) await logout();
    }
  }

  /// Creates the account and stays signed out: the screen sends the farmer to Sign In.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String farmLocation,
    required String languageCode,
    required String timezone,
  }) async {
    await _repo.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
      farmLocation: farmLocation,
      language: serverLanguageFromCode(languageCode),
      timezone: timezone,
    );
    await _prefs.setHasAccount();
    state = const AuthState.signedOut();
  }

  /// The password is sent as typed: spaces can be part of it.
  Future<LoginOutcome> login({required String email, required String password}) async {
    final result = await _repo.login(email.trim(), password);
    if (!result.user.isFarmer) return LoginOutcome.blockedRole;
    await _tokens.write(result.token);
    var user = result.user;
    if (ref.read(localeControllerProvider.notifier).hasSavedPreference) {
      user = await _saveLocalLanguageToServer(user);
    } else {
      await _applyServerLanguage(user);
    }
    await _saveUser(user);
    state = AuthState.signedIn(user);
    return LoginOutcome.signedIn;
  }

  Future<void> updateProfile({
    String? name,
    String? farmLocation,
    String? languageCode,
    String? timezone,
  }) async {
    final user = await _repo.updateMe({
      if (name != null) 'name': name.trim(),
      'farm_location': ?farmLocation,
      if (languageCode != null) 'language_preference': serverLanguageFromCode(languageCode),
      'timezone': ?timezone,
    });
    await _saveUser(user);
    await _applyServerLanguage(user);
    state = AuthState.signedIn(user);
  }

  Future<void> logout() async {
    state = AuthState.signedOut(firstLaunch: !_prefs.hasAccount);
    await _clearSession();
  }

  /// Called by ApiClient when a protected request returns 401.
  void handleUnauthorized() {
    if (state.status == AuthStatus.signedOut) return;
    state = const AuthState.signedOut();
    unawaited(_clearSession());
  }

  AppUser? _readCachedUser() {
    final json = _prefs.userJson;
    if (json == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> _saveUser(AppUser user) async {
    await _prefs.setUserJson(jsonEncode(user.toJson()));
    await _prefs.setHasAccount();
  }

  /// The farmer picked a language on the login screen. Store it on the server too,
  /// otherwise the next restore() would switch the app back to the server's language.
  Future<AppUser> _saveLocalLanguageToServer(AppUser user) async {
    final local = ref.read(localeControllerProvider);
    if (languageCodeFromServer(user.languagePreference) == local) return user;
    try {
      return await _repo.updateMe({'language_preference': serverLanguageFromCode(local)});
    } on Object {
      return user; // Not worth blocking sign-in over; the next login retries.
    }
  }

  Future<void> _applyServerLanguage(AppUser user) async {
    final code = languageCodeFromServer(user.languagePreference);
    if (code != null) await ref.read(localeControllerProvider.notifier).setLanguage(code);
  }

  Future<void> _clearSession() async {
    try {
      await _tokens.clear();
    } on Object {
      // Nothing more to do: the session is already signed out in memory.
    }
    await _prefs.setUserJson(null);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user's id, or null. Data providers watch this so they refetch per user.
final currentUserIdProvider =
    Provider<String?>((ref) => ref.watch(authControllerProvider.select((s) => s.user?.id)));
