import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../models/task.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/task_provider.dart';
import 'task_card.dart';
import '../../../widgets/universal_task_dialog.dart';

class BoardColumn extends ConsumerStatefulWidget {
  final String title;
  final TaskStatus status;
  final double? maxHeight;
  final List<Task>? tasks;
  final bool isCompact;

  const BoardColumn({
    super.key,
    required this.title,
    required this.status,
    this.maxHeight,
    this.tasks,
    this.isCompact = false,
  });

  @override
  ConsumerState<BoardColumn> createState() => _BoardColumnState();
}
class _BoardColumnState extends ConsumerState<BoardColumn> {
  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks ?? ref.watch(taskProvider).where((t) => t.status == widget.status).toList();
    final theme = Theme.of(context);

    return Container(
      width: 320,
      height: widget.maxHeight,
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, tasks.length),
          const Gap(16),
          Expanded(
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                ref.read(taskProvider.notifier).updateTaskStatus(details.data, widget.status);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                final color = _getStatusColor(widget.status, theme);
                
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isHovering ? theme.primaryColor.withValues(alpha: 0.04) : theme.primaryColor.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: tasks.length < 4 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(minHeight: tasks.length < 4 ? 0 : (widget.maxHeight ?? 500)),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                        child: Column(
                          children: [
                            if (tasks.isEmpty && !isHovering)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 100),
                                  child: Column(
                                    children: [
                                      Icon(LucideIcons.layers, size: 32, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2)),
                                      const Gap(12),
                                      Text('No tasks yet', style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            for (int i = 0; i < tasks.length; i++) ...[
                              _DraggableTaskCard(task: tasks[i], isCompact: widget.isCompact),
                              if (i < tasks.length - 1) const Gap(12),
                            ],
                            if (isHovering) ...[
                              const Gap(12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.status, theme);
    
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(8),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TaskStatus status, ThemeData theme) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blueAccent;
      case TaskStatus.inProgress:
        return Colors.orangeAccent;
      case TaskStatus.done:
        return Colors.greenAccent;
    }
  }
}


class _DraggableTaskCard extends ConsumerStatefulWidget {
  final Task task;
  final bool isCompact;

  const _DraggableTaskCard({required this.task, this.isCompact = false});

  @override
  ConsumerState<_DraggableTaskCard> createState() => _DraggableTaskCardState();
}

class _DraggableTaskCardState extends ConsumerState<_DraggableTaskCard> {
  bool _isPressed = false;
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != widget.task.id,
      onAcceptWithDetails: (details) {
        ref.read(taskProvider.notifier).updateTaskStatus(details.data, widget.task.status);
        setState(() => _isDragHovering = false);
      },
      onMove: (_) => setState(() => _isDragHovering = true),
      onLeave: (_) => setState(() => _isDragHovering = false),
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _isDragHovering 
                  ? _buildDropIndicator(context, widget.task.status)
                  : const SizedBox.shrink(),
            ),
            MouseRegion(
              cursor: _isPressed ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
              child: Listener(
                onPointerDown: (_) => setState(() => _isPressed = true),
                onPointerUp: (_) => setState(() => _isPressed = false),
                onPointerCancel: (_) => setState(() => _isPressed = false),
                child: Draggable<String>(
                  data: widget.task.id,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 320,
                      child: Opacity(
                        opacity: 0.8,
                        child: TaskCardWidget(task: widget.task, isCompact: widget.isCompact),
                      ),
                    ),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  child: TaskCardWidget(task: widget.task, isCompact: widget.isCompact),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropIndicator(BuildContext context, TaskStatus status) {
    final theme = Theme.of(context);
    final color = _getStatusColor(status, theme);
    return Container(
      height: 3,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status, ThemeData theme) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blueAccent;
      case TaskStatus.inProgress:
        return Colors.orangeAccent;
      case TaskStatus.done:
        return Colors.greenAccent;
    }
  }
}
