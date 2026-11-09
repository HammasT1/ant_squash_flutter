import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'Storage.dart';

enum GameSound { squash, hit, gameOver, combo }

class GameAudio {
  GameAudio._();

  static final Map<GameSound, AudioPlayer> _players = {};

  static const Map<GameSound, String> _files = {
    GameSound.squash: 'sounds/squash.wav',
    GameSound.hit: 'sounds/hit.wav',
    GameSound.gameOver: 'sounds/gameover.wav',
    GameSound.combo: 'sounds/combo.wav',
  };

  static Future<void> play(GameSound sound) async {
    if (!GameStorage.soundEnabled) {
      return;
    }
    try {
      final player = _players.putIfAbsent(sound, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        return p;
      });
      await player.stop();
      await player.play(AssetSource(_files[sound]!));
    } catch (_) {
      // Audio is optional; never break gameplay.
    }
  }

  static void haptic({bool heavy = false}) {
    if (!GameStorage.soundEnabled) {
      return;
    }
    if (heavy) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}
