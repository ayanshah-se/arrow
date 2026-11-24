import 'package:audioplayers/audioplayers.dart';

class HeartLossAudio {
  HeartLossAudio() : _player = AudioPlayer();

  static const assetPath = 'audio/heart_losse.mpeg';

  final AudioPlayer _player;

  Future<void> play() async {
    try {
      await _player.stop();
      await _player.setPlaybackRate(1.6);
      await _player.play(AssetSource(assetPath));
      await _player.setPlaybackRate(1.6);
    } catch (_) {
      // Widget tests / platforms without a plugin.
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

final heartLossAudio = HeartLossAudio();
