import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Manages all sound effects and background music for the game.
///
/// Every SFX gets its own short-lived [AudioPlayer] so effects can overlap
/// with each other and with the looping BGM. The [AudioContext] uses
/// `mixWithOthers` / `audioFocus: none` so playback never interrupts itself.
///
/// SFX live in `assets/audio/sfx/` and are referenced by name (without the
/// `.mp3` extension). The background loop lives in `assets/audio/bgm/bgm.mp3`.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _enabled = true;
  bool _bgmStarted = false;
  double sfxVolume = 0.7;
  double bgmVolume = 0.35;

  bool get muted => !_enabled;

  AudioContext _mixContext() => AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  /// Call once during boot. BGM is started separately via [startBgm].
  Future<void> init() async {
    _enabled = true;
  }

  /// Play a one-shot sound effect by name (without `.mp3`). Safe to call
  /// from anywhere; failures are swallowed so audio never breaks gameplay.
  void play(String name, {double volumeScale = 1}) {
    if (!_enabled) return;
    final player = AudioPlayer();
    unawaited(() async {
      try {
        await player.setAudioContext(_mixContext());
        await player.setVolume(
          (sfxVolume * volumeScale).clamp(0, 1).toDouble(),
        );
        player.onPlayerComplete.listen((_) {
          unawaited(player.dispose());
        });
        await player.play(AssetSource('assets/audio/sfx/$name.mp3'));
      } catch (_) {
        // Audio is optional and must never interrupt gameplay.
        await player.dispose();
      }
    }());
  }

  /// Start (or restart) the looping background music.
  Future<void> startBgm() async {
    if (!_enabled) return;
    _bgmStarted = true;
    try {
      await _bgmPlayer.setAudioContext(_mixContext());
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(bgmVolume);
      await _bgmPlayer.play(AssetSource('assets/audio/bgm/bgm.mp3'));
    } catch (_) {
      _bgmStarted = false;
    }
  }

  Future<void> stopBgm() => _bgmPlayer.stop();

  void toggleMute() {
    _enabled = !_enabled;
    if (!_enabled) {
      unawaited(_bgmPlayer.stop());
    } else if (!_bgmStarted) {
      unawaited(startBgm());
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
  }
}
