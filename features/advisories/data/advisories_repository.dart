import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'advisory.dart';

class AdvisoriesRepository {
  AdvisoriesRepository(this._api);

  final ApiClient _api;

  /// Newest first. The backend defaults to 5 results when [limit] is omitted.
  Future<List<Advisory>> fetch({String? type, int? limit}) async {
    final data = await _api.get('/dashboard/advisories', query: {
      'type': ?type,
      'limit': ?limit,
    }) as List<dynamic>;
    return [for (final item in data) Advisory.fromJson(item as Map<String, dynamic>)];
  }
}

final advisoriesRepositoryProvider =
    Provider<AdvisoriesRepository>((ref) => AdvisoriesRepository(ref.watch(apiClientProvider)));
