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
