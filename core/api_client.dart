import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import 'config.dart';
import 'demo/demo_backend.dart';
import 'errors.dart';
import 'maintenance_mode.dart';
import 'storage.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._tokenStore,
    required this._onUnauthorized,
    required this._onMaintenance,
    HttpClientAdapter? adapter,
  })  : _dio = Dio(BaseOptions(
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

  /// [timeout] overrides the 30 s receive timeout (AI replies can take longer).
  Future<dynamic> post(String path, {Object? data, Duration? timeout}) => _send(() => _dio.post<dynamic>(
        path,
        data: data,
        options: timeout == null ? null : Options(receiveTimeout: timeout),
      ));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  /// Raw bytes from an absolute URL (e.g. a scan image for the PDF). Same token and errors.
  Future<Uint8List> getBytes(String absoluteUrl) async {
    // Demo-mode images live in the app bundle or on the device, not on a server.
    final uri = Uri.parse(absoluteUrl);
    if (uri.scheme == 'asset') {
      final data = await rootBundle.load(uri.path.replaceFirst('/', ''));
      return data.buffer.asUint8List();
    }
    if (uri.scheme == 'file') return File.fromUri(uri).readAsBytes();
    final data = await _send(() => _dio.get<dynamic>(
          absoluteUrl,
          options: Options(responseType: ResponseType.bytes),
        ));
    return Uint8List.fromList(data as List<int>);
  }

  /// multipart/form-data upload (e.g. POST /scans/). Dio sets the boundary header.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String filePath,
    String fileField = 'file',
    String? contentType,
    Duration? timeout,
  }) async {
    final form = FormData.fromMap({
      ...fields,
      fileField: await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
        contentType: contentType == null ? null : DioMediaType.parse(contentType),
      ),
    });
    return _send(() => _dio.post<dynamic>(
          path,
          data: form,
          options: timeout == null ? null : Options(receiveTimeout: timeout),
        ));
  }

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

final demoModeProvider = Provider<bool>((ref) => demoMode);

/// null means Dio's real network adapter. Demo mode answers from built-in sample data;
/// tests override this with a FakeAdapter.
final httpAdapterProvider = Provider<HttpClientAdapter?>(
  (ref) => ref.watch(demoModeProvider) ? DemoBackendAdapter() : null,
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      baseUrl: apiBaseUrl,
      tokenStore: ref.watch(tokenStoreProvider),
      adapter: ref.watch(httpAdapterProvider),
      onUnauthorized: () => ref.read(authControllerProvider.notifier).handleUnauthorized(),
      onMaintenance: () => ref.read(maintenanceModeProvider.notifier).enter(),
    ));
