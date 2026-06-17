import 'dart:collection';

import '../models/canvas_document.dart';

class HistoryController {
  final ListQueue<CanvasDocument> _undoStack = ListQueue();
  final ListQueue<CanvasDocument> _redoStack = ListQueue();

  final int maxHistory;

  HistoryController({
    this.maxHistory = 100,
  });

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void push(CanvasDocument document) {
    _undoStack.addLast(document);
    _redoStack.clear();

    if (_undoStack.length > maxHistory) {
      _undoStack.removeFirst();
    }
  }

  CanvasDocument? undo(CanvasDocument currentDocument) {
    if (_undoStack.isEmpty) return null;

    _redoStack.addLast(currentDocument);

    return _undoStack.removeLast();
  }

  CanvasDocument? redo(CanvasDocument currentDocument) {
    if (_redoStack.isEmpty) return null;

    _undoStack.addLast(currentDocument);

    return _redoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
