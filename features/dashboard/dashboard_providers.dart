import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advisories/data/advisories_repository.dart';
import '../advisories/data/advisory.dart';
import '../auth/auth_controller.dart';
import 'data/dashboard_repository.dart';
import 'data/models.dart';

// Every provider watches the signed-in user id so a new sign-in never sees the
// previous farmer's data.

final activitiesProvider = FutureProvider<List<ActivityEntry>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(dashboardRepositoryProvider).fetchActivities();
});

final latestAlertProvider = FutureProvider<Advisory?>((ref) async {
  ref.watch(currentUserIdProvider);
  final list = await ref.read(advisoriesRepositoryProvider).fetch(type: 'alert', limit: 1);
  return list.isEmpty ? null : list.first;
});

final dailyTipProvider = FutureProvider<String?>((ref) async {
  ref.watch(currentUserIdProvider);
  final list = await ref.read(advisoriesRepositoryProvider).fetch(type: 'tip', limit: 1);
  return list.isEmpty ? null : list.first.message;
});

final cropProfileProvider = FutureProvider<CropProfile>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(dashboardRepositoryProvider).fetchCropProfile();
});

class ActionsNotifier extends AsyncNotifier<List<ActionItem>> {
  @override
  Future<List<ActionItem>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(dashboardRepositoryProvider).fetchActions();
  }

  /// Flips the task at once, then saves. Returns false (and restores the task) if saving fails.
  Future<bool> toggle(String id) async {
    final current = state.value;
    if (current == null) return false;
    final index = current.indexWhere((a) => a.id == id);
    if (index < 0) return false;
    final original = current[index];
    _replace(original.copyWith(isCompleted: !original.isCompleted));
    try {
      await ref.read(dashboardRepositoryProvider).setActionCompleted(id, !original.isCompleted);
      return true;
    } on Object {
      _replace(original);
      return false;
    }
  }

  void _replace(ActionItem item) {
    final list = [...?state.value];
    final index = list.indexWhere((a) => a.id == item.id);
    if (index < 0) return;
    list[index] = item;
    state = AsyncData(list);
  }
}

final actionsProvider =
    AsyncNotifierProvider<ActionsNotifier, List<ActionItem>>(ActionsNotifier.new);
