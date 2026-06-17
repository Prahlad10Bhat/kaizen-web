import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class CanvasAudioManager extends ChangeNotifier {
  static final CanvasAudioManager _instance = CanvasAudioManager._internal();
  factory CanvasAudioManager() => _instance;
  CanvasAudioManager._internal() {
    _player = AudioPlayer();
    _player.onDurationChanged.listen((d) {
      if (d != Duration.zero) {
        _duration = d;
        notifyListeners();
      }
    });
    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _isCompleted = true;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  late AudioPlayer _player;
  String? _currentSource;
  bool _isPlaying = false;
  bool _isCompleted = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String? get currentSource => _currentSource;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  Future<void> play(String source) async {
    if (_currentSource != source) {
      await _player.stop();
      _currentSource = source;
      _duration = Duration.zero;
      _position = Duration.zero;
      _isCompleted = false;
      await _player.play(DeviceFileSource(source));
    } else {
      if (_isCompleted) {
        _isCompleted = false;
        await _player.stop();
        await _player.play(DeviceFileSource(source));
      } else {
        await _player.resume();
      }
    }
    
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _position = position;
    _isCompleted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
