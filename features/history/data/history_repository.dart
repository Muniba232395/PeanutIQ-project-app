import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'scan_record.dart';

class HistoryRepository {
  HistoryRepository(this._api);

  final ApiClient _api;

  /// Newest first (the backend orders by created_at desc).
  Future<List<ScanRecord>> fetchScans() async {
    final data = await _api.get('/scans/') as List<dynamic>;
    return [for (final item in data) ScanRecord.fromJson(item as Map<String, dynamic>)];
  }
}

final historyRepositoryProvider =
    Provider<HistoryRepository>((ref) => HistoryRepository(ref.watch(apiClientProvider)));
