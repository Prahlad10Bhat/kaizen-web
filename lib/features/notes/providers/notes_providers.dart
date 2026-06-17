import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/settings_provider.dart';

import '../notes_page.dart';
class TagsNotifier extends Notifier<List<NoteTag>> {
  static const _storageKey = 'kaizen_note_tags';

  @override
  List<NoteTag> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((j) => NoteTag.fromJson(j)).toList();
      } catch (e) {
        return _defaultTags;
      }
    }
    return _defaultTags;
  }

  List<NoteTag> get _defaultTags => [
    NoteTag(id: 'tag_work', label: 'Work', color: Colors.blueAccent),
    NoteTag(id: 'tag_personal', label: 'Personal', color: Colors.greenAccent),
    NoteTag(id: 'tag_ideas', label: 'Ideas', color: Colors.amberAccent),
  ];

  void _saveTags() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(state.map((t) => t.toJson()).toList());
    prefs.setString(_storageKey, jsonStr);
  }

  void addTag(String label, Color color) {
    state = [...state, NoteTag(id: DateTime.now().toString(), label: label, color: color)];
    _saveTags();
  }

  void updateTag(String tagId, String newLabel, Color newColor) {
    state = [
      for (final tag in state)
        if (tag.id == tagId) NoteTag(id: tagId, label: newLabel, color: newColor) else tag
    ];
    _saveTags();
  }

  void deleteTag(String tagId) {
    state = state.where((tag) => tag.id != tagId).toList();
    _saveTags();
  }

  void reorderTags(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<NoteTag> items = List.from(state);
    final NoteTag item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    _saveTags();
  }
}

final tagsProvider = NotifierProvider<TagsNotifier, List<NoteTag>>(() => TagsNotifier());

// Provider to track the current view in the settings dialog
class DialogView {
  final String mode; // 'home', 'tags', 'edit_tag'
  final NoteTag? editingTag;
  final bool isForward; // Track direction for transitions
  
  DialogView(this.mode, {this.editingTag, this.isForward = true});
}

class DialogViewNotifier extends Notifier<DialogView> {
  @override
  DialogView build() => DialogView('home');

  void set(String mode, {NoteTag? tag}) {
    final currentMode = state.mode;
    bool forward = true;

    // Determine direction
    if (mode == 'home') {
      forward = false;
    } else if (mode == 'tags' && currentMode == 'edit_tag') {
      forward = false;
    }

    state = DialogView(mode, editingTag: tag, isForward: forward);
  }
}

final dialogViewProvider = NotifierProvider<DialogViewNotifier, DialogView>(() => DialogViewNotifier());

class Wrapped<T> {
  final T value;
  const Wrapped(this.value);
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final List<String> mediaPaths;
  final Color? color;
  final bool? _isPinned;
  final List<String> tagIds;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.mediaPaths = const [],
    this.color,
    bool? isPinned = false,
    this.tagIds = const [],
  }) : _isPinned = isPinned;

  bool get isPinned => _isPinned ?? false;

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    List<String>? mediaPaths,
    Wrapped<Color?>? color,
    bool? isPinned,
    List<String>? tagIds,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      color: color != null ? color.value : this.color,
      isPinned: isPinned ?? this.isPinned,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
    'mediaPaths': mediaPaths,
    'color': color?.value,
    'isPinned': isPinned,
    'tagIds': tagIds,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    updatedAt: DateTime.parse(json['updatedAt']),
    mediaPaths: List<String>.from(json['mediaPaths'] ?? []),
    color: json['color'] != null ? Color(json['color']) : null,
    isPinned: json['isPinned'] ?? false,
    tagIds: List<String>.from(json['tagIds'] ?? []),
  );
}

class NotesNotifier extends Notifier<List<Note>> {
  static const _storageKey = 'kaizen_notes';

  @override
  List<Note> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((j) => Note.fromJson(j)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void _saveNotes() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(state.map((n) => n.toJson()).toList());
    prefs.setString(_storageKey, jsonStr);
  }

  String addNote({String? title, String? content}) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? '',
      content: content ?? '',
      updatedAt: DateTime.now(),
      isPinned: false,
    );
    state = [newNote, ...state];
    _saveNotes();
    return newNote.id;
  }

  void updateNote(Note updatedNote) {
    state = [
      for (final note in state)
        if (note.id == updatedNote.id) updatedNote else note
    ];
    _saveNotes();
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
    _saveNotes();
  }

  void togglePin(String id) {
    state = [
      for (final note in state)
        if (note.id == id) note.copyWith(isPinned: !note.isPinned) else note
    ];
    _saveNotes();
  }
}

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(() {
  return NotesNotifier();
});

class SelectedNoteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final selectedNoteIdProvider = NotifierProvider<SelectedNoteNotifier, String?>(() {
  return SelectedNoteNotifier();
});

class NoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final noteSearchQueryProvider = NotifierProvider<NoteSearchQueryNotifier, String>(() {
  return NoteSearchQueryNotifier();
});

// NotesSettings moved to global SettingsProvider

