import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../models/calendar.dart';
import '../../../providers/calendar_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/universal_task_dialog.dart';
import '../../../utils/snackbar_utils.dart';
import 'calendar_check_item.dart';
import 'calendar_focus_widget.dart';

/// Right sidebar for the calendar page, shows selected day details,
/// focus stats, and task/event list with CRUD actions.
class CalendarRightSidebar extends ConsumerStatefulWidget {
  const CalendarRightSidebar({
    super.key,
    required this.selectedDay,
    required this.allTasks,
  });

  final DateTime selectedDay;
  final List<Task> allTasks;

  @override
  ConsumerState<CalendarRightSidebar> createState() => _CalendarRightSidebarState();
}

class _CalendarRightSidebarState extends ConsumerState<CalendarRightSidebar> {
  Future<void> _handleDelete(Task task, bool isTaskCalendar) async {
    final settings = ref.read(settingsProvider);
    final theme = Theme.of(context);

    if (!settings.askBeforeDelete) {
      ref.read(taskProvider.notifier).removeTask(task.id);
      if (mounted) {
        SnackbarUtils.showCustomSnackBar(
          context,
          isTaskCalendar ? 'Task deleted' : 'Event deleted',
        );
      }
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
            title: Text(
              isTaskCalendar ? 'Delete Task' : 'Delete Event',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this ${isTaskCalendar ? 'task' : 'event'}? This action cannot be undone.',
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

    if (confirm == true && mounted) {
      ref.read(taskProvider.notifier).removeTask(task.id);
      if (mounted) {
        SnackbarUtils.showCustomSnackBar(
          context,
          isTaskCalendar ? 'Task deleted' : 'Event deleted',
        );
      }
    }
  }

  String _resolveCalendarId(Task task) {
    return (task.calendarId == null || task.calendarId == '' || task.calendarId == 'null')
        ? 'default_tasks'
        : task.calendarId!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);

    final selectedDayTasks = widget.allTasks.where((t) =>
      t.dueDate != null && DateUtils.isSameDay(t.dueDate!, widget.selectedDay)
    ).toList();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: appColors.calendarSurface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMM yyyy').format(widget.selectedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          CalendarFocusWidget(dayTasks: selectedDayTasks),
          const Gap(32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks & Events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              MenuAnchor(
                builder: (context, controller, child) {
                  return ElevatedButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      '+ New',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: Icon(LucideIcons.checkSquare, size: 16, color: theme.primaryColor),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => UniversalTaskDialog(
                          isEventContext: false,
                          initialDate: widget.selectedDay,
                        ),
                      );
                    },
                    child: const Text('New Task'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.calendarDays, size: 16, color: Colors.blueAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => UniversalTaskDialog(
                          isEventContext: true,
                          initialDate: widget.selectedDay,
                        ),
                      );
                    },
                    child: const Text('New Event'),
                  ),
                ],
              ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: selectedDayTasks.isEmpty
                ? Center(
                    child: Text(
                      'No scheduled items',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedDayTasks.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final task = selectedDayTasks[index];
                      final cId = _resolveCalendarId(task);
                      final parentCal = calendars.firstWhere(
                        (c) => c.id == cId,
                        orElse: () => calendars.firstWhere(
                          (c) => c.id == 'default_tasks',
                          orElse: () => calendars.first,
                        ),
                      );
                      final isTaskCalendar = parentCal.isTaskCalendar;
                      return CalendarCheckItem(
                        key: ValueKey(task.id),
                        task: task,
                        onDelete: () => _handleDelete(task, isTaskCalendar),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
