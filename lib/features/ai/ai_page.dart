import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'dart:async';

import '../../theme/app_colors.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/settings_provider.dart';
import '../../features/habits/habits_page.dart';
import '../../services/voice_command_service.dart';
import '../../models/task.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

import '../../models/chat_message.dart';
import '../../providers/ai_provider.dart';

class AIPage extends ConsumerStatefulWidget {
  const AIPage({super.key});

  @override
  ConsumerState<AIPage> createState() => _AIPageState();
}

class _AIPageState extends ConsumerState<AIPage> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isProcessingVoice = false;
  double _currentSoundLevel = 0.0;
  String _speechStatusText = '';

  late AnimationController _pulseController;
  late VoiceCommandService _commandService;


  final List<String> _suggestions = [
    'Plan my day',
    'Analyze my habits',
    'Create a task',
    'Take a note',
    'Switch to dark mode',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _commandService = VoiceCommandService(ref);

    // Initial message removed from here as it's now handled by aiProvider


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final autoListen = ref.read(aiAutoListenProvider);
      if (autoListen) {
        ref.read(aiAutoListenProvider.notifier).setAutoListen(false);
        _listen();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _listen() async {
    if (_isProcessingVoice) return;

    if (!_isListening) {
      if (!mounted) return;
      setState(() {
        _isProcessingVoice = true;
        _speechStatusText = 'Initializing speech...';
      });

      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'listening') {
              setState(() {
                _isListening = true;
                _isProcessingVoice = false;
                _speechStatusText = 'Listening... Speak now';
              });
            } else {
              setState(() {
                _isListening = false;
                _isProcessingVoice = false;
                _currentSoundLevel = 0.0;
              });
            }
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _isProcessingVoice = false;
              _currentSoundLevel = 0.0;
              _speechStatusText = 'Error: ${error.errorMsg}';
            });
            SnackbarUtils.showCustomSnackBar(context, 'Speech error: ${error.errorMsg}');
          },
        );

        if (available) {
          final locale = await _speech.systemLocale();
          if (!mounted) return;
          _speech.listen(
            onResult: (result) {
              if (!mounted) return;
              if (result.recognizedWords.isNotEmpty) {
                _textController.text = result.recognizedWords;
              }
              if (result.finalResult) {
                setState(() {
                  _isListening = false;
                  _isProcessingVoice = false;
                  _currentSoundLevel = 0.0;
                });
                if (result.recognizedWords.isNotEmpty) {
                  _handleSubmit(result.recognizedWords);
                }
              }
            },
            onSoundLevelChange: (level) {
              if (!mounted) return;
              setState(() => _currentSoundLevel = level);
            },
            localeId: locale?.localeId,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            partialResults: true,
            cancelOnError: false,
          );
        } else {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _isProcessingVoice = false;
            _speechStatusText = 'Speech not available';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _isProcessingVoice = false;
          _speechStatusText = 'Initialization failed';
        });
      }
    } else {
      setState(() {
        _isListening = false;
        _isProcessingVoice = false;
        _currentSoundLevel = 0.0;
      });
      _speech.stop();
    }
  }

  void _handleSubmit(String text) {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    ref.read(aiProvider.notifier).addMessage(
      ChatMessage(
        text: query,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _scrollToBottom();

    // Process command with simulated conversational feedback
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final lowerQuery = query.toLowerCase();
      String responseText = '';

      if (lowerQuery.contains('plan today') || lowerQuery.contains('plan my day')) {
        // Fetch tasks
        final tasks = ref.read(taskProvider);
        final pending = tasks.where((t) => t.status != TaskStatus.done).toList();
        
        if (pending.isEmpty) {
          responseText = "You don't have any pending tasks scheduled for today. It's a great opportunity to start a deep focus session or plan ahead!";
        } else {
          final buffer = StringBuffer("Here is your plan based on your active tasks:\n\n");
          for (int i = 0; i < pending.length; i++) {
            final t = pending[i];
            final priorityStr = t.priority.name.toUpperCase();
            buffer.write("${i + 1}. **${t.title}** (Priority: $priorityStr)\n");
          }
          buffer.write("\nLet me know if you want to create a new task or start a Timeboxing timer!");
          responseText = buffer.toString();
        }
      } else if (lowerQuery.contains('analyze my habits') || lowerQuery.contains('habit consistency') || lowerQuery.contains('habits')) {
        // Fetch habits
        final habits = ref.read(habitsProvider);
        if (habits.isEmpty) {
          responseText = "You haven't set up any habits yet. Consistent routines are vital for growth. You can create a new habit using the '+' Quick Capture menu!";
        } else {
          final buffer = StringBuffer("Here is your habit consistency and streaks overview:\n\n");
          for (final h in habits) {
            buffer.write("• **${h.name}** ${h.icon} — Streak: **${h.streak} days**\n");
          }
          buffer.write("\nRemember: 'Kaizen' means continuous, small improvements every day.");
          responseText = buffer.toString();
        }
      } else {
        // Run general processCommand side-effects
        try {
          _commandService.processCommand(query);

          if (lowerQuery.contains('task:') || lowerQuery.contains('create a task') || lowerQuery.contains('remind me')) {
            responseText = "I've added that task for you! You can view it on the Calendar or Tasks board.";
          } else if (lowerQuery.contains('note:') || lowerQuery.contains('create a note') || lowerQuery.contains('take a note')) {
            responseText = "I've created and saved that note to your personal knowledge base.";
          } else if (lowerQuery.contains('theme') || lowerQuery.contains('mode')) {
            responseText = "Sure, I've adjusted your theme settings.";
          } else if (lowerQuery.startsWith('open') || lowerQuery.startsWith('go to') || lowerQuery.startsWith('show')) {
            responseText = "Navigating to your destination...";
          } else {
            responseText = "I've captured that request and added it as a note: \"$query\"";
          }
        } catch (e) {
          responseText = "I processed your request, but ran into an issue applying all actions: $e";
        }
      }

      ref.read(aiProvider.notifier).addMessage(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _scrollToBottom();
    });
  }

  void _handleSuggestionTap(String suggestion) {
    if (suggestion.toLowerCase() == 'create a task') {
      _textController.text = 'create task: ';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    } else if (suggestion.toLowerCase() == 'take a note') {
      _textController.text = 'create note: ';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    } else {
      _handleSubmit(suggestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.primaryColor;
    
    final chatMessages = ref.watch(aiProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Deep black background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'KAIZEN AI',
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history list
            Expanded(
              child: chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'Ask Kaizen anything...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = chatMessages[index];
                        return _buildChatBubble(msg, theme);
                      },
                    ),
            ),
            
            // Suggestion chips
            if (chatMessages.isNotEmpty && chatMessages.length < 5)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final sug = _suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        label: Text(
                          sug,
                          style: GoogleFonts.sora(
                            color: Colors.grey.shade300,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () => _handleSuggestionTap(sug),
                      ),
                    );
                  },
                ),
              ),

            const Gap(8),

            // Speech status hint
            if (_isListening || _isProcessingVoice)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _speechStatusText.isNotEmpty ? _speechStatusText : 'Listening...',
                  style: TextStyle(color: accentColor, fontSize: 12),
                ),
              ),

            // Input panel
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Text input container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          const Gap(16),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Ask Kaizen anything...',
                                hintStyle: TextStyle(color: Colors.grey.shade600),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: _handleSubmit,
                            ),
                          ),
                          // Voice button
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: InkWell(
                              onTap: _listen,
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final levelScale = (_currentSoundLevel.clamp(0, 10) / 10);
                                  return Container(
                                    width: 38 + (levelScale * 6),
                                    height: 38 + (levelScale * 6),
                                    decoration: BoxDecoration(
                                      color: _isListening
                                          ? accentColor.withValues(alpha: 0.1 + (levelScale * 0.4))
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isListening ? LucideIcons.mic : LucideIcons.micOff,
                                      size: 18,
                                      color: _isListening ? accentColor : Colors.grey.shade500,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(8),
                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      onPressed: () => _handleSubmit(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? theme.primaryColor : const Color(0xFF1A1A1A);
    final textColor = isUser ? Colors.white : Colors.grey.shade200;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 290),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              border: Border.all(
                color: isUser ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.sora(
                color: textColor,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
          const Gap(4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
