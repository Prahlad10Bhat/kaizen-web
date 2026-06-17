import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../models/calendar.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/calendar_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/universal_task_dialog.dart';

/// A single item row shown in the right sidebar task list.
/// Displays a task or event with toggle, edit, and delete actions.
class CalendarCheckItem extends ConsumerWidget {
  const CalendarCheckItem({
    super.key,
    required this.task,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);
    final isDone = task.status == TaskStatus.done;

    final cId = (task.calendarId == null || task.calendarId == '' || task.calendarId == 'null')
        ? 'default_tasks'
        : task.calendarId!;
    final parentCal = calendars.firstWhere(
      (c) => c.id == cId,
      orElse: () => calendars.firstWhere(
        (c) => c.id == 'default_tasks',
        orElse: () => calendars.first,
      ),
    );
    final isTaskCalendar = parentCal.isTaskCalendar;
    final calendarColor = Color(parentCal.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: isTaskCalendar
                  ? () {
                      final newStatus = isDone ? TaskStatus.todo : TaskStatus.done;
                      ref.read(taskProvider.notifier).updateTask(task.copyWith(status: newStatus));
                    }
                  : null,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Row(
                  children: [
                    if (isTaskCalendar) ...[
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDone ? theme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone ? theme.primaryColor : theme.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: isDone
                            ? Icon(LucideIcons.check, size: 14, color: theme.colorScheme.onPrimary)
                            : null,
                      ),
                    ] else ...[
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: calendarColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: calendarColor, width: 1.5),
                        ),
                        child: Icon(LucideIcons.calendarDays, size: 10, color: calendarColor),
                      ),
                    ],
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDone
                                  ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.4)
                                  : theme.textTheme.bodyLarge?.color,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              decorationColor: theme.primaryColor.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isTaskCalendar ? 'Task' : 'Event',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => UniversalTaskDialog(
                  initialTask: task,
                  isEventContext: !isTaskCalendar,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Icon(
                LucideIcons.pencil,
                size: 14,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 16, 12),
              child: Icon(
                LucideIcons.trash2,
                size: 14,
                color: Colors.redAccent.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
