import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the backend reports a maintenance window. The router sends the user to /maintenance.
class MaintenanceMode extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;

  void exit() => state = false;
}

final maintenanceModeProvider =
    NotifierProvider<MaintenanceMode, bool>(MaintenanceMode.new);
