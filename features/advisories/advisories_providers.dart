import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'data/advisories_repository.dart';
import 'data/advisory.dart';

/// The Advisories page: no query, so the backend's default of 5 applies (same as the website).
final advisoryListProvider = FutureProvider<List<Advisory>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(advisoriesRepositoryProvider).fetch();
});
