import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'data/history_repository.dart';
import 'data/scan_record.dart';

final historyProvider = FutureProvider<List<ScanRecord>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(historyRepositoryProvider).fetchScans();
});
