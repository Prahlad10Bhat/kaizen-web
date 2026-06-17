import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    Color priorityColor;
    String label;

    switch (priority) {
      case TaskPriority.high:
        priorityColor = appColors.highPriority;
        label = 'High';
        break;
      case TaskPriority.medium:
        priorityColor = appColors.mediumPriority;
        label = 'Medium';
        break;
      case TaskPriority.low:
        priorityColor = appColors.lowPriority;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: priorityColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
