import 'dart:ui';
import 'package:flutter/material.dart';

class ViewportController extends ChangeNotifier {
  Offset _offset;
  double _scale;

  ViewportController({
    Offset initialOffset = Offset.zero,
    double initialScale = 1.0,
  })  : _offset = initialOffset,
        _scale = initialScale,
        _homeOffset = initialOffset,
        _homeScale = initialScale;

  Offset get offset => _offset;
  double get scale => _scale;

  static const double minScale = 0.2;
  static const double maxScale = 3.0;
  static const double zoomStep = 0.1;

  Offset _homeOffset = Offset.zero;
  double _homeScale = 1.0;

  void setHomeView() {
    _homeOffset = _offset;
    _homeScale = _scale;
  }

  void reset() {
    _offset = _homeOffset;
    _scale = _homeScale;
    notifyListeners();
  }

  void pan(Offset delta) {
    _offset += delta;
    notifyListeners();
  }

  Offset worldToScreen(Offset worldPosition) {
    return Offset(
      worldPosition.dx * _scale + _offset.dx,
      worldPosition.dy * _scale + _offset.dy,
    );
  }

  Offset screenToWorld(Offset screenPosition) {
    return Offset(
      (screenPosition.dx - _offset.dx) / _scale,
      (screenPosition.dy - _offset.dy) / _scale,
    );
  }

  void zoomAt({
    required double delta,
    required Offset localCursorPosition,
  }) {
    final oldScale = _scale;
    final newScale = (_scale + delta).clamp(minScale, maxScale);

    if (oldScale == newScale) return;

    final worldBefore = screenToWorld(localCursorPosition);

    _scale = newScale;

    final screenAfter = worldToScreen(worldBefore);

    _offset += localCursorPosition - screenAfter;

    notifyListeners();
  }

  void zoomIn(Offset localCursorPosition) {
    zoomAt(
      delta: zoomStep,
      localCursorPosition: localCursorPosition,
    );
  }

  void zoomOut(Offset localCursorPosition) {
    zoomAt(
      delta: -zoomStep,
      localCursorPosition: localCursorPosition,
    );
  }

  void centerOnPosition(Offset worldPosition, Size viewportSize) {
    _offset = Offset(
      viewportSize.width / 2 - (worldPosition.dx * _scale),
      viewportSize.height / 2 - (worldPosition.dy * _scale),
    );
    notifyListeners();
  }
}
