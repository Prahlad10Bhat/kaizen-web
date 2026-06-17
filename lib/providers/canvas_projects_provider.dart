import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/canvas/models/canvas_document.dart';
import '../services/canvas_service.dart';

class CanvasProjectsNotifier extends Notifier<List<CanvasDocument>> {
  @override
  List<CanvasDocument> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await CanvasService.getProjects();
  }

  Future<void> refresh() async {
    state = await CanvasService.getProjects();
  }
}

final canvasProjectsProvider = NotifierProvider<CanvasProjectsNotifier, List<CanvasDocument>>(() {
  return CanvasProjectsNotifier();
});

class SelectedCanvasIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void set(String? id) => state = id;
}

final selectedCanvasIdProvider = NotifierProvider<SelectedCanvasIdNotifier, String?>(() {
  return SelectedCanvasIdNotifier();
});
