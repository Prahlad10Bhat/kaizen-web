import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../models/calendar.dart';
import '../../../providers/calendar_provider.dart';
import '../../../theme/app_colors.dart';

/// Renders the monthly calendar grid with day cells, task dots, and selection state.
class CalendarGrid extends ConsumerWidget {
  const CalendarGrid({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.allTasks,
    required this.isUltraCompact,
    required this.isSidebarExpanded,
    required this.searchQuery,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Task> allTasks;
  final bool isUltraCompact;
  final bool isSidebarExpanded;
  final String searchQuery;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);
    final daysOfWeek = isUltraCompact
        ? ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final double aspectRatio = isUltraCompact ? (isSidebarExpanded ? 1.0 : 0.85) : 1.2;

    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final prevMonthLastDay = DateTime(focusedDay.year, focusedDay.month, 0);

    final filteredTasks = searchQuery.isEmpty
        ? allTasks
        : allTasks.where((t) => t.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Row(
          children: daysOfWeek.map((day) => Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  day,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: isUltraCompact ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: isUltraCompact ? 4 : 8,
              mainAxisSpacing: isUltraCompact ? 4 : 8,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              DateTime day;
              bool isCurrentMonth = true;

              if (index < firstDayWeekday) {
                day = DateTime(focusedDay.year, focusedDay.month - 1,
                    prevMonthLastDay.day - (firstDayWeekday - index - 1));
                isCurrentMonth = false;
              } else if (index < firstDayWeekday + daysInMonth) {
                day = DateTime(focusedDay.year, focusedDay.month, index - firstDayWeekday + 1);
              } else {
                day = DateTime(focusedDay.year, focusedDay.month + 1,
                    index - (firstDayWeekday + daysInMonth) + 1);
                isCurrentMonth = false;
              }

              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final isSelected = DateUtils.isSameDay(day, selectedDay);

              final dayTasks = filteredTasks
                  .where((t) => t.dueDate != null && DateUtils.isSameDay(t.dueDate!, day))
                  .toList();

              int taskCount = 0;
              int eventCount = 0;
              Color? singleColor;
              for (final t in dayTasks) {
                final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null')
                    ? 'default_tasks'
                    : t.calendarId!;
                final cal = calendars.firstWhere(
                  (c) => c.id == cId,
                  orElse: () => calendars.firstWhere(
                    (c) => c.id == 'default_tasks',
                    orElse: () => calendars.first,
                  ),
                );
                if (cal.isTaskCalendar) {
                  taskCount++;
                } else {
                  eventCount++;
                }
                final calColor = Color(cal.colorValue);
                if (singleColor == null) {
                  singleColor = calColor;
                } else if (singleColor != calColor) {
                  singleColor = theme.primaryColor;
                }
              }
              final displayColor = singleColor ?? theme.primaryColor;

              return _CalendarDayCell(
                day: day,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                dayTasks: dayTasks,
                taskCount: taskCount,
                eventCount: eventCount,
                displayColor: displayColor,
                calendars: calendars,
                isUltraCompact: isUltraCompact,
                appColors: appColors,
                onTap: () => onDaySelected(day),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.dayTasks,
    required this.taskCount,
    required this.eventCount,
    required this.displayColor,
    required this.calendars,
    required this.isUltraCompact,
    required this.appColors,
    required this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<Task> dayTasks;
  final int taskCount;
  final int eventCount;
  final Color displayColor;
  final List<Calendar> calendars;
  final bool isUltraCompact;
  final AppColorsExtension appColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isToday
                    ? theme.primaryColor.withValues(alpha: 0.15)
                    : appColors.calendarAccent.withValues(alpha: 0.15))
                : (isCurrentMonth
                    ? appColors.calendarSurface
                    : appColors.calendarSurface.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? (isSelected
                      ? theme.primaryColor
                      : theme.primaryColor.withValues(alpha: 0.4))
                  : (isSelected
                      ? appColors.calendarAccent.withValues(alpha: 0.5)
                      : Colors.transparent),
              width: isToday ? 2 : 1,
            ),
          ),
          padding: EdgeInsets.all(isUltraCompact ? 4 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: isToday
                      ? (isSelected
                          ? theme.primaryColor
                          : theme.primaryColor.withValues(alpha: 0.5))
                      : (isSelected
                          ? appColors.calendarAccent
                          : (isCurrentMonth
                              ? theme.textTheme.bodyLarge?.color
                              : theme.textTheme.bodySmall?.color)),
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isUltraCompact ? 10 : 12,
                ),
              ),
              const Gap(4),
              if (dayTasks.isNotEmpty)
                Tooltip(
                  message: dayTasks.map((t) {
                    final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null')
                        ? 'default_tasks'
                        : t.calendarId!;
                    final parentCalendar = calendars.firstWhere(
                      (c) => c.id == cId,
                      orElse: () => calendars.firstWhere(
                        (c) => c.id == 'default_tasks',
                        orElse: () => calendars.first,
                      ),
                    );
                    return '• [${parentCalendar.name}] ${t.title} (${DateFormat('HH:mm').format(t.dueDate!)})';
                  }).join('\n'),
                  textStyle: TextStyle(fontSize: 12, color: theme.textTheme.bodyLarge?.color),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isUltraCompact ? 4 : 6,
                      vertical: isUltraCompact ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        displayColor.withValues(alpha: 0.15),
                        appColors.calendarSurface,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isUltraCompact) ...[
                          Text(
                            [
                              if (taskCount > 0) '$taskCount Task${taskCount > 1 ? 's' : ''}',
                              if (eventCount > 0) '$eventCount Event${eventCount > 1 ? 's' : ''}',
                            ].join(', '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: displayColor,
                            ),
                          ),
                          const Gap(4),
                        ],
                        ...dayTasks.take(4).map((t) {
                          final cId = (t.calendarId == null ||
                                  t.calendarId == '' ||
                                  t.calendarId == 'null')
                              ? 'default_tasks'
                              : t.calendarId!;
                          final cal = calendars.firstWhere(
                            (c) => c.id == cId,
                            orElse: () => calendars.firstWhere(
                              (c) => c.id == 'default_tasks',
                              orElse: () => calendars.first,
                            ),
                          );
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Color(cal.colorValue),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
