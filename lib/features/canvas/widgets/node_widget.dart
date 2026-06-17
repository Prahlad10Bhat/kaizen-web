import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task.dart';
import '../../../providers/boxclock_provider.dart';

import '../controllers/canvas_controller.dart';
import '../controllers/viewport_controller.dart';
import '../models/canvas_node.dart';
import 'audio_player_widget.dart';
import '../../../widgets/custom_context_menu.dart';

class NodeWidget extends StatefulWidget {
  final CanvasNode node;
  final CanvasController canvasController;
  final ViewportController viewportController;
  final Offset Function(Offset) globalToLocal;

  const NodeWidget({
    super.key,
    required this.node,
    required this.canvasController,
    required this.viewportController,
    required this.globalToLocal,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hovering = false;
  bool _dragging = false;
  bool _resizing = false;
  bool _isEditing = false;

  Offset? _dragStartMouseWorld;
  Offset? _dragStartNodeWorld;
  Size? _dragStartNodeSize;

  TextEditingController? _titleController;
  TextEditingController? _contentController;
  FocusNode? _titleFocusNode;
  FocusNode? _contentFocusNode;
  Offset? _lastDoubleTapDownPosition;
  bool _wasSelectedOnTapDown = false;

  TextEditingController get titleController =>
      _titleController ??= TextEditingController(text: widget.node.title);
  TextEditingController get contentController =>
      _contentController ??= TextEditingController(text: widget.node.content);
  
  FocusNode get titleFocusNode => _titleFocusNode ??= _createFocusNode();
  FocusNode get contentFocusNode => _contentFocusNode ??= _createFocusNode();

  FocusNode _createFocusNode() {
    final node = FocusNode();
    node.addListener(() {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        if (!titleFocusNode.hasFocus && !contentFocusNode.hasFocus && _isEditing) {
          _saveChanges();
        }
      });
    });

    return node;
  }

