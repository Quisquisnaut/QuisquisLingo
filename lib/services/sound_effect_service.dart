import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

class SoundEffectService {
  AudioPlayer? _player;
  final SettingsService _settings = SettingsService();

  Future<void> playDuelWin() => _play('audio/duel_win.wav');
  Future<void> playDuelLost() => _play('audio/duel_lost.wav');
  Future<void> playDuelSuspense() => _play('audio/duel_suspense.wav');
  Future<void> playVictory() => playDuelWin();
  Future<void> playDefeat() => playDuelLost();
  Future<void> playSuspense() => playDuelSuspense();

  Future<void> _play(String assetPath) async {
    if (!await _settings.areSoundEffectsEnabled()) return;
    try {
      var player = _player;
      if (player == null) {
        player = _player = AudioPlayer();
      } else {
        await player.stop();
      }
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Sound effects are optional and must never block the learning flow.
      // Drop a possibly broken backend player so the next attempt starts clean.
      final broken = _player;
      _player = null;
      try {
        await broken?.dispose();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
  }
}
