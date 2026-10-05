import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'models.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<List<ActivityEntry>> fetchActivities({int limit = 5}) async {
    final data = await _api.get('/dashboard/activities', query: {'limit': limit}) as List<dynamic>;
    return [for (final item in data) ActivityEntry.fromJson(item as Map<String, dynamic>)];
  }

  Future<CropProfile> fetchCropProfile() async =>
      CropProfile.fromJson(await _api.get('/dashboard/crop-profile') as Map<String, dynamic>);

  Future<List<ActionItem>> fetchActions() async {
    final data = await _api.get('/dashboard/actions') as List<dynamic>;
    return [for (final item in data) ActionItem.fromJson(item as Map<String, dynamic>)];
  }

  Future<void> logActivity(String action, String details) async {
    await _api.post('/dashboard/activities', data: {'action': action, 'details': details});
  }

  Future<void> setActionCompleted(String id, bool completed) async {
    await _api.put('/dashboard/actions/$id', data: {'is_completed': completed});
  }
}

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => DashboardRepository(ref.watch(apiClientProvider)));
