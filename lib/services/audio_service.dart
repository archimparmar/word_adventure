import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPlayers = [];
  int _sfxPlayerIndex = 0;
  static const int _maxSfxPlayers = 6;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _isMusicPlaying = false;

  final Map<String, int> _lastPlayedTimes = {};

  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;

  Future<void> init() async {
    if (_sfxPlayers.isEmpty) {
      for (int i = 0; i < _maxSfxPlayers; i++) {
        _sfxPlayers.add(AudioPlayer());
      }
    }
    await loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('setting_sound') ?? true;
    _musicEnabled = prefs.getBool('setting_music') ?? true;

    if (!_musicEnabled && _isMusicPlaying) {
      stopMusic();
    }
  }

  void updateSettings({bool? sound, bool? music}) {
    if (sound != null) _soundEnabled = sound;
    if (music != null) {
      _musicEnabled = music;
      if (!_musicEnabled && _isMusicPlaying) {
        stopMusic();
      } else if (_musicEnabled && !_isMusicPlaying) {
        playGameplayMusic();
      }
    }
  }

  // ── MUSIC METHODS ────────────────────────────────────────────────────────
  bool _hasEverStarted = false;

  Future<void> playGameplayMusic() async {
    await loadSettings();
    if (!_musicEnabled) return;
    if (_isMusicPlaying) return;

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('audio/Main Gameplay Music.wav'));
      _isMusicPlaying = true;
      _hasEverStarted = true;
    } catch (_) {
      _isMusicPlaying = false;
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    _isMusicPlaying = false;
    _hasEverStarted = false;
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (_) {}
    _isMusicPlaying = false;
    // Keep _hasEverStarted = true so resume knows to call resume() not play()
  }

  Future<void> resumeMusic() async {
    await loadSettings();
    if (!_musicEnabled) return;
    if (_isMusicPlaying) return;

    if (!_hasEverStarted) {
      // Never been started — do a full play
      await playGameplayMusic();
      return;
    }

    try {
      await _musicPlayer.resume();
      _isMusicPlaying = true;
    } catch (_) {
      await playGameplayMusic();
    }
  }

  // ── SFX METHODS ──────────────────────────────────────────────────────────
  Future<void> playSfx(String audioFileName, {int minIntervalMs = 60}) async {
    if (!_soundEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastPlayedTimes[audioFileName] ?? 0;
    if (now - lastTime < minIntervalMs) {
      return; // Debounce rapid duplicate playback
    }
    _lastPlayedTimes[audioFileName] = now;

    if (_sfxPlayers.isEmpty) {
      for (int i = 0; i < _maxSfxPlayers; i++) {
        _sfxPlayers.add(AudioPlayer());
      }
    }

    try {
      final player = _sfxPlayers[_sfxPlayerIndex];
      _sfxPlayerIndex = (_sfxPlayerIndex + 1) % _maxSfxPlayers;
      await player.stop();
      await player.play(AssetSource('audio/$audioFileName'));
    } catch (_) {}
  }

  // ── CONVENIENCE SFX TRIGGERS ──────────────────────────────────────────────
  void playButtonTap() => playSfx('Button Tap.wav');
  void playLetterSelect() => playSfx('Letter Select.wav');
  void playWordCorrect() => playSfx('Word Correct.wav');
  void playWordInvalid() => playSfx('Word Invalid.wav');
  void playWordComplete() => playSfx('Word Complete.wav');
  void playLevelComplete() => playSfx('Level Complete.wav');
  void playHintUsed() => playSfx('Hint Used.wav');
  void playShuffle() => playSfx('Shuffle.wav');
  void playDailyChallengeComplete() => playSfx('Daily Challenge Complete.wav');
  void playCoinReward() => playSfx('CoinDiamond Reward.wav');
  void playPurchaseSuccess() => playSfx('Purchase Success.wav');
  void playAchievementUnlock() => playSfx('Achievement Unlock.wav');
  void playMiniGameComplete() => playSfx('Mini-Game Complete.wav');
}
