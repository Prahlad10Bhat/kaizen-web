import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar.dart';
import '../features/notes/notes_page.dart';
import '../features/notes/providers/notes_providers.dart';
import '../features/habits/habits_page.dart';
import '../providers/workout_provider.dart';
import '../providers/app_tracker_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/canvas_projects_provider.dart';
import '../providers/recent_commands_provider.dart';
import '../features/canvas/models/canvas_node.dart';
import 'dart:math' as math;

class CommandPaletteItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final AppPage? route;
  final VoidCallback? action;
  final String? category;
  final String? shortcut;
  final bool isHeader;

  CommandPaletteItem({
    this.id = '',
    required this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.action,
    this.category,
    this.shortcut,
    this.isHeader = false,
  });
}

class ClosePaletteIntent extends Intent {
  const ClosePaletteIntent();
}

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({Key? key}) : super(key: key);

  static bool _isOpen = false;

  static void show(BuildContext context) {
    if (_isOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    _isOpen = true;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const CommandPalette(),
    ).then((_) {
      _isOpen = false;
    });
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  String _selectedFilter = 'All';
  int _selectedIndex = 0;

  final List<String> _filters = [
    'All',
    'Dashboard',
    'Notes',
    'Tasks',
    'Calendar',
    'Habits',
    'Canvas',
    'Workout',
    'BoxClock',
    'App Tracker',
    'Settings',
    'Media'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canvasProjectsProvider.notifier).refresh();
    });
    _searchController.addListener(_onSearchChanged);
    _focusNode.requestFocus();
  }

  void _onSearchChanged() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSelection(CommandPaletteItem item) {
    if (item.isHeader) return;
    
    if (item.id.isNotEmpty) {
      ref.read(recentCommandsProvider.notifier).addCommand(item.id);
    }

    Navigator.of(context).pop(); // Close dialog
    if (item.action != null) {
      item.action!();
    } else if (item.route != null) {
      ref.read(navigationProvider.notifier).setPage(item.route!);
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          do {
            _selectedIndex = (_selectedIndex + 1).clamp(0, math.max(0, _filteredItems.length - 1));
          } while (_filteredItems[_selectedIndex].isHeader && _selectedIndex < _filteredItems.length - 1);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          do {
            _selectedIndex = (_selectedIndex - 1).clamp(0, math.max(0, _filteredItems.length - 1));
          } while (_filteredItems[_selectedIndex].isHeader && _selectedIndex > 0);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter && _filteredItems.isNotEmpty) {
        _handleSelection(_filteredItems[_selectedIndex]);
      }
    }
  }

  List<CommandPaletteItem> _filteredItems = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notes = ref.watch(notesProvider);
    final allTasks = ref.watch(taskProvider);
    final calendars = ref.watch(calendarProvider);
    final habits = ref.watch(habitsProvider);
    final workouts = ref.watch(workoutProvider);
    final appTracker = ref.watch(appTrackerProvider);
    final aiChats = ref.watch(aiProvider);
    final canvasProjects = ref.watch(canvasProjectsProvider);

    // Split into tasks (task calendars) and events (non-task calendars)
    final tasks = allTasks.where((t) {
      final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null')
          ? 'default_tasks'
          : t.calendarId!;
      final parentCal = calendars.firstWhere(
        (c) => c.id == cId,
        orElse: () => calendars.firstWhere(
          (c) => c.id == 'default_tasks',
          orElse: () => const Calendar(id: 'default_tasks', name: 'Tasks', colorValue: 0xFF6C63FF, isTaskCalendar: true),
        ),
      );
      return parentCal.isTaskCalendar;
    }).toList();

    final events = allTasks.where((t) {
      final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null')
          ? 'default_tasks'
          : t.calendarId!;
      final parentCal = calendars.firstWhere(
        (c) => c.id == cId,
        orElse: () => calendars.firstWhere(
          (c) => c.id == 'default_tasks',
          orElse: () => const Calendar(id: 'default_tasks', name: 'Tasks', colorValue: 0xFF6C63FF, isTaskCalendar: true),
        ),
      );
      return !parentCal.isTaskCalendar;
    }).toList();
    
    final List<CommandPaletteItem> _pageItems = [
      CommandPaletteItem(id: 'PAGE_home', title: 'Dashboard', subtitle: 'Overview', icon: LucideIcons.layoutDashboard, category: 'PAGE_LINK', route: AppPage.home),
      CommandPaletteItem(id: 'PAGE_notes', title: 'Notes', subtitle: 'Rich text editor', icon: LucideIcons.fileText, category: 'PAGE_LINK', route: AppPage.notes),
      CommandPaletteItem(id: 'PAGE_tasks', title: 'Tasks', subtitle: 'To-do lists', icon: LucideIcons.checkSquare, category: 'PAGE_LINK', route: AppPage.tasks),
      CommandPaletteItem(id: 'PAGE_calendar', title: 'Calendar', subtitle: 'Schedule & events', icon: LucideIcons.calendar, category: 'PAGE_LINK', route: AppPage.calendar),
      CommandPaletteItem(id: 'PAGE_habits', title: 'Habits', subtitle: 'Habit tracker', icon: LucideIcons.flame, category: 'PAGE_LINK', route: AppPage.habits),
      CommandPaletteItem(id: 'PAGE_canvas', title: 'Canvas', subtitle: 'Infinite canvas workspace', icon: LucideIcons.box, category: 'PAGE_LINK', route: AppPage.canvas),
      CommandPaletteItem(id: 'PAGE_workout', title: 'Workout', subtitle: 'Fitness tracking', icon: LucideIcons.activity, category: 'PAGE_LINK', route: AppPage.workout),
      CommandPaletteItem(id: 'PAGE_ai', title: 'AI Assistant', subtitle: 'Chat with AI', icon: LucideIcons.messageSquare, category: 'PAGE_LINK', route: AppPage.ai),
      CommandPaletteItem(id: 'PAGE_boxclock', title: 'BoxClock', subtitle: 'Timeboxing timer', icon: LucideIcons.clock, category: 'TOOL_LINK', route: AppPage.boxclock),
      CommandPaletteItem(id: 'PAGE_appTracker', title: 'App Tracker', subtitle: 'Time tracking', icon: LucideIcons.monitor, category: 'TOOL_LINK', route: AppPage.appTracker),
      CommandPaletteItem(id: 'PAGE_settings', title: 'Settings', subtitle: 'Preferences', icon: LucideIcons.settings, category: 'TOOL_LINK', route: AppPage.settings),
      
      // Individual Settings
      CommandPaletteItem(id: 'SETTING_theme', title: 'Theme Settings', subtitle: 'Change app appearance', icon: LucideIcons.palette, category: 'SETTING', action: () { ref.read(navigationProvider.notifier).setPage(AppPage.settings); }),
      CommandPaletteItem(id: 'SETTING_notifications', title: 'Notifications Settings', subtitle: 'Enable or disable alerts', icon: LucideIcons.bell, category: 'SETTING', action: () { ref.read(navigationProvider.notifier).setPage(AppPage.settings); }),
      CommandPaletteItem(id: 'SETTING_timer', title: 'Floating Timer Settings', subtitle: 'Toggle floating timer', icon: LucideIcons.timer, category: 'SETTING', action: () { ref.read(navigationProvider.notifier).setPage(AppPage.settings); }),
      CommandPaletteItem(id: 'SETTING_alarm', title: 'Alarm Tune Settings', subtitle: 'Change alarm sound', icon: LucideIcons.music, category: 'SETTING', action: () { ref.read(navigationProvider.notifier).setPage(AppPage.settings); }),
      CommandPaletteItem(id: 'SETTING_changelog', title: 'What\'s New (Changelog)', subtitle: 'View app updates', icon: LucideIcons.sparkles, category: 'SETTING', action: () { ref.read(navigationProvider.notifier).setPage(AppPage.settings); }),
      CommandPaletteItem(id: 'SETTING_feedback', title: 'Submit Feedback', subtitle: 'Send feedback or report bugs', icon: LucideIcons.messageSquare, category: 'SETTING', action: () { ref.read(navigationProvider.notifier).setPage(AppPage.settings); }),
    ];
    
    final query = _searchController.text.toLowerCase();

    final allItems = <CommandPaletteItem>[
      ..._pageItems,
      ...notes.map((n) => CommandPaletteItem(
        id: 'NOTE_${n.id}',
        title: n.title.isEmpty ? 'Untitled Note' : n.title,
        subtitle: n.content.isNotEmpty ? n.content.replaceAll('\n', ' ') : 'Empty note',
        icon: LucideIcons.stickyNote,
        category: 'NOTE',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.notes);
          ref.read(selectedNoteIdProvider.notifier).set(n.id);
        },
      )),
      ...tasks.map((t) => CommandPaletteItem(
        id: 'TASK_${t.id}',
        title: t.title,
        subtitle: 'Task',
        icon: LucideIcons.checkSquare,
        category: 'TASK',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.tasks);
        },
      )),
      ...habits.map((h) => CommandPaletteItem(
        id: 'HABIT_${h.id}',
        title: h.name,
        subtitle: 'Habit',
        icon: LucideIcons.flame,
        category: 'HABIT',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.habits);
        },
      )),
      ...workouts.routines.map((r) => CommandPaletteItem(
        id: 'WORKOUT_${r.id}',
        title: r.name,
        subtitle: 'Workout Routine',
        icon: LucideIcons.activity,
        category: 'WORKOUT',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.workout);
        },
      )),
      ...appTracker.apps.map((a) => CommandPaletteItem(
        id: 'APP_${a.id}',
        title: a.name,
        subtitle: 'Tracked App - ${a.keyword}',
        icon: LucideIcons.monitor,
        category: 'APP_TRACKER',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.appTracker);
        },
      )),
      ...aiChats.where((c) => c.isUser).map((c) => CommandPaletteItem(
        id: 'AI_${c.timestamp.millisecondsSinceEpoch}',
        title: c.text.length > 50 ? '${c.text.substring(0, 50)}...' : c.text,
        subtitle: 'AI Chat History',
        icon: LucideIcons.messageSquare,
        category: 'AI_CHAT',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.ai);
        },
      )),
      ...notes.expand((n) => n.mediaPaths.map((path) {
        final filename = path.split(RegExp(r'[\\/]')).last;
        return CommandPaletteItem(
          id: 'MEDIA_$filename',
          title: filename,
          subtitle: 'Attached to: ${n.title.isEmpty ? 'Untitled Note' : n.title}',
          icon: LucideIcons.image,
          category: 'MEDIA',
          action: () {
            ref.read(navigationProvider.notifier).setPage(AppPage.notes);
            ref.read(selectedNoteIdProvider.notifier).set(n.id);
          },
        );
      })),
      ...canvasProjects.expand((doc) => doc.nodes.where((n) => n.type == CanvasNodeType.audio || n.type == CanvasNodeType.image).map((node) {
        final filename = node.content.split(RegExp(r'[\\/]')).last;
        return CommandPaletteItem(
          id: 'CANVAS_MEDIA_$filename',
          title: filename,
          subtitle: 'In Canvas: ${doc.name.isEmpty ? 'Untitled' : doc.name}',
          icon: node.type == CanvasNodeType.audio ? LucideIcons.music : LucideIcons.image,
          category: 'CANVAS_MEDIA',
          action: () {
            ref.read(navigationProvider.notifier).setPage(AppPage.canvas);
            ref.read(selectedCanvasIdProvider.notifier).set(doc.id);
          },
        );
      })),
      ...canvasProjects.expand((doc) => doc.nodes.where((n) => n.type == CanvasNodeType.note || n.type == CanvasNodeType.text).map((node) {
        return CommandPaletteItem(
          id: 'CANVAS_NOTE_${node.id}',
          title: node.title.isNotEmpty ? node.title : (node.content.isNotEmpty ? (node.content.length > 50 ? '${node.content.substring(0, 50)}...' : node.content) : 'Empty Text Node'),
          subtitle: 'In Canvas: ${doc.name.isEmpty ? 'Untitled' : doc.name}',
          icon: LucideIcons.box,
          category: 'CANVAS_NOTE',
          action: () {
            ref.read(navigationProvider.notifier).setPage(AppPage.canvas);
            ref.read(selectedCanvasIdProvider.notifier).set(doc.id);
          },
        );
      })),
      // Events last — still searchable but lower priority than tasks
      ...events.map((t) => CommandPaletteItem(
        id: 'EVENT_${t.id}',
        title: t.title,
        subtitle: 'Event',
        icon: LucideIcons.calendarDays,
        category: 'EVENT',
        action: () {
          ref.read(navigationProvider.notifier).setPage(AppPage.calendar);
        },
      )),
    ];

    if (query.isEmpty && _selectedFilter == 'All') {
      // Real Recent History
      List<CommandPaletteItem> recentItems = [];
      final recentIds = ref.watch(recentCommandsProvider);

      for (final id in recentIds) {
        try {
          final item = allItems.firstWhere((i) => i.id == id);
          recentItems.add(CommandPaletteItem(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            icon: LucideIcons.history,
            category: item.category,
            action: item.action,
            route: item.route,
          ));
        } catch (e) {
          // Item might have been deleted, ignore it
        }
      }

      List<CommandPaletteItem> emptyStateItems = [];
      if (recentItems.isNotEmpty) {
        emptyStateItems.add(CommandPaletteItem(title: 'Recent', isHeader: true));
        emptyStateItems.addAll(recentItems);
      }

      // Quick Actions removed as requested

      _filteredItems = emptyStateItems;
      
      // Ensure selected index is not on a header
      if (_filteredItems.isNotEmpty && _selectedIndex < _filteredItems.length && _filteredItems[_selectedIndex].isHeader) {
        _selectedIndex = _filteredItems.indexWhere((i) => !i.isHeader);
        if (_selectedIndex == -1) _selectedIndex = 0;
      }
    } else {
      _filteredItems = allItems.where((item) {
        bool matchesQuery = query.isEmpty || item.title.toLowerCase().contains(query) || 
                            (item.subtitle?.toLowerCase().contains(query) ?? false);
        
        if (!matchesQuery) return false;
        
        if (_selectedFilter == 'All') {
          // Previously we hid static links from the general search, but users expect to find pages/settings in All
          return true;
        }
        
        if (_selectedFilter == 'Dashboard' && item.route == AppPage.home) return true;
        if (_selectedFilter == 'Notes' && (item.route == AppPage.notes || item.category == 'NOTE')) return true;
        if (_selectedFilter == 'Tasks' && (item.route == AppPage.tasks || item.category == 'TASK')) return true;
        if (_selectedFilter == 'Calendar' && (item.route == AppPage.calendar || item.category == 'EVENT')) return true;
        if (_selectedFilter == 'Habits' && (item.route == AppPage.habits || item.category == 'HABIT')) return true;
        if (_selectedFilter == 'Canvas' && (item.route == AppPage.canvas || item.category == 'CANVAS_NOTE' || item.category == 'CANVAS_MEDIA')) return true;
        if (_selectedFilter == 'Workout' && (item.route == AppPage.workout || item.category == 'WORKOUT')) return true;
        if (_selectedFilter == 'AI Assistant' && (item.route == AppPage.ai || item.category == 'AI_CHAT')) return true;
        if (_selectedFilter == 'BoxClock' && item.route == AppPage.boxclock) return true;
        if (_selectedFilter == 'App Tracker' && (item.route == AppPage.appTracker || item.category == 'APP_TRACKER')) return true;
        if (_selectedFilter == 'Settings' && (item.route == AppPage.settings || item.category == 'SETTING')) return true;
        
        if (_selectedFilter == 'Commands' && item.category == 'COMMAND') return true;
        if (_selectedFilter == 'Media' && (item.category == 'MEDIA' || item.category == 'CANVAS_MEDIA')) return true;
        
        return false;
      }).toList();
    }

    if (_selectedIndex >= _filteredItems.length) {
      _selectedIndex = math.max(0, _filteredItems.length - 1);
      // Make sure we didn't land on a header
      while (_selectedIndex > 0 && _filteredItems[_selectedIndex].isHeader) {
        _selectedIndex--;
      }
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const ClosePaletteIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const ClosePaletteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ClosePaletteIntent: CallbackAction<ClosePaletteIntent>(
            onInvoke: (ClosePaletteIntent intent) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          elevation: 0,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: RawKeyboardListener(
              focusNode: FocusNode(), // Dummy focus node just for catching keys not caught by text field
              onKey: _handleKeyEvent,
              child: Container(
                width: 800,
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, size: 24, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onSubmitted: (_) {
                                if (_filteredItems.isNotEmpty && !_filteredItems[_selectedIndex].isHeader) {
                                  _handleSelection(_filteredItems[_selectedIndex]);
                                }
                              },
                              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Search pages, notes, tasks, habits, tools, commands...',
                                hintStyle: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Text(
                              'Ctrl + F',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Filter Row
                    if (query.isNotEmpty) ...[
                      Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedFilter = filter;
                                  _selectedIndex = 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? theme.primaryColor 
                                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    
                    // Results List
                    if (_filteredItems.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            
                            if (item.isHeader) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            }

                            final isSelected = index == _selectedIndex;
                            
                            return InkWell(
                              onTap: () => _handleSelection(item),
                              onHover: (hovering) {
                                if (hovering) {
                                  setState(() => _selectedIndex = index);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04))
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                          ? theme.primaryColor.withValues(alpha: 0.1)
                                          : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 16,
                                        color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected 
                                                  ? (isDark ? Colors.white : Colors.black)
                                                  : theme.textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subtitle!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (item.shortcut != null) ...[
                                      Text(
                                        item.shortcut!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    if (item.category != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.category!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        LucideIcons.cornerDownLeft,
                                        size: 14,
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 32.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.searchX, size: 48, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching for pages, notes, tasks, habits, tools, or commands.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
