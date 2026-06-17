import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/settings_provider.dart';
import 'widgets/board_column.dart';
import '../../widgets/universal_task_dialog.dart';
import '../../../models/calendar.dart';
import '../../../providers/calendar_provider.dart';
import '../../../services/app_tour_service.dart';
import '../../../widgets/custom_context_menu.dart';

class SortCriteria {
  final String field;
  final bool ascending;

  SortCriteria(this.field, this.ascending);
}

class TaskBoardTabNotifier extends Notifier<String> {
  @override
  String build() => 'Lists';

  void setTab(String tab) => state = tab;
}

final taskBoardTabProvider = NotifierProvider<TaskBoardTabNotifier, String>(() {
  return TaskBoardTabNotifier();
});

class TaskBoardPage extends ConsumerStatefulWidget {
  const TaskBoardPage({super.key});

  @override
  ConsumerState<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends ConsumerState<TaskBoardPage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _vScrollController = ScrollController();
  
  bool _isPanning = false;
  String _searchQuery = '';
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  
  // Multi-column sorting
  List<SortCriteria> _sortCriteria = [SortCriteria('Due Date', true)];
  
  bool _isCompactView = false;
  bool _isSearchOpen = false;

  final List<String> _tabs = ['Overview', 'Lists', 'Board'];
  Set<String> _selectedTaskIds = {};
  String? _hoveredTaskId;
  bool _isHeaderHovered = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  void _toggleSort(String field, {bool multi = false}) {
    setState(() {
      final existingIndex = _sortCriteria.indexWhere((c) => c.field == field);
      
      if (existingIndex != -1) {
        final existing = _sortCriteria[existingIndex];
        if (existing.ascending) {
          // Switch to Descending
          _sortCriteria[existingIndex] = SortCriteria(field, false);
        } else {
          // Remove this sort
          _sortCriteria.removeAt(existingIndex);
          // If no sort left, reset to Due Date
          if (_sortCriteria.isEmpty) {
            _sortCriteria = [SortCriteria('Due Date', true)];
          }
        }
      } else {
        // Add new sort
        if (!multi) {
          _sortCriteria = [SortCriteria(field, true)];
        } else {
          _sortCriteria.add(SortCriteria(field, true));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);
    final activeTab = ref.watch(taskBoardTabProvider);
    final theme = Theme.of(context);
    final calendars = ref.watch(calendarProvider);

    final filteredTasks = allTasks.where((task) {
      final parentCalendar = calendars.firstWhere(
        (c) => c.id == task.calendarId,
        orElse: () => calendars.firstWhere(
          (c) => c.id == 'default_tasks', 
          orElse: () => const Calendar(id: 'default_tasks', name: 'Default Tasks', colorValue: 0xFF6C63FF, isTaskCalendar: true),
        ),
      );
      if (!parentCalendar.isTaskCalendar) {
        return false;
      }
      
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == null || task.status == _filterStatus;
      final matchesPriority = _filterPriority == null || task.priority == _filterPriority;
      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();

    // Multi-column Sorting Logic
    filteredTasks.sort((a, b) {
      for (final criteria in _sortCriteria) {
        int cmp = 0;
        switch (criteria.field) {
          case 'Due Date':
            cmp = (a.dueDate ?? DateTime(3000)).compareTo(b.dueDate ?? DateTime(3000));
            break;
          case 'Priority':
            cmp = a.priority.index.compareTo(b.priority.index);
            break;
          case 'Title':
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case 'Status':
            cmp = a.status.index.compareTo(b.status.index);
            break;
        }
        
        if (cmp != 0) {
          return criteria.ascending ? cmp : -cmp;
        }
      }
      return 0;
    });
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Tasks',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Gap(12),
                            IconButton(
                              onPressed: () => _showSettingsDialog(context),
                              icon: Icon(LucideIcons.settings, size: 20, color: theme.textTheme.labelLarge?.color),
                              tooltip: 'Settings & Controls',
                            ),
                          ],
                        ),
                        const Gap(16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ..._tabs.map((tab) => _buildTab(context, tab, isActive: activeTab == tab)),
                            const Gap(12),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const UniversalTaskDialog(),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.plus, size: 14, color: theme.primaryColor),
                                    const Gap(8),
                                    Text(
                                      'New Task',
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'New Task',
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_isSearchOpen)
                          Container(
                            width: 200,
                            height: 36,
                            margin: const EdgeInsets.only(right: 12),
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              autofocus: true,
                              style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: theme.cardColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                                suffixIcon: IconButton(
                                  icon: const Icon(LucideIcons.x, size: 14),
                                  onPressed: () => setState(() {
                                    _isSearchOpen = false;
                                    _searchQuery = '';
                                  }),
                                ),
                              ),
                            ),
                          )
                        else
                          _buildActionButton(context, LucideIcons.search, 'Search', onTap: () => setState(() => _isSearchOpen = true)),
                        const Gap(12),
                        const Gap(12),
                        _buildActionButton(
                          context, 
                          LucideIcons.rotateCcw, 
                          'Reset', 
                          onTap: () => setState(() {
                            _filterStatus = null;
                            _filterPriority = null;
                            _sortCriteria = [SortCriteria('Due Date', true)];
                            _searchQuery = '';
                            _isSearchOpen = false;
                          }),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              
              const Gap(16),
              
              Expanded(
                child: _buildTabContent(filteredTasks, activeTab),
              ),
            ],
          ),
          if (_selectedTaskIds.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dialogTheme.backgroundColor ?? theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedTaskIds.length} Selected',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(16),
                      Container(width: 1, height: 20, color: theme.dividerColor),
                      const Gap(16),
                      _buildBarButton(
                        context: context,
                        icon: LucideIcons.checkCircle2,
                        label: 'Complete',
                        color: theme.primaryColor,
                        onTap: () {
                          for (final id in _selectedTaskIds) {
                            ref.read(taskProvider.notifier).updateTaskStatus(id, TaskStatus.done);
                          }
                          setState(() => _selectedTaskIds.clear());
                        },
                      ),
                      const Gap(12),
                      _buildBarButton(
                        context: context,
                        icon: LucideIcons.refreshCw,
                        label: 'In Progress',
                        color: Colors.orangeAccent,
                        onTap: () {
                          for (final id in _selectedTaskIds) {
                            ref.read(taskProvider.notifier).updateTaskStatus(id, TaskStatus.inProgress);
                          }
                          setState(() => _selectedTaskIds.clear());
                        },
                      ),
                      const Gap(12),
                      _buildBarButton(
                        context: context,
                        icon: LucideIcons.circle,
                        label: 'To Do',
                        color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                        onTap: () {
                          for (final id in _selectedTaskIds) {
                            ref.read(taskProvider.notifier).updateTaskStatus(id, TaskStatus.todo);
                          }
                          setState(() => _selectedTaskIds.clear());
                        },
                      ),
                      const Gap(12),
                      _buildBarButton(
                        context: context,
                        icon: LucideIcons.trash2,
                        label: 'Delete',
                        color: Colors.redAccent,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: theme.dialogTheme.backgroundColor,
                              shape: theme.dialogTheme.shape,
                              title: Text('Delete Selected', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                              content: Text(
                                'Are you sure you want to delete the ${_selectedTaskIds.length} selected tasks? This action cannot be undone.',
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            for (final id in _selectedTaskIds) {
                              ref.read(taskProvider.notifier).removeTask(id);
                            }
                            setState(() => _selectedTaskIds.clear());
                          }
                        },
                      ),
                      const Gap(16),
                      Container(width: 1, height: 20, color: theme.dividerColor),
                      const Gap(12),
                      IconButton(
                        onPressed: () => setState(() => _selectedTaskIds.clear()),
                        icon: const Icon(LucideIcons.x, size: 16),
                        tooltip: 'Clear Selection',
                        color: theme.textTheme.bodySmall?.color,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const Gap(6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildActionButton(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerTheme.color ?? Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.textTheme.bodyMedium?.color),
              const Gap(8),
              Text(label, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, {bool isActive = false}) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ref.read(taskBoardTabProvider.notifier).setTab(title),
        child: Container(
          margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? theme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<Task> tasks, String activeTab) {
    if (tasks.isEmpty) {
      return _buildEmptyState(context, isSearching: _searchQuery.isNotEmpty);
    }
    
    switch (activeTab) {
      case 'Overview':
        return _buildOverview(tasks);
      case 'Lists':
        return _buildLists(tasks);
      case 'Board':
        return _buildBoard(tasks);
      default:
        return _buildBoard(tasks);
    }
  }

  Widget _buildOverview(List<Task> tasks) {
    final theme = Theme.of(context);
    final completed = tasks.where((t) => t.status == TaskStatus.done).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard(context, 'Total Tasks', tasks.length.toString(), LucideIcons.layers, theme.primaryColor),
              const Gap(24),
              _buildStatCard(context, 'Completed', completed.toString(), LucideIcons.checkCircle2, _getStatusColor(TaskStatus.done)),
              const Gap(24),
              _buildStatCard(context, 'In Progress', inProgress.toString(), LucideIcons.refreshCw, _getStatusColor(TaskStatus.inProgress)),
              const Gap(24),
              _buildStatCard(context, 'Upcoming', todo.toString(), LucideIcons.clock, _getStatusColor(TaskStatus.todo)),
            ],
          ),
          const Gap(48),
          Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const Gap(24),
          ...tasks.take(5).map((t) => _buildActivityItem(t)),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerTheme.color ?? Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const Gap(12),
            Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Task task) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                Text('Updated in ${task.status.name}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          Text(
            task.dueDate != null ? DateFormat('MMM dd').format(task.dueDate!) : 'No date',
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildLists(List<Task> tasks) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.transparent),
      ),
      child: Column(
        children: [
          _buildListHeader(context, tasks),
          Expanded(
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerTheme.color),
              itemBuilder: (context, index) => _buildListRow(context, tasks[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);
    
    Widget headerCell(String label, String sortField, int flex) {
      final criteriaIndex = _sortCriteria.indexWhere((c) => c.field == sortField);
      final isSorting = criteriaIndex != -1;
      final isAscending = isSorting ? _sortCriteria[criteriaIndex].ascending : true;

      return Expanded(
        flex: flex,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
          onTap: () => _toggleSort(sortField, multi: false),
          onLongPress: () => _toggleSort(sortField, multi: true),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSorting ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                if (isSorting) ...[
                  const Gap(4),
                  Icon(
                    isAscending ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 12,
                    color: theme.primaryColor,
                  ),
                  if (_sortCriteria.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '${criteriaIndex + 1}',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: theme.primaryColor),
                      ),
                    ),
                ],
              ],
            ),
          ),
        )),
      );
    }

    final allChecked = tasks.isNotEmpty && tasks.every((t) => _selectedTaskIds.contains(t.id));
    final anyChecked = _selectedTaskIds.isNotEmpty && !allChecked;
    final isSelectedAny = _selectedTaskIds.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHeaderHovered = true),
      onExit: (_) => setState(() => _isHeaderHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 36), // Align with row completion status icon
            headerCell('TASK NAME', 'Title', 4),
            headerCell('STATUS', 'Status', 2),
            headerCell('PRIORITY', 'Priority', 2),
            headerCell('DUE DATE', 'Due Date', 2),
            SizedBox(
              width: 36,
              child: Align(
                alignment: Alignment.centerRight,
                child: Visibility(
                  visible: isSelectedAny || _isHeaderHovered,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Checkbox(
                    value: allChecked,
                    tristate: anyChecked,
                    activeColor: theme.primaryColor,
                    checkColor: Colors.white,
                    shape: const CircleBorder(),
                    side: BorderSide(
                      color: (theme.textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedTaskIds.addAll(tasks.map((t) => t.id));
                        } else {
                          for (final t in tasks) {
                            _selectedTaskIds.remove(t.id);
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, Task task) async {
    final settings = ref.read(settingsProvider);
    final theme = Theme.of(context);
    
    if (!settings.askBeforeDelete) {
      ref.read(taskProvider.notifier).removeTask(task.id);
      return;
    }

    bool dontShowAgain = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: theme.dialogTheme.shape,
            title: Text('Delete Task', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this task? This action cannot be undone.',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const Gap(24),
                InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => setState(() => dontShowAgain = !dontShowAgain),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: dontShowAgain,
                          onChanged: (val) => setState(() => dontShowAgain = val ?? false),
                          activeColor: theme.primaryColor,
                          visualDensity: VisualDensity.compact,
                          toggleable: true,
                        ),
                        const Gap(8),
                        Text(
                          "Don't show me again",
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (dontShowAgain) {
                    ref.read(settingsProvider.notifier).setAskBeforeDelete(false);
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    if (confirm == true) {
      ref.read(taskProvider.notifier).removeTask(task.id);
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(settingsProvider);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.dialogTheme.backgroundColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tasks Controls', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const Gap(24),
                    _buildHelpItem(context, LucideIcons.layoutGrid, 'Board View', 'Drag & drop to move tasks between columns'),
                    const Gap(16),
                    _buildHelpItem(context, LucideIcons.list, 'Lists View', 'Click headers to sort, right-click to delete tasks'),
                    const Gap(16),
                    _buildHelpItem(context, LucideIcons.plus, 'Quick Add', 'Press New Task to create via universal dialog'),
                    const Gap(32),
                    Divider(color: theme.dividerColor),
                    const Gap(24),
                    Text('Settings', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Gap(16),
                    InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => ref.read(settingsProvider.notifier).setAskBeforeDelete(!settings.askBeforeDelete),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.shieldAlert, size: 16, color: theme.textTheme.bodyMedium?.color),
                                const Gap(12),
                                Text('Ask before deleting', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
                              ],
                            ),
                            Switch(
                              value: settings.askBeforeDelete,
                              onChanged: (val) => ref.read(settingsProvider.notifier).setAskBeforeDelete(val),
                              activeColor: theme.primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(32),
                    Center(child: Text('Kaizen Tasks v1.0', style: TextStyle(color: theme.textTheme.labelLarge?.color, fontSize: 11))),
                    const Gap(8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.primaryColor),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.bold)),
                const Gap(4),
                Text(description, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.done;
    final isSelected = _selectedTaskIds.contains(task.id);
    final isSelectedAny = _selectedTaskIds.isNotEmpty;
    final isHovered = _hoveredTaskId == task.id;
    
    // Helper to capitalize status name
    String formatStatus(String name) {
      if (name == 'todo') return 'To Do';
      if (name == 'inProgress') return 'In Progress';
      if (name == 'done') return 'Completed';
      return name[0].toUpperCase() + name.substring(1);
    }

    String formatPriority(String name) {
      return name[0].toUpperCase() + name.substring(1);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTaskId = task.id),
      onExit: (_) => setState(() => _hoveredTaskId = null),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) {
          showCustomContextMenu(
            context: context,
            position: details.globalPosition,
            items: [
              CustomContextMenuItem(
                icon: LucideIcons.trash2,
                label: 'Delete',
                shortcut: 'Del',
                isDestructive: true,
                onTap: () {
                  _handleDelete(context, task);
                },
              ),
            ],
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Column 0: Task Completion Icon (always visible, always checks off task)
              SizedBox(
                width: 36,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      final newStatus = isCompleted ? TaskStatus.todo : TaskStatus.done;
                      ref.read(taskProvider.notifier).updateTaskStatus(task.id, newStatus);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                        size: 18,
                        color: isCompleted ? theme.primaryColor : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
              // Column 1: Task Title
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: () {
                    final newStatus = isCompleted ? TaskStatus.todo : TaskStatus.done;
                    ref.read(taskProvider.notifier).updateTaskStatus(task.id, newStatus);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Text(
                      task.title, 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCompleted ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) : theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              ),
              // Column 2: Status Badge
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 100, // Fixed width for badges
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(task.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getStatusColor(task.status).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        formatStatus(task.status.name), 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(task.status), letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Column 3: Priority
              Expanded(
                flex: 2,
                child: Text(
                  formatPriority(task.priority.name), 
                  style: TextStyle(fontSize: 12, color: _getPriorityColor(task.priority), fontWeight: FontWeight.w500),
                ),
              ),
              // Column 4: Due Date
              Expanded(
                flex: 2,
                child: Text(
                  task.dueDate != null ? DateFormat('MMM dd, yyyy').format(task.dueDate!) : '-',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                ),
              ),
              // Column 5: Selection Checkbox
              SizedBox(
                width: 36,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Visibility(
                    visible: isSelected || isHovered || isSelectedAny,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: theme.primaryColor,
                      checkColor: Colors.white,
                      shape: const CircleBorder(),
                      side: BorderSide(
                        color: (theme.textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTaskIds.add(task.id);
                          } else {
                            _selectedTaskIds.remove(task.id);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildBoard(List<Task> filteredTasks) {
    return MouseRegion(
      cursor: _isPanning ? SystemMouseCursors.grabbing : MouseCursor.defer,
      child: Listener(
        onPointerDown: (event) {
          if (event.buttons == 2) {
            setState(() => _isPanning = true);
          }
        },
        onPointerUp: (event) {
          if (_isPanning) {
            setState(() => _isPanning = false);
          }
        },
        onPointerCancel: (event) {
          if (_isPanning) {
            setState(() => _isPanning = false);
          }
        },
        onPointerMove: (event) {
          if (event.buttons == 2) {
            if (_scrollController.hasClients) {
              final newOffset = _scrollController.offset - event.delta.dx;
              _scrollController.jumpTo(
                newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
              );
            }
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = (constraints.maxHeight - 64).clamp(0.0, double.infinity);
            
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(40, 64, 40, 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 1500,
                    minHeight: screenHeight,
                  ),
                  child: Row(
                    key: AppTourKeys.taskBoardKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BoardColumn(title: 'To Do', status: TaskStatus.todo, maxHeight: screenHeight, tasks: filteredTasks.where((t) => t.status == TaskStatus.todo).toList()),
                      BoardColumn(title: 'In Progress', status: TaskStatus.inProgress, maxHeight: screenHeight, tasks: filteredTasks.where((t) => t.status == TaskStatus.inProgress).toList()),
                      BoardColumn(title: 'Completed', status: TaskStatus.done, maxHeight: screenHeight, tasks: filteredTasks.where((t) => t.status == TaskStatus.done).toList()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return const Color(0xFFE57373);
      case TaskPriority.medium: return const Color(0xFFFFB74D);
      case TaskPriority.low: return const Color(0xFF81C784);
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return const Color(0xFF6C63FF);
      case TaskStatus.inProgress: return const Color(0xFFFFB74D);
      case TaskStatus.done: return const Color(0xFF81C784);
    }
  }

  Widget _buildEmptyState(BuildContext context, {required bool isSearching}) {
    final theme = Theme.of(context);
    
    if (isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No search results found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const Gap(12),
            Text(
              'Try adjusting your search query',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(LucideIcons.checkSquare, size: 48, color: theme.primaryColor),
              ),
              const Gap(24),
              Text(
                'Start Achieving',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const Gap(8),
              SizedBox(
                width: 340,
                child: Text(
                  'Every big goal is just a series of small tasks. Create your first task to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                ),
              ),
              const Gap(32),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const UniversalTaskDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  elevation: 0,
                ),
                child: const Text('Create First Task', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