  Widget? _buildEntityLinkDropdown() {
    if (widget.node.type != CanvasNodeType.task && widget.node.type != CanvasNodeType.goal) {
      return null;
    }

    if (widget.node.title.isNotEmpty) {
      return null;
    }

    return Consumer(
      builder: (context, ref, _) {
        final theme = Theme.of(context);
        
        final child = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.node.type == CanvasNodeType.task 
                ? Colors.teal.withValues(alpha: 0.1) 
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.node.type == CanvasNodeType.task 
                  ? Colors.teal.withValues(alpha: 0.3) 
                  : Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.node.type == CanvasNodeType.task ? 'Choose task' : 'Choose goal',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.node.type == CanvasNodeType.task ? Colors.teal : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown, 
                size: 14, 
                color: widget.node.type == CanvasNodeType.task ? Colors.teal : Colors.orange
              ),
            ],
          ),
        );

        if (widget.node.type == CanvasNodeType.task) {
          final tasks = ref.watch(taskProvider);
          
          return PopupMenuButton<Task>(
            tooltip: 'Link to Task',
            offset: const Offset(0, 32),
            onSelected: (Task selectedTask) {
              widget.canvasController.updateNodeData(
                widget.node.id, 
                title: selectedTask.title,
                content: selectedTask.description ?? '',
              );
            },
            itemBuilder: (context) {
              if (tasks.isEmpty) {
                return [
                  const PopupMenuItem<Task>(
                    enabled: false,
                    child: Text('No tasks available'),
                  )
                ];
              }
              return tasks.map((t) => PopupMenuItem<Task>(
                value: t,
                child: SizedBox(
                  width: 200,
                  child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              )).toList();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: child,
            ),
          );
        } else {
          // Goal
          final boxClockData = ref.watch(boxClockProvider);
          final goals = boxClockData.goals;
          
          return PopupMenuButton<LifeGoal>(
            tooltip: 'Link to Goal',
            offset: const Offset(0, 32),
            onSelected: (LifeGoal selectedGoal) {
              widget.canvasController.updateNodeData(
                widget.node.id, 
                title: selectedGoal.name,
              );
            },
            itemBuilder: (context) {
              if (goals.isEmpty) {
                return [
                  const PopupMenuItem<LifeGoal>(
                    enabled: false,
                    child: Text('No goals available'),
                  )
                ];
              }
              return goals.map((g) => PopupMenuItem<LifeGoal>(
                value: g,
                child: SizedBox(
                  width: 200,
                  child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              )).toList();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: child,
            ),
          );
        }
      }
    );
  }

  Widget _buildTaskCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isHighlighted
        ? Colors.amber
        : isSelected
            ? Colors.teal
            : _hovering
                ? Colors.teal.withValues(alpha: 0.5)
                : Colors.teal.withValues(alpha: 0.3);

    return Container(
      width: widget.node.size.width,
      height: widget.node.size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF00332E), const Color(0xFF004D40)]
            : [const Color(0xFFE0F4F2), const Color(0xFFC2EBE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (isSelected || isHighlighted) ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: isDark ? 0.3 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.checkSquare, color: Colors.teal, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'TASK',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isDark ? Colors.teal : Colors.teal.shade800,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  if (_buildEntityLinkDropdown() != null) ...[
                    const SizedBox(height: 12),
                    _buildEntityLinkDropdown()!,
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.node.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF004D40),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ],
                ),
              ),
            ),
            if (isSelected || _hovering)
              Positioned(
                top: 12,
                right: 12,
                child: _buildInteractiveDots(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isHighlighted
        ? Colors.amber
        : isSelected
            ? Colors.orange
            : _hovering
                ? Colors.orange.withValues(alpha: 0.5)
                : Colors.orange.withValues(alpha: 0.3);

    return Container(
      width: widget.node.size.width,
      height: widget.node.size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF4A2B0F), const Color(0xFF6B3E14)]
            : [const Color(0xFFFFF4E6), const Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (isSelected || isHighlighted) ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: isDark ? 0.3 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.target, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GOAL',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isDark ? Colors.orange : Colors.orange.shade800,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          if (_buildEntityLinkDropdown() != null) ...[
                            const SizedBox(height: 8),
                            _buildEntityLinkDropdown()!,
                          ],
                          const SizedBox(height: 6),
                          Text(
                            widget.node.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF3E2723),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected || _hovering)
              Positioned(
                top: 12,
                right: 12,
                child: _buildInteractiveDots(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Pre-initialize
    titleController;
    contentController;
    titleFocusNode;
    contentFocusNode;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    widget.canvasController.addListener(_onCanvasChange);
  }

  void _onCanvasChange() {
    if (widget.canvasController.pulsingNodeId == widget.node.id && !_pulseController.isAnimating) {
      _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
    }
  }

  @override
  void didUpdateWidget(NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.title != widget.node.title && !_isEditing) {
      _titleController?.text = widget.node.title;
    }
    if (oldWidget.node.content != widget.node.content && !_isEditing) {
      _contentController?.text = widget.node.content;
    }
  }

  @override
  void dispose() {
    _titleController?.dispose();
    _contentController?.dispose();
    _titleFocusNode?.dispose();
    _contentFocusNode?.dispose();
    _pulseController.dispose();
    widget.canvasController.removeListener(_onCanvasChange);
    super.dispose();
  }

  void _saveChanges() {
    widget.canvasController.updateNodeData(
      widget.node.id,
      title: titleController.text,
      content: contentController.text,
    );
    setState(() => _isEditing = false);
    if (widget.canvasController.editingNodeId == widget.node.id) {
      widget.canvasController.setEditingNodeId(null);
    }
  }

  bool get isSelected {
    return widget.canvasController.selectedNodeIds.contains(widget.node.id);
  }

  bool get isHighlighted {
    return widget.canvasController.searchResults.contains(widget.node.id) &&
        widget.canvasController.searchResults.indexOf(widget.node.id) ==
            widget.canvasController.currentSearchIndex;
  }

  Offset _toCanvasLocal(Offset globalPosition) {
    return widget.globalToLocal(globalPosition);
  }

  void _showContextMenu(Offset globalPosition) {
    showCustomContextMenu(
      context: context,
      position: globalPosition,
      items: [
        CustomContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'Delete',
          shortcut: 'Del',
          isDestructive: true,
          onTap: () {
            widget.canvasController.deleteNode(widget.node.id);
          },
        ),
        CustomContextMenuItem(
          icon: LucideIcons.copy,
          label: 'Duplicate',
          shortcut: 'Ctrl+D',
          onTap: () {
            widget.canvasController.selectNode(widget.node.id, additive: false);
            widget.canvasController.duplicateSelectedNodes();
          },
        ),
        CustomContextMenuItem(
          icon: (widget.node.showTitle ?? true) ? LucideIcons.eyeOff : LucideIcons.eye,
          label: (widget.node.showTitle ?? true) ? 'Hide Title' : 'Show Title',
          onTap: () {
            widget.canvasController.toggleTitleVisibility(widget.node.id);
          },
        ),
      ],
    );
  }

  void _startDrag(Offset globalPosition) {
    if (_isEditing) return;
    widget.canvasController.pushHistory();
    widget.canvasController.startNodeInteraction();

    _dragging = true;

    final local = _toCanvasLocal(globalPosition);

    _dragStartMouseWorld =
        widget.viewportController.screenToWorld(local);

    _dragStartNodeWorld = widget.node.position;

    setState(() {});
  }

  void _updateDrag(Offset globalPosition) {
    if (!_dragging) return;
    if (_dragStartMouseWorld == null) return;
    if (_dragStartNodeWorld == null) return;

    final local = _toCanvasLocal(globalPosition);

    final currentMouseWorld =
        widget.viewportController.screenToWorld(local);

    final delta = currentMouseWorld - _dragStartMouseWorld!;

    widget.canvasController.moveNode(
      widget.node.id,
      _dragStartNodeWorld! + delta,
    );
  }

  void _endDrag() {
    widget.canvasController.endNodeInteraction();

    _dragging = false;
    _dragStartMouseWorld = null;
    _dragStartNodeWorld = null;

    setState(() {});
  }

  void _startResize(PointerDownEvent event) {
    widget.canvasController.pushHistory();
    widget.canvasController.startNodeInteraction();
    _resizing = true;
    final local = _toCanvasLocal(event.position);
    _dragStartMouseWorld = widget.viewportController.screenToWorld(local);
    _dragStartNodeSize = widget.node.size;
    setState(() {});
  }

  void _updateResize(PointerMoveEvent event) {
    if (!_resizing) return;
    if (_dragStartMouseWorld == null) return;
    if (_dragStartNodeSize == null) return;

    final local = _toCanvasLocal(event.position);
    final currentMouseWorld = widget.viewportController.screenToWorld(local);
    final delta = currentMouseWorld - _dragStartMouseWorld!;

    widget.canvasController.updateNodeSize(
      widget.node.id,
      Size(
        _dragStartNodeSize!.width + delta.dx,
        _dragStartNodeSize!.height + delta.dy,
      ),
    );
  }

  void _endResize() {
    widget.canvasController.endNodeInteraction();
    _resizing = false;
    _dragStartMouseWorld = null;
    _dragStartNodeSize = null;
    setState(() {});
  }

  void _handleTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    final additive = HardwareKeyboard.instance.isShiftPressed;
    
    // If we click a selected node without shift, don't clear selection yet 
    // to allow dragging multiple nodes.
    if (!additive && isSelected) return;

    widget.canvasController.selectNode(
      widget.node.id,
      additive: additive,
    );
  }

  void _handleDoubleTap() {
    setState(() {
      _isEditing = true;
      if (widget.node.showTitle == true && (_lastDoubleTapDownPosition?.dy ?? 0) <= 40) {
        titleFocusNode.requestFocus();
      } else {
        contentFocusNode.requestFocus();
      }
    });
    widget.canvasController.setEditingNodeId(widget.node.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenPosition =
        widget.viewportController.worldToScreen(widget.node.position);

    return Positioned(
      left: screenPosition.dx,
      top: screenPosition.dy,
      child: Transform.scale(
        scale: widget.viewportController.scale,
        alignment: Alignment.topLeft,
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _hovering = true;
            });
          },
          onExit: (_) {
            setState(() {
              _hovering = false;
            });
          },
          child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            onDoubleTapDown: (details) => _lastDoubleTapDownPosition = details.localPosition,
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                  onTapDown: (details) {
                    _wasSelectedOnTapDown = isSelected;
                    if (!_isEditing) _handleTap();
                  },
                  onTapUp: (details) {
                    if (!_isEditing && _wasSelectedOnTapDown && !HardwareKeyboard.instance.isShiftPressed) {
                      _lastDoubleTapDownPosition = details.localPosition;
                      _handleDoubleTap();
                    }
                  },
                  onPanStart: (details) {
                    if (!_isEditing) _handleTap();
                    _startDrag(details.globalPosition);
                  },
                  onPanUpdate: (details) {
                    _updateDrag(details.globalPosition);
                  },
                  onPanEnd: (_) => _endDrag(),
                  child: Listener(
                    onPointerDown: (event) {
                      // Handled by InfiniteCanvas centrally
                    },
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Stack(
                        children: [
                          if (widget.canvasController.pulsingNodeId == widget.node.id)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(widget.node.type == CanvasNodeType.group ? 24 : 14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (widget.node.accentColor ?? theme.primaryColor).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          _buildCard(),
                        ],
                      ),
                    ),
                  ),
                )),
                if (isSelected || _hovering) ...[
                  if (isSelected) _buildResizeHandle(),
                  _buildConnectionHandle(Alignment.topCenter),
                  _buildConnectionHandle(Alignment.bottomCenter),
                  _buildConnectionHandle(Alignment.centerLeft),
                  _buildConnectionHandle(Alignment.centerRight),
                ],
              ],
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildCard() {
    if (widget.node.type == CanvasNodeType.task) return _buildTaskCard();
    if (widget.node.type == CanvasNodeType.goal) return _buildGoalCard();

    final isGroup = widget.node.type == CanvasNodeType.group;
    final theme = Theme.of(context);
    final borderColor = isHighlighted
        ? Colors.amber
        : isSelected
            ? theme.colorScheme.primary
            : _hovering
                ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2)
                : theme.dividerColor.withValues(alpha: 0.12);

    return Container(
      width: widget.node.size.width,
      height: widget.node.size.height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGroup ? theme.colorScheme.primary.withValues(alpha: 0.03) : theme.cardColor,
        borderRadius: BorderRadius.circular(isGroup ? 24 : 14),
        border: Border.all(
          color: isGroup && widget.node.accentColor != null ? widget.node.accentColor! : (borderColor ?? Colors.grey),
          width: (isSelected || isHighlighted) ? ((widget.node.borderWidth ?? 1.0) + 1.0) : (isGroup ? (widget.node.borderWidth ?? 1.0) : 0.5),
          style: isGroup ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: isGroup ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: widget.node.showTitle == true
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, right: 24.0),
                        child: _buildHeaderTitle(),
                      )
                    : const SizedBox.shrink(),
              ),
              if (widget.node.type != CanvasNodeType.group)
                Expanded(
                  child: widget.node.type == CanvasNodeType.image
                      ? _buildImageContent()
                      : widget.node.type == CanvasNodeType.audio
                          ? _buildAudioContent()
                          : _isEditing
                              ? _buildEditor()
                              : _buildContent(),
                ),
            ],
          ),
          if (isSelected || _hovering)
            Positioned(
              top: 0,
              right: 0,
              child: _buildInteractiveDots(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildTypeDot(),
        const SizedBox(width: 10),
        Expanded(
          child: _isEditing
              ? TextField(
                  controller: titleController,
                  focusNode: titleFocusNode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  widget.node.title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInteractiveDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.node.type == CanvasNodeType.group) ...[
          _buildColorDot(),
          _buildThicknessDot(),
        ],
        _buildVisibilityDot(),
      ],
    );
  }

  Widget _buildColorDot() {
    final theme = Theme.of(context);
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTap: () {
         final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.grey];
         final currentIdx = colors.indexWhere((c) => c.value == widget.node.accentColor?.value);
         final nextColor = colors[(currentIdx + 1) % colors.length];
         widget.canvasController.updateNodeStyle(widget.node.id, accentColor: nextColor);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.node.accentColor ?? theme.colorScheme.primary,
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
        ),
      ),
    ));
  }

  Widget _buildThicknessDot() {
    final theme = Theme.of(context);
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTap: () {
         final widths = <double>[1.0, 2.0, 4.0, 8.0, 0.0];
         final currentIdx = widths.indexOf(widget.node.borderWidth ?? 1.0);
         final nextWidth = widths[(currentIdx + 1) % widths.length];
         widget.canvasController.updateNodeStyle(widget.node.id, borderWidth: nextWidth);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.iconTheme.color?.withValues(alpha: 0.5) ?? Colors.black54, 
              width: (widget.node.borderWidth ?? 1.0) == 0.0 ? 0.5 : (widget.node.borderWidth ?? 1.0).clamp(1.0, 4.0),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildVisibilityDot() {
    final theme = Theme.of(context);
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTap: () => widget.canvasController.toggleTitleVisibility(widget.node.id),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            widget.node.showTitle == true ? LucideIcons.eye : LucideIcons.eyeOff,
            size: 14,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    ));
  }

  Widget _buildImageContent() {
    final file = File(widget.node.content);
    if (!file.existsSync()) {
      return const Center(
        child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildAudioContent() {
    final theme = Theme.of(context);
    String label = widget.node.title;
    if (label.isEmpty || label == 'Audio Note') {
      label = widget.node.content.split('\\').last.split('/').last;
    }

    return Center(
      child: CanvasAudioPlayer(
        source: widget.node.content,
        label: label,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final isEmpty = widget.node.content.trim().isEmpty;
    
    return Text(
      isEmpty ? 'Type something..' : widget.node.content,
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: isEmpty ? 0.35 : 0.72),
        fontSize: 14,
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _buildEditor() {
    final theme = Theme.of(context);
    return TextField(
      controller: contentController,
      focusNode: contentFocusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: 'Type something..',
      ),
      autofocus: false, // Title gets focus first
    );
  }

  Widget _buildTypeDot() {
    final theme = Theme.of(context);
    Color color;

    switch (widget.node.type) {
      case CanvasNodeType.note:
        color = theme.colorScheme.primary;
        break;
      case CanvasNodeType.text:
        color = Colors.green;
        break;
      case CanvasNodeType.image:
        color = Colors.purple;
        break;
      case CanvasNodeType.group:
        color = Colors.orange;
        break;
      case CanvasNodeType.audio:
        color = Colors.pink;
        break;
      case CanvasNodeType.task:
        color = Colors.blue;
        break;
      case CanvasNodeType.goal:
        color = Colors.orange;
        break;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildConnectionHandle(Alignment alignment) {
    final theme = Theme.of(context);
    final handleSize = 24.0; // Total touch area
    
    double? left, top, right, bottom;
    
    if (alignment == Alignment.topCenter) {
      top = -handleSize / 2;
      left = widget.node.size.width / 2 - handleSize / 2;
    } else if (alignment == Alignment.bottomCenter) {
      bottom = -handleSize / 2;
      left = widget.node.size.width / 2 - handleSize / 2;
    } else if (alignment == Alignment.centerLeft) {
      left = -handleSize / 2;
      top = widget.node.size.height / 2 - handleSize / 2;
    } else if (alignment == Alignment.centerRight) {
      right = -handleSize / 2;
      top = widget.node.size.height / 2 - handleSize / 2;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isHandleHovered = false;
          return MouseRegion(
            onEnter: (_) => setState(() => isHandleHovered = true),
            onExit: (_) => setState(() => isHandleHovered = false),
            cursor: SystemMouseCursors.precise,
            child: Listener(
              onPointerDown: (event) {
                if (event.buttons != kPrimaryMouseButton) return;
                String side = 'right';
                if (alignment == Alignment.topCenter) side = 'top';
                else if (alignment == Alignment.bottomCenter) side = 'bottom';
                else if (alignment == Alignment.centerLeft) side = 'left';
                widget.canvasController.startConnection(widget.node.id, side);
              },
              child: Container(
                width: handleSize,
                height: handleSize,
                color: Colors.transparent, // Expand hit area
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: isHandleHovered ? 20 : 14,
                    height: isHandleHovered ? 20 : 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: isHandleHovered ? 0.3 : 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: isHandleHovered ? 0.8 : 0.5),
                        width: 1.5,
                      ),
                      boxShadow: isHandleHovered ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: isHandleHovered ? 14 : 10,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Listener(
        onPointerDown: _startResize,
        onPointerMove: _updateResize,
        onPointerUp: (_) => _endResize(),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: Container(
            width: 20,
            height: 20,
            color: Colors.transparent,
            child: CustomPaint(
              painter: _ResizeHandlePainter(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeHandlePainter extends CustomPainter {
  final Color color;

  _ResizeHandlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw three diagonal lines for the resize grip
    canvas.drawLine(
      Offset(size.width - 4, size.height - 12),
      Offset(size.width - 12, size.height - 4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 4, size.height - 8),
      Offset(size.width - 8, size.height - 4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4),
      Offset(size.width - 4, size.height - 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
