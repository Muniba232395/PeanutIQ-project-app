import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';

import 'demo_seed.dart';

/// Demo mode: answers every endpoint the app uses from in-memory sample data, so the app
/// runs with no backend. It sits below the ApiClient, so all the real app code runs.
/// Sign in as demo@peanutiq.app / peanut123, or create an account (kept until the app closes).
class DemoBackendAdapter implements HttpClientAdapter {
  DemoBackendAdapter({
    this.latency = const Duration(milliseconds: 350),
    Future<Directory> Function()? tempDir,
    DateTime Function()? clock,
  })  : _tempDir = tempDir ?? getTemporaryDirectory,
        _clock = clock ?? DateTime.now {
    _advisories = seedAdvisories(_ago);
    _articles = seedArticles(_ago);
  }

  static const demoPassword = 'peanut123';

  final Duration latency;
  final Future<Directory> Function() _tempDir;
  final DateTime Function() _clock;

  final _users = <String, Map<String, dynamic>>{};
  final _passwords = <String, String>{demoAccountEmail: demoPassword};
  final _actions = <String, List<Map<String, dynamic>>>{};
  final _activities = <String, List<Map<String, dynamic>>>{};
  final _scans = <String, List<Map<String, dynamic>>>{};
  late final List<Map<String, dynamic>> _advisories;
  late final List<Map<String, dynamic>> _articles;
  var _nextId = 1;

  String _stamp(DateTime utc) => DateFormat("yyyy-MM-dd'T'HH:mm:ss", 'en_US').format(utc);
  String _ago(Duration d) => _stamp(_clock().toUtc().subtract(d));
  String _ahead(Duration d) => _stamp(_clock().toUtc().add(d));

  Map<String, dynamic> _userFor(String email) => _users.putIfAbsent(email, () {
        _actions[email] = seedActions(_ahead);
        _activities[email] = seedActivities(_ago);
        _scans[email] = seedScans(_ago);
        return seedDemoFarmer(email);
      });

  String _normalEmail(Object? value) => '${value ?? ''}'.trim().toLowerCase();

  /// Creates the account only; the app signs in separately with the password.
  ResponseBody _register(Map data) {
    final email = _normalEmail(data['identifier']);
    final password = '${data['password'] ?? ''}';
    if (!email.contains('@')) return _json(422, {'detail': 'Invalid email address'});
    if (password.length < 8) return _json(422, {'detail': 'Password must be at least 8 characters'});
    if (_passwords.containsKey(email)) return _json(400, {'detail': 'Email already registered'});
    _passwords[email] = password;
    final user = _userFor(email)
      ..['name'] = '${data['name'] ?? ''}'.trim()
      ..['farm_location'] = data['farm_location']
      ..['language_preference'] = data['language_preference'] ?? 'english'
      ..['timezone'] = data['timezone'] ?? 'UTC';
    return _json(201, user);
  }

  /// Tokens carry the email, so a stored session still works after the app restarts.
  String? _emailFromToken(RequestOptions options) {
    final header = options.headers['Authorization'] as String?;
    if (header == null || !header.startsWith('Bearer demo:')) return null;
    return header.substring('Bearer demo:'.length);
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final path = options.uri.path.replaceFirst(RegExp(r'^.*/api/v1'), '');
    final method = options.method;
    final query = options.uri.queryParameters;
    Object? body = options.data;
    if (body is String && body.isNotEmpty) body = jsonDecode(body);

    // Public endpoints
    if (method == 'POST' && path == '/auth/register') return _register(body as Map);
    if (method == 'POST' && path == '/auth/login') {
      final data = body as Map;
      final email = _normalEmail(data['identifier']);
      // Same message for an unknown email, so the screen doesn't reveal who has an account.
      if (_passwords[email] == null || _passwords[email] != '${data['password']}') {
        return _json(401, {'detail': 'Incorrect email or password'});
      }
      return _json(200, {'access_token': 'demo:$email', 'token_type': 'bearer', 'user': _userFor(email)});
    }
    if (method == 'GET' && path == '/admin/system/maintenance/status') return _json(200, {'active': false});

    final email = _emailFromToken(options);
    if (email == null) return _json(401, {'detail': 'Could not validate credentials'});
    final user = _userFor(email);
    int? limit(int fallback) => int.tryParse(query['limit'] ?? '') ?? fallback;

    switch ((method, path)) {
      case ('GET', '/users/me'):
        return _json(200, user);
      case ('PUT', '/users/me'):
        (body as Map).forEach((k, v) {
          if (v != null) user['$k'] = v;
        });
        return _json(200, user);
      case ('GET', '/dashboard/activities'):
        return _json(200, _activities[email]!.take(limit(10)!).toList());
      case ('POST', '/dashboard/activities'):
        final entry = {..._logEntry(email, '${(body as Map)['action']}', body['details'] as String?)};
        return _json(201, entry);
      case ('GET', '/dashboard/advisories'):
        final type = query['type'];
        return _json(200, [for (final a in _advisories) if (type == null || a['type'] == type) a].take(limit(5)!).toList());
      case ('GET', '/dashboard/weather'):
        // The website's sample forecast.
        String day(int ahead) => DateFormat('yyyy-MM-dd', 'en_US').format(_clock().add(Duration(days: ahead)));
        return _json(200, {
          'current': {'temp_c': 32, 'condition': 'sunny'},
          'days': [
            {'date': day(0), 'max_c': 33, 'min_c': 21, 'condition': 'sunny'},
            {'date': day(1), 'max_c': 29, 'min_c': 20, 'condition': 'rain'},
            {'date': day(2), 'max_c': 30, 'min_c': 19, 'condition': 'breezy'},
          ],
        });
      case ('GET', '/dashboard/crop-profile'):
        return _json(200, {
          'id': 'crop-1',
          'user_id': user['id'],
          'stage': 'pegging',
          'health_good_pct': 72,
          'health_average_pct': 18,
          'health_poor_pct': 10,
          'sowing_date': _ago(const Duration(days: 60)),
          'updated_at': _ago(const Duration(days: 1)),
        });
      case ('GET', '/dashboard/actions'):
        return _json(200, _actions[email]);
      case ('GET', '/scans/'):
        return _json(200, _scans[email]);
      case ('POST', '/scans/'):
        return _json(201, await _saveScan(email, options, requestStream));
      case ('GET', '/knowledge/articles'):
        return _json(200, _articles);
    }
    if (method == 'PUT' && path.startsWith('/dashboard/actions/')) {
      final id = path.split('/').last;
      for (final action in _actions[email]!) {
        if (action['id'] == id) {
          action['is_completed'] = (body as Map)['is_completed'] == true;
          return _json(200, action);
        }
      }
    }
    return _json(404, {'detail': 'Not Found'});
  }

