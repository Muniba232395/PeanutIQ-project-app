import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Plays recorded voice notes.
abstract interface class AudioPlayback {
  Stream<void> get completed;

  Future<void> play(String path);

  Future<void> pause();
}

class JustAudioPlayback implements AudioPlayback {
  JustAudioPlayback() {
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _completed.add(null);
        _player.stop();
      }
    });
  }

  final _player = AudioPlayer();
  final _completed = StreamController<void>.broadcast();

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> play(String path) async {
    await _player.setFilePath(path);
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();
}

final audioPlaybackProvider = Provider<AudioPlayback>((ref) => JustAudioPlayback());
