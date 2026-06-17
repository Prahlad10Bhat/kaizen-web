import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../features/notes/notes_page.dart';
import '../../features/notes/providers/notes_providers.dart';
import '../../features/habits/habits_page.dart';
import '../../services/voice_command_service.dart';
import '../../models/task.dart';
import '../../providers/calendar_provider.dart';
import '../../models/calendar.dart';
import '../../services/app_tour_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GhostTextController _commandController = GhostTextController();
  final FocusNode _commandFocus = FocusNode();
  bool _isListening = false;
  String _text = 'Press the mic to speak';
  String _ghostText = '';
  double _confidence = 1.0;
  List<String> _commandHistory = [];
  
  late AnimationController _pulseController;
  late VoiceCommandService _commandService;
  
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Command Feedback State
  bool _isProcessingCommand = false;
  String? _submittedCommand;
  String? _processingStatus;
  String? _resultMessage;
  String? _resultTitle;
  String? _resultSubtitle;
  String? _resultBadgeDay;
  String? _resultBadgeDate;
  bool _isCommandConfirmed = false;
  Timer? _processingTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _commandService = VoiceCommandService(ref);
    _loadCommandHistory();

    _commandFocus.onKeyEvent = (node, event) {
      if (event is! KeyUpEvent) {
        debugPrint('Command Hub Key Pressed: ${event.logicalKey.keyLabel} (Ghost: "$_ghostText")');
        
        // Tab key
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          if (_ghostText.isNotEmpty) {
            debugPrint('Tab pressed with suggestion. Accepting: "$_ghostText"');
            _acceptSuggestion();
            return KeyEventResult.handled;
          }
        }
        // Right Arrow key
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          final selection = _commandController.selection;
          if (selection.baseOffset == _commandController.text.length && _ghostText.isNotEmpty) {
            debugPrint('Right Arrow pressed at end of line. Accepting: "$_ghostText"');
            _acceptSuggestion();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _loadCommandHistory() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _commandHistory = prefs.getStringList('kaizen_command_history') ?? [];
      });
    } catch (e) {
      _commandHistory = [];
    }
  }

  void _saveCommandToHistory(String cmd) {
    final trimmed = cmd.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _commandHistory.remove(trimmed);
      _commandHistory.insert(0, trimmed);

      if (_commandHistory.length > 50) {
        _commandHistory = _commandHistory.sublist(0, 50);
      }
    });

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setStringList('kaizen_command_history', _commandHistory);
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    _speech.cancel();
    _commandController.dispose();
    _commandFocus.dispose();
    _processingTimer?.cancel();
    super.dispose();
  }

  final List<String> _primaryCommands = [
    'create a task:',
    'add a note:',
    'note:',
    'task:',
    'open canvas',
    'go to dashboard',
    'switch to dark mode',
    'switch to light mode',
    'switch to ember mode',
    'show task list',
    'open notes',
  ];

  void _updateGhostText(String value) {
    if (value.isEmpty) {
      setState(() {
        _ghostText = '';
        _commandController.ghostText = '';
      });
      return;
    }

    setState(() {
      final lower = value.toLowerCase();
      
      // 1. Check command history for prefix matches (terminal style!)
      String? historyMatch;
      for (final cmd in _commandHistory) {
        if (cmd.toLowerCase().startsWith(lower) && cmd.length > lower.length) {
          historyMatch = cmd;
          break;
        }
      }

      if (historyMatch != null) {
        _ghostText = historyMatch.substring(value.length);
        _commandController.ghostText = _ghostText;
        debugPrint('Matched History Suggestion: "$historyMatch" (Ghost: "$_ghostText")');
        return;
      }

      // 2. Check for primary command prefix matching
      String? matchedCommand;
      for (final cmd in _primaryCommands) {
        if (cmd.startsWith(lower) && cmd != lower) {
          matchedCommand = cmd;
          break;
        }
      }

      if (matchedCommand != null) {
        _ghostText = matchedCommand.substring(lower.length);
        _commandController.ghostText = _ghostText;
        debugPrint('Matched Built-in Command: "$matchedCommand" (Ghost: "$_ghostText")');
        return;
      }

      // 3. Check for parameter suggestions once command is typed
      bool isTask = lower.startsWith('task:') || lower.startsWith('create a task:');
      bool isNote = lower.startsWith('note:') || lower.startsWith('add a note:');

      if (isTask) {
        final prefix = lower.startsWith('task:') ? 'task:' : 'create a task:';
        final taskContent = lower.substring(prefix.length);
        if (!taskContent.contains('--start')) {
          if (taskContent.trim().isEmpty) {
            _ghostText = ' [Title] --start: [Today] --end: [Tomorrow]';
          } else {
            _ghostText = ' --start: [Today] --end: [Tomorrow]';
          }
        } else if (!taskContent.contains('--end')) {
          final parts = taskContent.split('--start:');
          if (parts.length > 1 && parts[1].trim().isEmpty) {
            _ghostText = ' [Today] --end: [Tomorrow]';
          } else {
            _ghostText = ' --end: [Tomorrow]';
          }
        } else {
          final parts = taskContent.split('--end:');
          if (parts.length > 1 && parts[1].trim().isEmpty) {
            _ghostText = ' [Tomorrow]';
          } else {
            _ghostText = '';
          }
        }
      } else if (isNote) {
        final prefix = lower.startsWith('note:') ? 'note:' : 'add a note:';
        final noteContent = lower.substring(prefix.length);
        if (!noteContent.contains(';')) {
          if (noteContent.trim().isEmpty) {
            _ghostText = ' [Title]; [Content]';
          } else {
            _ghostText = '; [Content]';
          }
        } else {
          final parts = noteContent.split(';');
          if (parts.length > 1 && parts[1].trim().isEmpty) {
            _ghostText = ' [Content]';
          } else {
            _ghostText = '';
          }
        }
      } else {
        _ghostText = '';
      }
      
      _commandController.ghostText = _ghostText;
      if (_ghostText.isNotEmpty) {
        debugPrint('Rendered Parameter Tip Ghost: "$_ghostText"');
      }
    });
  }

  void _acceptSuggestion() {
    if (_ghostText.isNotEmpty) {
      final currentText = _commandController.text;
      final fullText = currentText + _ghostText;
      _commandController.text = fullText;
      _commandController.selection = TextSelection.fromPosition(
        TextPosition(offset: fullText.length),
      );
      setState(() {
        _ghostText = '';
        _commandController.ghostText = '';
      });
      _updateGhostText(fullText);
    }
  }

  void _handleSubmittedCommand(String value) {
    _saveCommandToHistory(value);
    
    _processingTimer?.cancel();
    
    setState(() {
      _submittedCommand = value;
      _isProcessingCommand = true;
      _isCommandConfirmed = false;
      _resultMessage = null;
      _resultTitle = null;
      _resultSubtitle = null;
      _resultBadgeDay = null;
      _resultBadgeDate = null;
      
      final lower = value.toLowerCase();
      if (lower.contains('schedule') || lower.contains('calendar') || lower.contains('event') || lower.contains('meeting')) {
        _processingStatus = 'Analyzing schedule...';
      } else if (lower.contains('note') || lower.contains('write') || lower.contains('jot')) {
        _processingStatus = 'Saving note...';
      } else {
        _processingStatus = 'Processing command...';
      }
    });

    _processingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final lower = _submittedCommand!.toLowerCase();
      final now = DateTime.now();
      var eventDate = now;
      var dateStr = 'Today';
      
      if (lower.contains('tomorrow')) {
        eventDate = now.add(const Duration(days: 1));
        dateStr = 'Tomorrow';
      } else {
        final weekdays = {
          'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
          'friday': 5, 'saturday': 6, 'sunday': 7
        };
        for (final entry in weekdays.entries) {
          if (lower.contains(entry.key)) {
            eventDate = _getNextWeekday(entry.key);
            dateStr = entry.key[0].toUpperCase() + entry.key.substring(1);
            break;
          }
        }
      }
      
      final badgeDay = DateFormat('EEE').format(eventDate).toUpperCase();
      final badgeDate = DateFormat('d').format(eventDate);
      
      if (lower.contains('schedule') || lower.contains('calendar') || lower.contains('event') || lower.contains('meeting') || lower.contains('hours') || lower.contains('work')) {
        // Extract Title
        String title = 'Deep Work';
        if (lower.contains('proposal')) {
          title = 'Marketing Proposal';
        } else if (lower.contains('exercise') || lower.contains('workout')) {
          title = 'Workout Session';
        } else if (lower.contains('meeting') || lower.contains('1:1')) {
          title = '1:1 Sync';
        } else {
          final stripped = _extractSubjectTitle(_submittedCommand!);
          if (stripped != 'Note' && stripped.isNotEmpty) {
            title = stripped;
          }
        }
        
        // Extract hours/duration
        String duration = '9:00 AM - 10:00 AM';
        if (lower.contains('2 hours')) {
          duration = '9:00 AM - 11:00 AM';
        } else if (lower.contains('1 hour')) {
          duration = '10:00 AM - 11:00 AM';
        } else if (lower.contains('3 hours')) {
          duration = '2:00 PM - 5:00 PM';
        }
        
        setState(() {
          _isProcessingCommand = false;
          _processingStatus = null;
          _resultMessage = "Found a perfect block. I've scheduled it and moved your 1:1 to Thursday.";
          _resultTitle = title;
          _resultSubtitle = duration;
          _resultBadgeDay = badgeDay;
          _resultBadgeDate = badgeDate;
        });
      } else if (lower.contains('note') || lower.contains('write') || lower.contains('jot')) {
        final title = _extractSubjectTitle(_submittedCommand!);
        setState(() {
          _isProcessingCommand = false;
          _processingStatus = null;
          _resultMessage = "I've saved your note successfully.";
          _resultTitle = title;
          _resultSubtitle = "Saved in Notes";
          _resultBadgeDay = "NOTE";
          _resultBadgeDate = "✍️";
        });
      } else {
        final title = _extractSubjectTitle(_submittedCommand!);
        setState(() {
          _isProcessingCommand = false;
          _processingStatus = null;
          _resultMessage = "Added task to your to-do list.";
          _resultTitle = title;
          _resultSubtitle = "Task • Medium Priority";
          _resultBadgeDay = badgeDay;
          _resultBadgeDate = badgeDate;
        });
      }
    });
  }

  void _confirmCommandResult() {
    if (_submittedCommand == null) return;
    
    setState(() {
      _isCommandConfirmed = true;
    });

    final lower = _submittedCommand!.toLowerCase();
    if (lower.contains('schedule') || lower.contains('calendar') || lower.contains('event') || lower.contains('meeting') || lower.contains('hours') || lower.contains('work')) {
      final now = DateTime.now();
      var eventDate = now;
      if (lower.contains('tomorrow')) {
        eventDate = now.add(const Duration(days: 1));
      } else {
        final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        for (final day in weekdays) {
          if (lower.contains(day)) {
            eventDate = _getNextWeekday(day);
            break;
          }
        }
      }
      
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _resultTitle ?? 'Scheduled Event',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        dueDate: eventDate,
        description: 'Scheduled via command: "${_submittedCommand}"',
      );
      ref.read(taskProvider.notifier).addTask(newTask);
    } else if (lower.contains('note') || lower.contains('write') || lower.contains('jot')) {
      _commandService.processCommand(_submittedCommand!);
    } else {
      _commandService.processCommand(_submittedCommand!);
    }

    ref.read(notificationProvider.notifier).show('Event confirmed & saved');

    Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _submittedCommand = null;
        _resultMessage = null;
        _resultTitle = null;
        _resultSubtitle = null;
        _resultBadgeDay = null;
        _resultBadgeDate = null;
        _isCommandConfirmed = false;
      });
    });
  }

  DateTime _getNextWeekday(String dayName) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetDay = days.indexOf(dayName.toLowerCase());
    if (targetDay == -1) return DateTime.now();
    
    final now = DateTime.now();
    int daysUntil = targetDay + 1 - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    
    return now.add(Duration(days: daysUntil));
  }

  String _extractSubjectTitle(String text) {
    String cleanText = text.trim();
    if (cleanText.isEmpty) return 'Note';

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

    if (cleanText.contains(';')) {
      return cleanText.split(';')[0].trim();
    }
    if (cleanText.contains(':')) {
      final possible = cleanText.split(':')[0].trim();
      if (possible.length > 2 && possible.length < 30) {
        return possible;
      }
    }

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

  double _currentSoundLevel = 0;
  bool _isProcessingVoice = false;

  Future<void> _listen() async {
    if (_isProcessingVoice) return;
    
    if (!_isListening) {
      if (!mounted) return;
      setState(() => _isProcessingVoice = true);
      
      try {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (!mounted) return;
            if (val == 'listening') {
              setState(() {
                _isListening = true;
                _isProcessingVoice = false;
                _text = 'Listening... (Speak now)';
              });
            } else {
              setState(() {
                _isListening = false;
                _isProcessingVoice = false;
                _currentSoundLevel = 0;
              });
              if (val == 'done' || val == 'notListening') {
                if (_text == 'Initializing...' || _text == 'Listening... (Speak now)') {
                  setState(() => _text = 'Press the mic to speak');
                }
              }
            }
          },
          onError: (val) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _isProcessingVoice = false;
              _currentSoundLevel = 0;
              _text = 'Error: ${val.errorMsg}';
            });
          },
        );

        if (available) {
          final systemLocale = await _speech.systemLocale();
          if (!mounted) return;
          setState(() {
            _text = 'Initializing...';
          });
          
          _speech.listen(
            onResult: (val) {
              if (!mounted) return;
              setState(() {
                if (val.recognizedWords.isNotEmpty) {
                  _text = val.recognizedWords;
                }
                if (val.finalResult) {
                  _isListening = false;
                  _isProcessingVoice = false;
                  _currentSoundLevel = 0;
                  if (val.recognizedWords.isNotEmpty) {
                    _commandService.processCommand(val.recognizedWords);
                  }
                }
              });
            },
            onSoundLevelChange: (level) {
              if (!mounted) return;
              setState(() => _currentSoundLevel = level);
            },
            localeId: systemLocale?.localeId,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            partialResults: false,
            cancelOnError: false,
          );
        } else {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _isProcessingVoice = false;
            _text = 'Speech recognition not available';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _isProcessingVoice = false;
          _text = 'Failed to initialize speech';
        });
      }
    } else {
      _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _isProcessingVoice = false;
        _currentSoundLevel = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _commandController.ghostColor = theme.primaryColor.withValues(alpha: 0.4);
    final tasks = ref.watch(taskProvider);
    final notes = ref.watch(notesProvider);
    final user = ref.watch(userProvider);
    final habits = ref.watch(habitsProvider);
    final calendars = ref.watch(calendarProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(isMobile ? 20 : 40, isMobile ? 32 : 64, isMobile ? 20 : 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, user.name, isMobile),
                Gap(isMobile ? 24 : 48),
                _buildCommandHub(theme, isMobile),
                Gap(isMobile ? 24 : 48),
                _buildActivitySummary(theme, tasks, notes, habits, calendars, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, String name, bool isMobile) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 0 && hour < 4) greeting = 'Good Night';
    else if (hour >= 4 && hour < 12) greeting = 'Good Morning';
    else if (hour >= 12 && hour < 16) greeting = 'Good Afternoon';
    else greeting = 'Good Evening';
    
    final displayName = name.contains('...') ? '' : ', $name';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting$displayName',
          style: GoogleFonts.sora(
            fontSize: isMobile ? 28 : 40,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildCommandHub(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: AppTourKeys.homeCommandHubKey,
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Gap(16),
                  Icon(
                    LucideIcons.sparkles, 
                    size: 20, 
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                  ),
                  const Gap(12),
                  Expanded(
                    child: TextField(
                      autofocus: !isMobile,
                      controller: _commandController,
                      focusNode: _commandFocus,
                      onChanged: _updateGhostText,
                      style: GoogleFonts.sora(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What should I do for you today?',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          if (value.toLowerCase().trim() == 'clear history') {
                            try {
                              final prefs = ref.read(sharedPreferencesProvider);
                              prefs.remove('kaizen_command_history');
                            } catch (_) {}
                            setState(() {
                              _commandHistory.clear();
                            });
                            ref.read(notificationProvider.notifier).show('Command history cleared');
                            _commandController.clear();
                            _updateGhostText('');
                            _commandFocus.requestFocus();
                            return;
                          }
                          _handleSubmittedCommand(value);
                          _commandController.clear();
                          _updateGhostText('');
                          _commandFocus.requestFocus();
                        }
                      },
                    ),
                  ),
                  _buildVoiceButton(theme, isMobile),
                ],

              ),
              if (_isListening || (_text != 'Press the mic to speak' && _text.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.sparkles, size: 14, color: theme.primaryColor.withValues(alpha: 0.5)),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          _isListening ? '“$_text”' : _text,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                            color: theme.primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_submittedCommand != null) ...[
                const Divider(height: 24, thickness: 1, color: Colors.white10),
                
                // 1. Submitted Command Bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Text(
                      _submittedCommand!,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),

                // 2. Analyzing Status
                if (_isProcessingCommand)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _pulseController.value * 2 * 3.14159,
                              child: Icon(
                                LucideIcons.dna,
                                size: 18,
                                color: theme.primaryColor,
                              ),
                            );
                          },
                        ),
                        const Gap(12),
                        Text(
                          _processingStatus ?? 'Processing...',
                          style: GoogleFonts.sora(
                            color: theme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Result Panel Block
                if (_resultMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resultMessage!,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const Gap(14),
                        
                        // Action Event Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07070F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Date Badge
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _resultBadgeDay ?? 'WED',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: theme.primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Gap(2),
                                    Text(
                                      _resultBadgeDate ?? '14',
                                      style: GoogleFonts.sora(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(14),
                              
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _resultTitle ?? 'Scheduled Event',
                                      style: GoogleFonts.sora(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      _resultSubtitle ?? '9:00 AM - 11:00 AM',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Confirm Button
                              InkWell(
                                onTap: _isCommandConfirmed ? null : _confirmCommandResult,
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _isCommandConfirmed ? Colors.green : const Color(0xFF161622),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isCommandConfirmed ? Colors.green : Colors.white12,
                                    ),
                                  ),
                                  child: Icon(
                                    _isCommandConfirmed ? LucideIcons.check : LucideIcons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceButton(ThemeData theme, bool isMobile) {
    return InkWell(
      onTap: () {
        ref.read(notificationProvider.notifier).show('Voice commands are currently under development');
      },
      borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final levelScale = (_currentSoundLevel.clamp(0, 10) / 10);
          return Container(
            width: (isMobile ? 44 : 52) + (levelScale * 10),
            height: (isMobile ? 44 : 52) + (levelScale * 10),
            decoration: BoxDecoration(
              color: _isListening 
                ? theme.primaryColor.withValues(alpha: 0.15 + (levelScale * 0.4))
                : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isListening ? LucideIcons.mic : LucideIcons.micOff,
              size: (isMobile ? 18 : 22),
              color: _isListening 
                ? Colors.green 
                : Colors.red,
            ),
          );
        },
      ),
    );
  }




  Widget _buildActivitySummary(ThemeData theme, List<Task> tasks, List<Note> notes, List<Habit> habits, List<Calendar> calendars, bool isMobile) {
    // Filter out events (tasks belonging to a non-task calendar)
    final actualTasks = tasks.where((t) {
      final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null') ? 'default_tasks' : t.calendarId!;
      final parentCal = calendars.firstWhere(
        (c) => c.id == cId,
        orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
      );
      return parentCal.isTaskCalendar;
    }).toList();

    final todoCount = actualTasks.where((t) => t.status == TaskStatus.todo).length;
    final completedCount = actualTasks.where((t) => t.status == TaskStatus.done).length;
    final totalTasks = actualTasks.length;
    final consistency = totalTasks == 0 ? 0 : ((completedCount / totalTasks) * 100).round();

    // Next upcoming/pending task logic
    final pendingTasksList = actualTasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      
      // Filter out past tasks based on due date
      if (t.dueDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (taskDate.isBefore(today)) return false;
      }
      
      return true;
    }).toList();
    
    pendingTasksList.sort((a, b) {
      if (a.priority == b.priority) {
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        return 0;
      }
      return a.priority.index.compareTo(b.priority.index);
    });
    final nextTask = pendingTasksList.isNotEmpty ? pendingTasksList.first : null;

    // Latest note logic
    final sortedNotesList = [...notes];
    sortedNotesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final latestNote = sortedNotesList.isNotEmpty ? sortedNotesList.first : null;

    // Dynamic Narrative calculations
    final hour = DateTime.now().hour;
    String greeting;
    String timeBackgroundImage;
    Color timeTextColor = Colors.white;
    Color timeSubtitleColor = Colors.white.withValues(alpha: 0.85);

    if (hour >= 22 || hour < 4) {
      greeting = 'Good Night';
      timeBackgroundImage = 'assets/images/starry_night_clouds.png';
    } else if (hour >= 4 && hour < 7) {
      greeting = 'Good Morning';
      timeBackgroundImage = 'assets/images/sunrise_clouds.png';
    } else if (hour >= 7 && hour < 12) {
      greeting = 'Good Morning';
      timeBackgroundImage = 'assets/images/morning_clouds.png';
    } else if (hour >= 12 && hour < 16) {
      greeting = 'Good Afternoon';
      timeBackgroundImage = 'assets/images/afternoon_clouds.png';
    } else if (hour >= 16 && hour < 20) {
      greeting = 'Good Evening';
      timeBackgroundImage = 'assets/images/evening_clouds.png';
    } else {
      greeting = 'Good Night';
      timeBackgroundImage = 'assets/images/night_clouds.png';
    }

    final clockCard = Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(timeBackgroundImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.2), 
            BlendMode.darken,
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('h:mm a').format(_currentTime),
            style: GoogleFonts.sora(
              fontSize: isMobile ? 30 : 36,
              fontWeight: FontWeight.bold,
              color: timeTextColor,
              letterSpacing: -1,
            ),
          ),
          const Gap(6),
          Text(
            DateFormat('EEEE, dd MMMM').format(_currentTime),
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: timeSubtitleColor,
            ),
          ),
        ],
      ),
    );

    String taskStory = "";
    if (totalTasks == 0) {
      taskStory = "You have no tasks scheduled for today. Take some time to organize your goals.";
    } else {
      if (todoCount == 0) {
        taskStory = "All tasks completed! You've accomplished all $completedCount tasks on your schedule today.";
      } else {
        taskStory = "You have $todoCount pending tasks today. You've completed $completedCount of $totalTasks total tasks ($consistency% success rate).";
      }
    }

    String habitStory = "";
    if (habits.isEmpty) {
      habitStory = "Start tracking your habits to see consistency insights and build continuous daily improvements.";
    } else {
      int totalHabitOpportunities = 0;
      int completedHabitsCount = 0;
      final today = DateTime.now();
      
      Habit bestHabit = habits.first;
      int bestCount = 0;

      for (final h in habits) {
        int count = 0;
        for (int i = 0; i < 31; i++) {
          final date = today.subtract(Duration(days: i));
          final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          totalHabitOpportunities++;
          final status = h.history[dateStr];
          if (status == HabitStatus.completed) {
            completedHabitsCount++;
            count++;
          }
        }
        if (count > bestCount) {
          bestCount = count;
          bestHabit = h;
        }
      }

      final totalHabitConsistency = totalHabitOpportunities == 0 ? 0 : ((completedHabitsCount / totalHabitOpportunities) * 100).round();

      if (bestCount > 0) {
        habitStory = "You completed your ${bestHabit.name.toLowerCase()} habit on $bestCount of the last 31 days. Overall habit consistency is at $totalHabitConsistency%, a solid step towards your growth.";
      } else {
        habitStory = "Overall habit consistency is at $totalHabitConsistency% for the last 31 days. Make sure to complete today's habits to kickstart a streak!";
      }
    }

    return Column(
      key: AppTourKeys.homeActivitySummaryKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          // Mobile layout: Stack elements cleanly
          clockCard,
          const Gap(16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      color: theme.primaryColor,
                      size: 18,
                    ),
                    const Gap(8),
                    Text(
                      "TODAY'S STORY",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: theme.primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Text(
                  "$greeting.\n\n$taskStory\n\n$habitStory",
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Desktop layout: Horizontal Row for clock + stat cards with flex spacing
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: clockCard,
                ),
                const Gap(16),
                _buildStatCard(
                  theme: theme,
                  count: todoCount.toString(),
                  label: 'Pending Tasks',
                  icon: LucideIcons.circle,
                  color: Colors.orange,
                  isMobile: false,
                  onTap: () => ref.read(navigationProvider.notifier).setPage(AppPage.tasks),
                ),
                const Gap(16),
                _buildStatCard(
                  theme: theme,
                  count: notes.length.toString(),
                  label: 'Recent Notes',
                  icon: LucideIcons.fileText,
                  color: Colors.blue,
                  isMobile: false,
                  onTap: () => ref.read(navigationProvider.notifier).setPage(AppPage.notes),
                ),
                const Gap(16),
                _buildStatCard(
                  theme: theme,
                  count: '$consistency%',
                  label: 'Consistency',
                  icon: LucideIcons.zap,
                  color: Colors.amber,
                  isMobile: false,
                  onTap: () => ref.read(navigationProvider.notifier).setPage(AppPage.habits),
                ),
              ],
            ),
          ),
        ],
        const Gap(16),
        // Bottom wide card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.01),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  children: [
                    _buildTaskPreview(theme, nextTask, true),
                    Divider(height: 1, thickness: 0.5, color: theme.dividerColor.withValues(alpha: 0.3)),
                    _buildNotePreview(theme, latestNote, true),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildTaskPreview(theme, nextTask, false)),
                    Container(
                      width: 0.5,
                      height: 100,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                    Expanded(child: _buildNotePreview(theme, latestNote, false)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              hoverColor: color.withValues(alpha: 0.04),
              splashColor: color.withValues(alpha: 0.08),
              highlightColor: color.withValues(alpha: 0.04),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 20,
                  vertical: isMobile ? 10 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: isMobile ? 14 : 16,
                        color: color,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: isMobile ? 20 : 30,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 9 : 11,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPreview(ThemeData theme, Task? task, bool isMobile) {
    final hasTask = task != null;
    return ClipRRect(
      borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : const BorderRadius.horizontal(left: Radius.circular(24)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(navigationProvider.notifier).setPage(AppPage.tasks);
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkSquare,
                      size: 14,
                      color: theme.primaryColor.withValues(alpha: 0.7),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'NEXT TASK',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: theme.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                if (hasTask) ...[
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Gap(6),
                  Row(
                    children: [
                      _buildPriorityDot(task.priority),
                      const Gap(6),
                      Flexible(
                        child: Text(
                          task.priority.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(task.priority),
                          ),
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const Gap(12),
                        Icon(
                          LucideIcons.calendar,
                          size: 11,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            DateFormat('MMM d').format(task.dueDate!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Text(
                    'All tasks completed',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Enjoy your free time or add a new task.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotePreview(ThemeData theme, Note? note, bool isMobile) {
    final hasNote = note != null;
    return ClipRRect(
      borderRadius: isMobile 
          ? const BorderRadius.vertical(bottom: Radius.circular(24))
          : const BorderRadius.horizontal(right: Radius.circular(24)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(navigationProvider.notifier).setPage(AppPage.notes);
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: theme.primaryColor.withValues(alpha: 0.7),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'LATEST NOTE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: theme.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                if (hasNote) ...[
                  Text(
                    note.title.isEmpty ? 'Untitled Note' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    note.content.isEmpty ? 'Empty note' : note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ] else ...[
                  Text(
                    'No notes yet',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Start writing down your ideas and thoughts.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDot(TaskPriority priority) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.greenAccent;
    }
  }
}

class GhostTextController extends TextEditingController {
  String _ghostText = '';
  Color ghostColor = Colors.grey;

  String get ghostText => _ghostText;
  
  set ghostText(String val) {
    if (_ghostText != val) {
      _ghostText = val;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_ghostText.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: text),
        TextSpan(
          text: _ghostText,
          style: style?.copyWith(color: ghostColor) ?? TextStyle(color: ghostColor),
        ),
      ],
    );
  }
}
