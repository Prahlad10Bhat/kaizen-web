import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPage { home, notes, tasks, calendar, habits, canvas, settings, profile, boxclock, feedback, ai, workout, appTracker }

class NavigationNotifier extends Notifier<AppPage> {
  final List<AppPage> _history = [AppPage.home];
  int _currentIndex = 0;

  @override
  AppPage build() {
    return _history[_currentIndex]; // Default to home
  }

  void setPage(AppPage page) {
    if (_history[_currentIndex] == page) return;
    
    // Remove forward history if we navigate to a new page from the middle of history
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }
    
    _history.add(page);
    _currentIndex++;
    state = page;
  }

  bool get canGoBack => _currentIndex > 0;
  bool get canGoForward => _currentIndex < _history.length - 1;

  void goBack() {
    if (canGoBack) {
      _currentIndex--;
      state = _history[_currentIndex];
    }
  }

  void goForward() {
    if (canGoForward) {
      _currentIndex++;
      state = _history[_currentIndex];
    }
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, AppPage>(() {
  return NavigationNotifier();
});

final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

class AIAutoListenNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setAutoListen(bool value) {
    state = value;
  }
}

final aiAutoListenProvider = NotifierProvider<AIAutoListenNotifier, bool>(() {
  return AIAutoListenNotifier();
});

