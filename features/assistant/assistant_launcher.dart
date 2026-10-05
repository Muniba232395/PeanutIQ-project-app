import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks the floating assistant to open (the website's `open-robot` window event).
/// The value is a counter; the assistant opens whenever it changes.
class AssistantLauncher extends Notifier<int> {
  @override
  int build() => 0;

  void open() => state++;
}

final assistantLauncherProvider = NotifierProvider<AssistantLauncher, int>(AssistantLauncher.new);
