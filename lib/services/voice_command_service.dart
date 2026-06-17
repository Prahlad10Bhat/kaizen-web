import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/task_provider.dart';
import '../features/notes/notes_page.dart';
import '../features/notes/providers/notes_providers.dart';
import '../models/task.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';

import '../providers/active_canvas_provider.dart';
import '../providers/notification_provider.dart';

class VoiceCommandService {
  final WidgetRef ref;

  VoiceCommandService(this.ref);

  void processCommand(String text) {
    final lowerText = text.toLowerCase().trim();

    // 0. Canvas Linking Commands
    if (lowerText.contains('link') || lowerText.contains('connect')) {
      final canvasController = ref.read(activeCanvasControllerProvider);
      if (canvasController != null) {
        // Simple regex to find "link A to B" or "connect A and B"
        final linkMatch = RegExp(r'(?:link|connect)\s+(.+?)\s+(?:to|and)\s+(.+)').firstMatch(lowerText);
        if (linkMatch != null) {
          final nodeAName = linkMatch.group(1)!.trim();
          final nodeBName = linkMatch.group(2)!.trim();
          
          _handleLinking(nodeAName, nodeBName);
          return;
        }
      }
    }

    // 1. Note Creation
    if (lowerText.contains('note:')) {
      final content = text.split(RegExp(r'note:', caseSensitive: false))[1].trim();
      if (content.isNotEmpty) {
        _createNote(content);
        return;
      }
    }

    // 2. Task Creation
    if (lowerText.contains('task:')) {
      final content = text.split(RegExp(r'task:', caseSensitive: false))[1].trim();
      _createTask(content);
      return;
    }

    // --- NATURAL LANGUAGE PROCESSOR (NLP) ---
    // Try parsing conversational statements (e.g. "Remind me to buy groceries tomorrow" or "Take a note about...")
    
    DateTime? extractedDate;
    String cleanText = text;
    
    // Check for temporal keywords
    if (lowerText.contains('tomorrow')) {
      extractedDate = DateTime.now().add(const Duration(days: 1));
      cleanText = text.replaceAll(RegExp(r'\b(tomorrow)\b', caseSensitive: false), '').trim();
    } else if (lowerText.contains('today') || lowerText.contains('tonight')) {
      extractedDate = DateTime.now();
      cleanText = text.replaceAll(RegExp(r'\b(today|tonight)\b', caseSensitive: false), '').trim();
    } else {
      // Check for weekday names (e.g. "by friday", "on monday")
      final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (final day in weekdays) {
        if (lowerText.contains(day)) {
          extractedDate = _getNextWeekday(day);
          cleanText = text.replaceAll(RegExp(r'\b(by|on|next)?\s*' + day + r'\b', caseSensitive: false), '').trim();
          break;
        }
      }
    }

    // Strip common leading conversational fillers for trigger detection
    String cleanTriggerText = cleanText;
    final leadingFillers = [
      RegExp(r'^i\s+', caseSensitive: false),
      RegExp(r'^we\s+', caseSensitive: false),
      RegExp(r'^please\s+', caseSensitive: false),
      RegExp(r'^hey\s+kaizen,?\s*', caseSensitive: false),
      RegExp(r'^kaizen,?\s*', caseSensitive: false),
      RegExp(r'^can\s+you\s+please\s+', caseSensitive: false),
      RegExp(r'^can\s+you\s+', caseSensitive: false),
    ];
    for (final filler in leadingFillers) {
      cleanTriggerText = cleanTriggerText.replaceFirst(filler, '').trim();
    }
    final lowerCleanTriggerText = cleanTriggerText.toLowerCase();

    // 1. Task triggers
    final taskTriggers = [
      'remind me to',
      'remind me',
      'remember to',
      'need to',
      'have to',
      'must',
      'schedule a task to',
      'schedule a task for',
      'schedule task for',
      'schedule task to',
      'schedule',
      'create a task to',
      'create a task for',
      'create task for',
      'create task to',
      'add a task to',
      'add a task for',
      'add task to',
      'add task for',
    ];

    String? taskText;
    for (final trigger in taskTriggers) {
      if (lowerCleanTriggerText.startsWith(trigger)) {
        taskText = cleanTriggerText.substring(trigger.length).trim();
        break;
      }
    }

    if (taskText != null && taskText.isNotEmpty) {
      taskText = taskText.replaceAll(RegExp(r'^[,\s]+|[.,\s]+$'), '').trim();
      if (taskText.isNotEmpty) {
        taskText = taskText[0].toUpperCase() + taskText.substring(1);
      }
      
      _createTask(taskText, parsedDueDate: extractedDate);
      
      ref.read(notificationProvider.notifier).show(
        'Created Task: "$taskText"' + (extractedDate != null ? ' (Due: ${extractedDate.month}/${extractedDate.day})' : ''),
      );
      return;
    }

    // 2. Note triggers
    final noteTriggers = [
      'take a note that',
      'take a note to',
      'take a note about',
      'take a note:',
      'take a note',
      'add a note that',
      'add a note to',
      'add a note about',
      'add a note:',
      'add a note',
      'write down that',
      'write down',
      'jot down that',
      'jot down',
      'create a note that',
      'create a note about',
      'create a note:',
      'create a note',
      'note that',
      'note',
    ];

    String? noteText;
    for (final trigger in noteTriggers) {
      if (lowerCleanTriggerText.startsWith(trigger)) {
        noteText = cleanTriggerText.substring(trigger.length).trim();
        break;
      }
    }

    if (noteText != null && noteText.isNotEmpty) {
      noteText = noteText.replaceAll(RegExp(r'^[,\s]+|[.,\s]+$'), '').trim();
      
      String title;
      if (noteText.contains(';')) {
        final parts = noteText.split(';');
        title = parts[0].trim();
        noteText = parts.sublist(1).join(';').trim();
      } else {
        title = _extractSubjectTitle(noteText);
      }

      if (title.isNotEmpty) {
        title = title[0].toUpperCase() + title.substring(1);
      }
      if (noteText.isNotEmpty) {
        noteText = noteText[0].toUpperCase() + noteText.substring(1);
      }

      _createNote(noteText, parsedTitle: title);
      
      ref.read(notificationProvider.notifier).show(
        'Created Note: "$title"',
      );
      return;
    }

    // 3. Theme Switching
    if (lowerText.contains('theme') || lowerText.contains('mode')) {
      if (lowerText.contains('dark')) {
        ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);
        return;
      } else if (lowerText.contains('light')) {
        ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.light);
        return;
      } else if (lowerText.contains('cherry')) {
        ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.cherryBlossom);
        return;
      } else if (lowerText.contains('coffee')) {
        ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.coffee);
        return;
      } else if (lowerText.contains('ember') || lowerText.contains('autumn')) {
        ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.ember);
        return;
      } else if (lowerText.contains('ivory') || lowerText.contains('medical') || lowerText.contains('beige') || lowerText.contains('cream')) {
        ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.ivory);
        return;
      }
    }

    // 4. Navigation & Search
    if (lowerText.startsWith('open') || lowerText.startsWith('go to') || lowerText.startsWith('show')) {
      final destination = lowerText
          .replaceFirst('open', '')
          .replaceFirst('go to', '')
          .replaceFirst('show', '')
          .trim();
      
      if (destination.isEmpty) return;

      if (destination.contains('note')) {
        _navigateTo(AppPage.notes);
      } else if (destination.contains('task')) {
        _navigateTo(AppPage.tasks);
      } else if (destination.contains('calendar')) {
        _navigateTo(AppPage.calendar);
      } else if (destination.contains('habit')) {
        _navigateTo(AppPage.habits);
      } else if (destination.contains('canvas') || destination.contains('board')) {
        _navigateTo(AppPage.canvas);
      } else if (destination.contains('dashboard') || destination.contains('home')) {
        _navigateTo(AppPage.home);
      } else if (destination.contains('clock')) {
        _navigateTo(AppPage.boxclock);
      }
      return;
    }

    if (lowerText.startsWith('search')) {
      final query = lowerText.replaceFirst('search', '').trim();
      _handleSearch(query);
      return;
    }

    // 5. Canvas specific commands
    if (lowerText.contains('canvas') || lowerText.contains('board')) {
      _navigateTo(AppPage.canvas);
      return;
    }

    // 6. Unknown Command Fallback
    ref.read(notificationProvider.notifier).show(
      'Command not recognized. Try "help" or use a specific prefix like "note:" or "task:".',
      isError: true,
    );
  }

  void _createTask(String rawInput, {DateTime? parsedDueDate}) {
    String title = rawInput;
    DateTime? dueDate = parsedDueDate;

    if (dueDate == null) {
      if (rawInput.contains('--end:')) {
        final parts = rawInput.split('--end:');
        title = parts[0].split('--start:')[0].trim();
        final dateStr = parts[1].trim();
        if (dateStr.toLowerCase().contains('tomorrow')) {
          dueDate = DateTime.now().add(const Duration(days: 1));
        } else if (dateStr.toLowerCase().contains('today')) {
          dueDate = DateTime.now();
        }
      } else if (rawInput.contains('--start:')) {
         title = rawInput.split('--start:')[0].trim();
      }
    }

    title = title.replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '');

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? 'New Task' : title,
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      dueDate: dueDate,
    );
    
    ref.read(taskProvider.notifier).addTask(newTask);
    _navigateTo(AppPage.tasks);
  }

  void _createNote(String content, {String? parsedTitle}) {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    String title;
    String actualContent;

    if (parsedTitle != null) {
      title = parsedTitle;
      actualContent = cleanContent;
    } else if (cleanContent.contains(';')) {
      final parts = cleanContent.split(';');
      title = parts[0].trim();
      actualContent = parts.sublist(1).join(';').trim();
      
      if (title.isEmpty) {
        title = 'Untitled Note';
      }
      if (actualContent.isEmpty) {
        actualContent = title;
      }
    } else {
      title = _extractSubjectTitle(cleanContent);
      actualContent = cleanContent;
    }

    ref.read(notesProvider.notifier).addNote(
      title: title, 
      content: actualContent,
    );
    _navigateTo(AppPage.notes);
  }

  DateTime _getNextWeekday(String dayName) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetDay = days.indexOf(dayName.toLowerCase());
    if (targetDay == -1) return DateTime.now();
    
    final now = DateTime.now();
    int daysUntil = targetDay + 1 - now.weekday;
    if (daysUntil <= 0) daysUntil += 7; // Next week's weekday
    
    return now.add(Duration(days: daysUntil));
  }

  String _extractSubjectTitle(String text) {
    String cleanText = text.trim();
    if (cleanText.isEmpty) return 'Note';

    // Strip common leading conversational phrases at the start of title extraction
    final leadingPhrasesToStrip = [
      RegExp(r'^(take\s+a\s+)?note\s+(that|about|to|on)?\s*', caseSensitive: false),
      RegExp(r'^(create|add)\s+(a\s+)?(note|task)\s+(that|about|to|for|on)?\s*', caseSensitive: false),
      RegExp(r'^remind\s+me\s+(to|that|about)?\s*', caseSensitive: false),
      RegExp(r'^remember\s+(to)?\s*', caseSensitive: false),
      RegExp(r'^i\s+(need|want|have)\s+to\s*', caseSensitive: false),
      RegExp(r'^we\s+(need|want|have)\s+to\s*', caseSensitive: false),
      RegExp(r'^please\s*', caseSensitive: false),
      RegExp(r'^hey\s+kaizen,?\s*', caseSensitive: false),
      RegExp(r'^kaizen,?\s*', caseSensitive: false),
      RegExp(r'^can\s+you\s+(please\s+)?(remind\s+me\s+to|note|create|add)?\s*', caseSensitive: false),
      RegExp(r'^write\s+(down\s+)?(that|about)?\s*', caseSensitive: false),
      RegExp(r'^jot\s+(down\s+)?(that|about)?\s*', caseSensitive: false),
    ];
    for (final phrase in leadingPhrasesToStrip) {
      cleanText = cleanText.replaceFirst(phrase, '').trim();
    }

    if (cleanText.isEmpty) return 'Note';

    // Heuristic 0: Check if there's a semicolon or colon - that is an explicit title!
    if (cleanText.contains(';')) {
      return cleanText.split(';')[0].trim();
    }
    if (cleanText.contains(':')) {
      final possible = cleanText.split(':')[0].trim();
      if (possible.length > 2 && possible.length < 30) {
        return possible;
      }
    }

    // Heuristic 1: Look for purpose/goal clauses with common action verbs
    // e.g. "to watch la casa de papel", "to meet my friend", "to buy groceries"
    final actionPattern = RegExp(
      r'\b(?:to|about|for|on)\s+(watch|meet|buy|read|play|visit|finish|check|study|listen|call|discuss|learn)\s+([^,.]+)',
      caseSensitive: false,
    );
    final actionMatch = actionPattern.firstMatch(cleanText);
    if (actionMatch != null) {
      final verb = actionMatch.group(1)!.trim();
      final subject = actionMatch.group(2)!.trim();
      final cleanSubject = _cleanSubjectPhrase(subject);
      if (cleanSubject.isNotEmpty) {
        return _capitalizeWords('${verb} ${cleanSubject}').take(30);
      }
    }

    // Heuristic 2: Direct match for action verb + noun in the whole text
    // e.g. "watch la casa de papel", "buy groceries"
    final directActionPattern = RegExp(
      r'\b(watch|meet|buy|read|play|visit|finish|check|study|listen|call|discuss|learn)\s+([^,.]+)',
      caseSensitive: false,
    );
    final directMatch = directActionPattern.firstMatch(cleanText);
    if (directMatch != null) {
      final verb = directMatch.group(1)!.trim();
      final subject = directMatch.group(2)!.trim();
      final cleanSubject = _cleanSubjectPhrase(subject);
      if (cleanSubject.isNotEmpty) {
        return _capitalizeWords('${verb} ${cleanSubject}').take(30);
      }
    }

    // Heuristic 3: Check for prepositional topics: "about [topic]", "on [topic]", "for [topic]"
    final prepPattern = RegExp(
      r'\b(?:about|on|for|regarding|with)\s+([^,.]+)',
      caseSensitive: false,
    );
    final prepMatch = prepPattern.firstMatch(cleanText);
    if (prepMatch != null) {
      final topic = prepMatch.group(1)!.trim();
      final cleanTopic = _cleanSubjectPhrase(topic);
      if (cleanTopic.isNotEmpty) {
        return _capitalizeWords(cleanTopic).take(30);
      }
    }

    // Heuristic 4: Check if there's any capitalized noun phrase in the middle of the sentence
    // e.g. "I want to watch Stranger Things" -> "Stranger Things"
    final words = cleanText.split(RegExp(r'\s+'));
    final capitalizedSequence = <String>[];
    for (int i = 1; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (word.isNotEmpty && word[0] == word[0].toUpperCase() && word[0] != word[0].toLowerCase()) {
        capitalizedSequence.add(words[i]);
      } else {
        if (capitalizedSequence.isNotEmpty) break;
      }
    }
    if (capitalizedSequence.isNotEmpty) {
      final phrase = capitalizedSequence.join(' ').replaceAll(RegExp(r'[.,;:!?]$'), '');
      if (phrase.length > 2) {
        return phrase.take(30);
      }
    }

    // Heuristic 5: Fallback to the first non-trivial words (up to 4 words)
    final trivialPattern = RegExp(
      r'\b(i|me|my|myself|we|us|our|ours|you|your|yours|he|him|his|she|her|hers|they|them|their|'
      r'a|an|the|this|that|these|those|'
      r'am|is|are|was|were|be|been|being|have|has|had|do|does|did|'
      r'can|could|will|would|shall|should|may|might|must|'
      r'to|for|on|at|in|with|from|by|about|of|'
      r'go|went|gone|going|want|wants|need|needs|'
      r'today|tonight|tomorrow|yesterday|morning|afternoon|evening|night|'
      r'note|task|remind|remember|create|add)\b',
      caseSensitive: false,
    );
    final cleanWords = words.where((w) => !trivialPattern.hasMatch(w)).toList();
    if (cleanWords.isNotEmpty) {
      final fallbackTitle = cleanWords.take(3).join(' ').replaceAll(RegExp(r'[.,;:!?]$'), '');
      if (fallbackTitle.isNotEmpty) {
        return _capitalizeWords(fallbackTitle).take(30);
      }
    }

    // Heuristic 6: Absolute fallback
    final fallbackWords = words.take(4).join(' ').replaceAll(RegExp(r'[.,;:!?]$'), '');
    return _capitalizeWords(fallbackWords).take(30);
  }

  String _cleanSubjectPhrase(String phrase) {
    var clean = phrase.replaceAll(RegExp(r'\b(today|tonight|tomorrow|yesterday|now|at|by|on|in|with|from|to)\b.*$', caseSensitive: false), '').trim();
    clean = clean.replaceAll(RegExp(r'^[,\s]+|[.,\s]+$'), '').trim();
    return clean;
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  void _handleSearch(String query) {
    ref.read(noteSearchQueryProvider.notifier).set(query);
    _navigateTo(AppPage.notes);
  }

  void _handleLinking(String nameA, String nameB) {
    final controller = ref.read(activeCanvasControllerProvider);
    if (controller == null) return;

    final matchesA = controller.findNodesByTitle(nameA);
    final matchesB = controller.findNodesByTitle(nameB);

    if (matchesA.isEmpty || matchesB.isEmpty) {
      ref.read(notificationProvider.notifier).show(
        'Could not find nodes: ${matchesA.isEmpty ? nameA : ""} ${matchesB.isEmpty ? nameB : ""}',
        isError: true,
      );
      return;
    }

    // If multiple matches, we trigger the search cycle for the first node
    // to let the user "go through them one by one"
    if (matchesA.length > 1) {
      controller.findNodesByTitle(nameA);
      ref.read(notificationProvider.notifier).show('Found multiple matches for "$nameA". Cycle to choose.');
      return;
    }
    
    if (matchesB.length > 1) {
      controller.findNodesByTitle(nameB);
      ref.read(notificationProvider.notifier).show('Found multiple matches for "$nameB". Cycle to choose.');
      return;
    }

    // Single matches found, link them
    final idA = matchesA.first;
    final idB = matchesB.first;

    controller.addConnection(idA, idB);
    controller.triggerNodePulse(idA);
    controller.triggerNodePulse(idB);
    
    ref.read(notificationProvider.notifier).show('Successfully linked $nameA to $nameB');
    _navigateTo(AppPage.canvas);
  }

  void _navigateTo(AppPage page) {
    ref.read(navigationProvider.notifier).setPage(page);
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
