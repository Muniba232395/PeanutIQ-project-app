import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Microphone recording, behind an interface so tests don't need a device.
abstract interface class VoiceRecorder {
  Future<bool> hasPermission();

  Future<void> start();

  /// Stops and returns the recorded file, or null if nothing was recorded.
  Future<String?> stop();
}

class RecordVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
  }

  @override
  Future<String?> stop() => _recorder.stop();
}

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) => RecordVoiceRecorder());
