import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:audioplayers/audioplayers.dart';
import 'settings_provider.dart';

class TimerState {
  final int totalDurationSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isExpanded;
  final bool isNotificationEnabled;
  final bool isRinging;

  TimerState({
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.isExpanded,
    this.isNotificationEnabled = true,
    this.isRinging = false,
  });

  TimerState copyWith({
    int? totalDurationSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isExpanded,
    bool? isNotificationEnabled,
    bool? isRinging,
  }) {
    return TimerState(
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isExpanded: isExpanded ?? this.isExpanded,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      isRinging: isRinging ?? this.isRinging,
    );
  }

  double get progress => totalDurationSeconds == 0 
      ? 0.0 
      : 1.0 - (remainingSeconds / totalDurationSeconds);
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;
  Timer? _alarmTimeoutTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  TimerState build() {
    return TimerState(
      totalDurationSeconds: 25 * 60, // Default 25 minutes
      remainingSeconds: 25 * 60,
      isRunning: false,
      isPaused: false,
      isExpanded: false,
    );
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void stopAlarm() {
    _alarmTimeoutTimer?.cancel();
    if (state.isRinging || _audioPlayer.state == PlayerState.playing) {
      _audioPlayer.stop();
      state = state.copyWith(isRinging: false);
    }
  }

  void toggleNotification() {
    if (state.isRinging || _audioPlayer.state == PlayerState.playing) {
      stopAlarm();
      return;
    }
    state = state.copyWith(isNotificationEnabled: !state.isNotificationEnabled);
  }

  void setDuration(int seconds) {
    if (!state.isRunning || state.isPaused) {
      state = state.copyWith(
        totalDurationSeconds: seconds,
        remainingSeconds: seconds,
      );
    }
  }

  void startTimer({int? durationSeconds}) {
    _timer?.cancel();
    stopAlarm();
    final seconds = durationSeconds ?? state.totalDurationSeconds;
    
    state = state.copyWith(
      totalDurationSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      isPaused: false,
      isExpanded: true, // Expand when starting
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    if (state.isRunning && !state.isPaused) {
      _timer?.cancel();
      state = state.copyWith(isPaused: true, isExpanded: true);
    }
  }

  void resumeTimer() {
    if (state.isRunning && state.isPaused) {
      state = state.copyWith(isPaused: false);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.remainingSeconds > 0) {
          state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _alarmTimeoutTimer?.cancel();
    _audioPlayer.stop();
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      remainingSeconds: state.totalDurationSeconds,
      isRinging: false,
    );
  }

  void _onTimerComplete() async {
    stopTimer();
    state = state.copyWith(isRinging: true);
    if (state.isNotificationEnabled) {
      final alarmPath = ref.read(settingsProvider).alarmAudioPath;
      if (alarmPath == 'system') {
        _playSystemNotification();
        return;
      }
      
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        if (alarmPath != null && alarmPath.isNotEmpty) {
          await _audioPlayer.play(DeviceFileSource(alarmPath));
        } else {
          await _audioPlayer.play(AssetSource('audio/rickroll.wav'));
        }

        _alarmTimeoutTimer?.cancel();
        _alarmTimeoutTimer = Timer(const Duration(minutes: 1), () {
          if (_audioPlayer.state == PlayerState.playing) {
            _audioPlayer.stop();
          }
        });
      } catch (e) {
        _playSystemNotification();
      }
    }
  }

  void _playSystemNotification() {
    LocalNotification notification = LocalNotification(
      title: "Time's up!",
      body: "Your focus timer has completed.",
    );
    notification.show();
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(() => TimerNotifier());
