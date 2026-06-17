import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/avatar_stack.dart';
import '../../../widgets/priority_badge.dart';
import '../../../widgets/tag_chip.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/universal_task_dialog.dart';
import '../../../widgets/custom_context_menu.dart';

class TaskCardWidget extends ConsumerStatefulWidget {
  final Task task;
  final bool isCompact;

  const TaskCardWidget({super.key, required this.task, this.isCompact = false});

  @override
  ConsumerState<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends ConsumerState<TaskCardWidget> {
  bool _isHovered = false;

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => UniversalTaskDialog(initialTask: widget.task),
    );
  }

  void _showContextMenu(Offset position) {
    showCustomContextMenu(
      context: context,
      position: position,
      items: [
        CustomContextMenuItem(
          icon: LucideIcons.edit2,
          label: 'Edit Task',
          onTap: () => Future.delayed(Duration.zero, _showEditDialog),
        ),
        CustomContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'Delete',
          isDestructive: true,
          onTap: () => Future.delayed(Duration.zero, () {
            ref.read(taskProvider.notifier).removeTask(widget.task.id);
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    Color priorityColor;
    switch (widget.task.priority) {
      case TaskPriority.high: priorityColor = appColors.highPriority; break;
      case TaskPriority.medium: priorityColor = appColors.mediumPriority; break;
      case TaskPriority.low: priorityColor = appColors.lowPriority; break;
    }

    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTap: _showEditDialog,
      onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) { if (mounted) setState(() => _isHovered = true); },
        onExit: (_) { if (mounted) setState(() => _isHovered = false); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? priorityColor.withValues(alpha: 0.4) : priorityColor.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: priorityColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PriorityBadge(priority: widget.task.priority),
                        ...widget.task.tags.map((tag) => TagChip(label: tag)),
                      ],
                    ),
                  ),
                  Gap(widget.isCompact ? 8 : 12),
                  Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (!widget.isCompact && widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                    const Gap(6),
                    Text(
                      widget.task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                  Gap(widget.isCompact ? 12 : 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AvatarStack(imageUrls: widget.task.assignees),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.task.dueDate != null) ...[
                            Icon(LucideIcons.calendar, size: 14, color: theme.textTheme.bodyMedium?.color),
                            const Gap(4),
                            Text(
                              DateFormat('MMM d').format(widget.task.dueDate!),
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                            ),
                            const Gap(12),
                          ],
                          if (widget.task.commentsCount > 0) ...[
                            Icon(LucideIcons.messageSquare, size: 14, color: theme.textTheme.bodyMedium?.color),
                            const Gap(4),
                            Text(
                              '${widget.task.commentsCount}',
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                            ),
                            const Gap(12),
                          ],
                          if (widget.task.attachmentsCount > 0) ...[
                            Icon(LucideIcons.paperclip, size: 14, color: theme.textTheme.bodyMedium?.color),
                            const Gap(4),
                            Text(
                              '${widget.task.attachmentsCount}',
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(
                        LucideIcons.moreHorizontal,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                      onPressed: () {
                        final RenderBox renderBox = context.findRenderObject() as RenderBox;
                        final position = renderBox.localToGlobal(Offset(0, renderBox.size.height));
                        _showContextMenu(position);
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