  Map<String, dynamic> _logEntry(String email, String action, String? details) {
    final entry = {'id': 'log-${_nextId++}', 'action': action, 'details': details, 'timestamp': _ago(Duration.zero)};
    _activities[email]!.insert(0, entry);
    return entry;
  }

  /// Parses the multipart body, keeps the photo in the temp folder, and records the scan.
  Future<Map<String, dynamic>> _saveScan(String email, RequestOptions options, Stream<Uint8List>? stream) async {
    final bytes = <int>[];
    if (stream != null) {
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
    }
    final contentType = '${options.headers[Headers.contentTypeHeader] ?? options.contentType ?? ''}';
    final boundary = RegExp(r'boundary=([^;]+)').firstMatch(contentType)?.group(1)?.replaceAll('"', '');
    final fields = <String, String>{};
    List<int>? fileBytes;
    var fileName = 'scan.jpg';
    if (boundary != null) {
      final text = latin1.decode(bytes);
      for (final part in text.split('--$boundary')) {
        final split = part.indexOf('\r\n\r\n');
        if (split < 0) continue;
        final headers = part.substring(0, split);
        var content = part.substring(split + 4);
        if (content.endsWith('\r\n')) content = content.substring(0, content.length - 2);
        final name = RegExp(r'name="([^"]*)"').firstMatch(headers)?.group(1);
        final file = RegExp(r'filename="([^"]*)"').firstMatch(headers)?.group(1);
        if (file != null) {
          fileBytes = latin1.encode(content);
          fileName = file;
        } else if (name != null) {
          fields[name] = utf8.decode(latin1.encode(content));
        }
      }
    }
    var imageUrl = '';
    if (fileBytes != null) {
      final dir = await _tempDir();
      final saved = File('${dir.path}/demo-scan-${_nextId++}-$fileName');
      await saved.writeAsBytes(fileBytes);
      imageUrl = saved.uri.toString();
    }
    final disease = fields['type'] == 'Disease Intelligence';
    // The real backend has Gemini analyse the photo; demo mode returns the website's sample result.
    final analysis = fields['analyze'] == 'true' ? (disease ? demoDiseaseAnalysis : demoSeedAnalysis) : null;
    final record = {
      'id': 'scan-${_nextId++}',
      'type': fields['type'] ?? '',
      'title': analysis == null ? fields['title'] ?? '' : (disease ? 'Early Leaf Spot Detection' : 'Seed Lot Grade A'),
      'status': analysis == null ? fields['status'] ?? '' : (disease ? 'High Risk' : 'Healthy'),
      'confidence_score': analysis == null
          ? double.tryParse(fields['confidence_score'] ?? '') ?? 0
          : (analysis['confidence_pct'] as num).toDouble(),
      'image_url': imageUrl,
      'created_at': _ago(Duration.zero),
      'analysis': analysis,
    };
    _scans[email]!.insert(0, record);
    // The real backend logs every scan as an activity too.
    _logEntry(email, disease ? 'Disease Analysis' : 'Seed Quality Scan', record['status'] as String?);
    return record;
  }

  ResponseBody _json(int status, Object? data) => ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
