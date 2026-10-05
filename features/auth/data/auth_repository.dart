import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'app_user.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Creates the account. It does not sign in: the farmer signs in next with the password.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String farmLocation,
    required String language,
    required String timezone,
  }) async =>
      AppUser.fromJson(await _api.post('/auth/register', data: {
        'name': name,
        'identifier': email,
        'password': password,
        'farm_location': farmLocation,
        'language_preference': language,
        'timezone': timezone,
      }) as Map<String, dynamic>);

  Future<({String token, AppUser user})> login(String email, String password) async {
    final data = await _api.post('/auth/login', data: {'identifier': email, 'password': password})
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
