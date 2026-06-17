import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../models/calendar.dart';
import '../../../providers/calendar_provider.dart';
import '../../../theme/app_colors.dart';

/// The focus/progress widget shown in the right sidebar.
/// Displays task completion progress for the selected day.
class CalendarFocusWidget extends ConsumerWidget {
  const CalendarFocusWidget({
    super.key,
    required this.dayTasks,
  });

  final List<Task> dayTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final calendars = ref.watch(calendarProvider);

    final taskItems = dayTasks.where((t) {
      final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null')
          ? 'default_tasks'
          : t.calendarId!;
      final parentCal = calendars.firstWhere(
        (c) => c.id == cId,
        orElse: () => calendars.firstWhere(
          (c) => c.id == 'default_tasks',
          orElse: () => calendars.first,
        ),
      );
      return parentCal.isTaskCalendar;
    }).toList();

    final doneTasks = taskItems.where((t) => t.status == TaskStatus.done).length;
    final totalTasks = taskItems.length;
    final progress = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus on work span',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const Gap(20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FocusStat(icon: LucideIcons.briefcase, label: '$totalTasks total'),
                  const Gap(8),
                  _FocusStat(icon: LucideIcons.checkCircle, label: '$doneTasks completed'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusStat extends StatelessWidget {
  const _FocusStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
        const Gap(8),
        Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
      ],
    );
  }
}
