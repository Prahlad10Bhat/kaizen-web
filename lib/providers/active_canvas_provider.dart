import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/canvas/controllers/canvas_controller.dart';

class ActiveCanvasControllerNotifier extends Notifier<CanvasController?> {
  @override
  CanvasController? build() => null;

  void set(CanvasController? controller) {
    state = controller;
  }
}

final activeCanvasControllerProvider = NotifierProvider<ActiveCanvasControllerNotifier, CanvasController?>(() {
  return ActiveCanvasControllerNotifier();
});
