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
      ServerException(detail: final String detail) => _knownDetail(detail, t) ?? detail,
      _ => t.t('common.serverError'),
    };

/// The backend's messages are English; the ones the app can meet are translated here.
String? _knownDetail(String detail, Translations t) {
  final key = switch (detail) {
    'Incorrect email or password' => 'common.serverErrors.badCredentials',
    'Email already registered' => 'common.serverErrors.emailTaken',
    'User not found' => 'common.serverErrors.userNotFound',
    'System under maintenance' => 'common.serverErrors.maintenance',
    'AI assistant is busy. Please try again.' => 'common.serverErrors.aiBusy',
    'Daily AI limit reached' => 'common.serverErrors.aiLimit',
    'Weather is unavailable' => 'dashboard.app.weatherUnavailable',
    "This photo doesn't show peanut seeds. Take a clear photo of the seeds on a plain surface." =>
      'common.serverErrors.notSeeds',
    'No seeds could be counted. Take a clearer, closer photo of the seeds.' => 'common.serverErrors.noSeeds',
    "This photo doesn't show a peanut plant or pest. Take a clear, close photo of the affected leaves, plant or insect." =>
      'common.serverErrors.notCrop',
    'File is too large' => 'common.serverErrors.tooLarge',
    _ when detail.startsWith('Not authorized') => 'common.serverErrors.notAuthorized',
    _ => null,
  };
  return key == null ? null : t.t(key);
}
