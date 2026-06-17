import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../controllers/canvas_controller.dart';
import '../controllers/viewport_controller.dart';
import '../../../theme/app_colors.dart';
import 'edge_painter.dart';
import '../../../widgets/custom_context_menu.dart';
import 'node_widget.dart';
import 'selection_overlay.dart';
import '../models/canvas_node.dart';
import '../models/canvas_edge.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfiniteCanvas extends StatefulWidget {
  final CanvasController canvasController;
  final ViewportController viewportController;

  const InfiniteCanvas({
    super.key,
    required this.canvasController,
    required this.viewportController,
  });

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  final GlobalKey _canvasKey = GlobalKey();

  Offset? _panStartScreen;
  Offset? _selectionStartScreen;
  Rect? _selectionRectScreen;

  bool _panning = false;
  bool _selecting = false;
  bool _isSecondaryDown = false;
  double _totalPanDistance = 0;

  OverlayEntry? _contextMenuEntry;

  Offset _getSideOffset(CanvasNode node, String? side) {
    if (side == 'top') return node.position + Offset(node.size.width / 2, 0);
    if (side == 'bottom') return node.position + Offset(node.size.width / 2, node.size.height);
    if (side == 'left') return node.position + Offset(0, node.size.height / 2);
    return node.position + Offset(node.size.width, node.size.height / 2); // right
  }

  Offset _toLocal(Offset globalPosition) {
    final box =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;

    return box.globalToLocal(globalPosition);
  }

  @override
  void initState() {
    super.initState();
    widget.canvasController.addListener(_refresh);
    widget.viewportController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.canvasController.removeListener(_refresh);
    widget.viewportController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _startPan(PointerDownEvent event) {
    _panning = true;
    _panStartScreen = _toLocal(event.position);
    _totalPanDistance = 0;
    _isSecondaryDown = event.buttons == kSecondaryMouseButton;
  }

  void _updatePan(PointerMoveEvent event) {
    if (!_panning || _panStartScreen == null) return;

    final current = _toLocal(event.position);
    final delta = current - _panStartScreen!;
    _totalPanDistance += delta.distance;

    widget.viewportController.pan(delta);
    _panStartScreen = current;
  }

  void _endPan() {
    _panning = false;
    _panStartScreen = null;
  }

  void _startSelection(PointerDownEvent event) {
    _selecting = true;
    _selectionStartScreen = _toLocal(event.position);
    _selectionRectScreen = null;
  }

  void _updateSelection(PointerMoveEvent event) {
    if (!_selecting || _selectionStartScreen == null) return;

    final current = _toLocal(event.position);

    setState(() {
      _selectionRectScreen = Rect.fromPoints(
        _selectionStartScreen!,
        current,
      );
    });

    // Update selection live
    if (_selectionRectScreen != null) {
      final topLeftWorld = widget.viewportController.screenToWorld(
        _selectionRectScreen!.topLeft,
      );

      final bottomRightWorld = widget.viewportController.screenToWorld(
        _selectionRectScreen!.bottomRight,
      );

      widget.canvasController.selectNodesInRect(
        Rect.fromPoints(topLeftWorld, bottomRightWorld),
      );
    }
  }

  void _endSelection() {
    if (_selectionRectScreen != null) {
      final topLeftWorld = widget.viewportController.screenToWorld(
        _selectionRectScreen!.topLeft,
      );

      final bottomRightWorld = widget.viewportController.screenToWorld(
        _selectionRectScreen!.bottomRight,
      );

      widget.canvasController.selectNodesInRect(
        Rect.fromPoints(topLeftWorld, bottomRightWorld),
      );
    }

    _selecting = false;
    _selectionStartScreen = null;
    _selectionRectScreen = null;

    setState(() {});
  }

  void _handleScrollZoom(PointerScrollEvent event) {
    _hideMenu();
    final local = _toLocal(event.position);

    if (event.scrollDelta.dy < 0) {
      widget.viewportController.zoomIn(local);
    } else {
      widget.viewportController.zoomOut(local);
    }
  }

  void _showMenu(Offset screenPosition) {
    final worldPos = widget.viewportController.screenToWorld(screenPosition);
    final selectedIds = widget.canvasController.selectedNodeIds;
    
    CanvasNode? clickedNode;
    CanvasEdge? clickedEdge;

    for (final node in widget.canvasController.document.nodes) {
      final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);
      if (rect.contains(worldPos)) {
        clickedNode = node;
        break;
      }
    }

    if (clickedNode == null) {
      for (final edge in widget.canvasController.document.edges) {
        final fromNode = widget.canvasController.document.getNodeById(edge.fromNodeId);
        final toNode = widget.canvasController.document.getNodeById(edge.toNodeId);
        if (fromNode == null || toNode == null) continue;
        
        final startWorld = _getSideOffset(fromNode, edge.fromSide ?? 'right');
        final endWorld = _getSideOffset(toNode, edge.toSide ?? 'left');
        
        if (EdgePainter.hitTestEdge(worldPos, startWorld, endWorld, edge.fromSide ?? 'right', edge.toSide ?? 'left', tolerance: 20.0 / widget.viewportController.scale)) {
          clickedEdge = edge;
          break;
        }
      }
    }

    if (clickedNode != null && clickedNode.id == widget.canvasController.editingNodeId) {
      return; // Do not show canvas menu if node is being edited
    }

    if (clickedNode != null && !widget.canvasController.selectedNodeIds.contains(clickedNode.id)) {
      widget.canvasController.selectNode(clickedNode.id);
    } else if (clickedEdge != null && !widget.canvasController.selectedEdgeIds.contains(clickedEdge.id)) {
      widget.canvasController.selectEdge(clickedEdge.id);
    }

    final currentSelectedNodeIds = widget.canvasController.selectedNodeIds;
    final currentSelectedEdgeIds = widget.canvasController.selectedEdgeIds;
    final items = <CustomContextMenuItem>[];

    if (clickedNode == null && clickedEdge == null) {
      // Background click
      items.addAll([
        CustomContextMenuItem(
          icon: LucideIcons.square,
          label: 'Add Task',
          onTap: () {
            widget.canvasController.addNode(title: '', content: '', type: CanvasNodeType.task, position: worldPos);
          },
        ),
        CustomContextMenuItem(
          icon: LucideIcons.target,
          label: 'Add Goal',
          onTap: () {
            widget.canvasController.addNode(title: '', content: '', type: CanvasNodeType.goal, position: worldPos);
          },
        ),
        CustomContextMenuItem(
          icon: LucideIcons.type,
          label: 'Add Note',
          onTap: () {
            widget.canvasController.addNode(title: '', content: '', type: CanvasNodeType.note, position: worldPos);
          },
        ),
      ]);
    }

    if (clickedEdge != null && clickedNode == null) {
      items.add(CustomContextMenuItem(
        icon: LucideIcons.trash2,
        label: 'Unlink',
        isDestructive: true,
        onTap: () {
          widget.canvasController.deleteSelectedNodes();
        },
      ));
    }

    if (clickedNode != null) {
      items.add(CustomContextMenuItem(
        icon: LucideIcons.layers,
        label: 'Add Container',
        onTap: () {
          widget.canvasController.addContainerBehindSelected();
        },
      ));

      final selectedNodes = widget.canvasController.selectedNodes;
      final hasGroupedItems = selectedNodes.any((n) => n.type == CanvasNodeType.group || n.parentId != null);

      if (hasGroupedItems) {
        items.add(CustomContextMenuItem(
          icon: LucideIcons.ungroup,
          label: 'Ungroup',
          shortcut: 'Ctrl+Shift+G',
          onTap: () {
            for (final n in selectedNodes) {
              if (n.type == CanvasNodeType.group || n.parentId != null) {
                widget.canvasController.ungroupNodes(n.id);
              }
            }
          },
        ));
      } else if (currentSelectedNodeIds.length > 1) {
        items.add(CustomContextMenuItem(
          icon: LucideIcons.group,
          label: 'Group Selection',
          shortcut: 'Ctrl+G',
          onTap: () {
            widget.canvasController.logicallyGroupSelectedNodes();
          },
        ));
      }

      items.add(CustomContextMenuItem(
        icon: LucideIcons.copy,
        label: 'Duplicate',
        shortcut: 'Ctrl+D',
        onTap: () {
          widget.canvasController.duplicateSelectedNodes();
        },
      ));

      final hasConnections = widget.canvasController.document.edges.any((e) => 
        currentSelectedNodeIds.contains(e.fromNodeId) || currentSelectedNodeIds.contains(e.toNodeId)
      );

      if (hasConnections) {
        items.add(CustomContextMenuItem(
          icon: LucideIcons.link2Off,
          label: 'Disconnect',
          onTap: () {
            widget.canvasController.disconnectSelectedNodes();
          },
        ));
      }

      items.add(CustomContextMenuItem.divider());

      items.add(CustomContextMenuItem(
        icon: LucideIcons.trash2,
        label: 'Delete',
        shortcut: 'Del',
        isDestructive: true,
        onTap: () {
          widget.canvasController.deleteSelectedNodes();
        },
      ));

      // Add Toggle Title for single node selection
      if (currentSelectedNodeIds.length == 1) {
        final node = widget.canvasController.document.getNodeById(currentSelectedNodeIds.first);
        if (node != null) {
          items.add(CustomContextMenuItem(
            icon: (node.showTitle ?? true) ? LucideIcons.eyeOff : LucideIcons.eye,
            label: (node.showTitle ?? true) ? 'Hide Title' : 'Show Title',
            onTap: () {
              widget.canvasController.toggleTitleVisibility(node.id);
            },
          ));
        }
      }
    }

    if (items.isNotEmpty) {
      final renderBox = context.findRenderObject() as RenderBox;
      final globalPosition = renderBox.localToGlobal(screenPosition);

      showCustomContextMenu(
        context: context,
        position: globalPosition,
        items: items,
      );
    }
  }

  void _hideMenu() {
    if (_contextMenuEntry != null) {
      _contextMenuEntry?.remove();
      _contextMenuEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppColorsExtension>();

    return Listener(
      key: _canvasKey,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleScrollZoom(event);
        }
      },
      onPointerDown: (event) {
        _hideMenu();
        
        if (event.buttons == kSecondaryMouseButton || event.buttons == kMiddleMouseButton) {
          _startPan(event);
          return;
        }

        if (event.buttons == kPrimaryMouseButton) {
          FocusManager.instance.primaryFocus?.unfocus();
          final local = _toLocal(event.position);
          final worldPos = widget.viewportController.screenToWorld(local);
          
          bool hitNode = false;
          for (final n in widget.canvasController.document.nodes) {
            final rect = Rect.fromLTWH(n.position.dx, n.position.dy, n.size.width, n.size.height);
            if (rect.contains(worldPos)) {
              hitNode = true;
              break;
            }
          }

          if (hitNode) return;

          // Check if an edge was clicked
          bool hitEdge = false;
          for (final edge in widget.canvasController.document.edges) {
            final fromNode = widget.canvasController.document.getNodeById(edge.fromNodeId);
            final toNode = widget.canvasController.document.getNodeById(edge.toNodeId);
            if (fromNode == null || toNode == null) continue;
            
            final startWorld = _getSideOffset(fromNode, edge.fromSide ?? 'right');
            final endWorld = _getSideOffset(toNode, edge.toSide ?? 'left');
            
            if (EdgePainter.hitTestEdge(worldPos, startWorld, endWorld, edge.fromSide ?? 'right', edge.toSide ?? 'left', tolerance: 20.0 / widget.viewportController.scale)) {
              widget.canvasController.selectEdge(edge.id);
              final currentType = edge.type ?? 'solid';
              String nextType = 'dashed';
              if (currentType == 'solid') nextType = 'dashed';
              else if (currentType == 'dashed') nextType = 'arrow';
              else if (currentType == 'arrow') nextType = 'solid';
              widget.canvasController.updateEdgeType(edge.id, nextType);
              hitEdge = true;
              break;
            }
          }

          if (hitEdge) return;

          widget.canvasController.clearSelection();
          _startSelection(event);
        }
      },
      onPointerMove: (event) {
        final local = _toLocal(event.position);
        final worldPos = widget.viewportController.screenToWorld(local);

        if (widget.canvasController.connectingFromNodeId != null) {
          widget.canvasController.updateConnectionPreview(worldPos);
          return;
        }

        if (widget.canvasController.nodeInteractionActive) return;

        if (_panning) {
          _updatePan(event);
        } else if (_selecting) {
          _updateSelection(event);
        }
      },
      onPointerUp: (event) {
        if (widget.canvasController.connectingFromNodeId != null) {
          final local = _toLocal(event.position);
          final worldPos = widget.viewportController.screenToWorld(local);
          
          CanvasNode? nodeUnderMouse;
          for (final n in widget.canvasController.document.nodes) {
            final rect = Rect.fromLTWH(n.position.dx, n.position.dy, n.size.width, n.size.height);
            if (rect.contains(worldPos)) {
              nodeUnderMouse = n;
              break;
            }
          }

          if (nodeUnderMouse != null && nodeUnderMouse.id != widget.canvasController.connectingFromNodeId) {
             final rect = Rect.fromLTWH(nodeUnderMouse.position.dx, nodeUnderMouse.position.dy, nodeUnderMouse.size.width, nodeUnderMouse.size.height);
             final dTop = (worldPos.dy - rect.top).abs();
             final dBottom = (worldPos.dy - rect.bottom).abs();
             final dLeft = (worldPos.dx - rect.left).abs();
             final dRight = (worldPos.dx - rect.right).abs();
             
             final minD = [dTop, dBottom, dLeft, dRight].reduce((a, b) => a < b ? a : b);
             String toSide = 'left';
             if (minD == dTop) toSide = 'top';
             else if (minD == dBottom) toSide = 'bottom';
             else if (minD == dRight) toSide = 'right';

            widget.canvasController.completeConnection(nodeUnderMouse.id, toSide);
          } else {
            widget.canvasController.cancelConnection();
          }
          return;
        }

        widget.canvasController.endNodeInteraction();
        if (_panning) {
          if (_isSecondaryDown && _totalPanDistance < 5) {
            _showMenu(_toLocal(event.position));
          }
          _endPan();
        }
        _endSelection();
      },
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    viewportController: widget.viewportController,
                    color: palette?.calendarGrid ?? theme.dividerColor,
                  ),
                ),
              ),
              if (widget.canvasController.document.canvasWidth != null && widget.canvasController.document.canvasHeight != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CanvasBoundsPainter(
                      width: widget.canvasController.document.canvasWidth!,
                      height: widget.canvasController.document.canvasHeight!,
                      viewportController: widget.viewportController,
                      color: theme.cardColor,
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CanvasEdgesPainter(
                      canvasController: widget.canvasController,
                      viewportController: widget.viewportController,
                      getSideOffset: _getSideOffset,
                    ),
                  ),
                ),
              ),
              ...([
                ...widget.canvasController.document.nodes.where((n) => n.type == CanvasNodeType.group),
                ...widget.canvasController.document.nodes.where((n) => n.type != CanvasNodeType.group),
              ]).map(
                (node) => NodeWidget(
                  key: ValueKey(node.id),
                  node: node,
                  canvasController: widget.canvasController,
                  viewportController: widget.viewportController,
                  globalToLocal: _toLocal,
                ),
              ),
              CanvasSelectionOverlay(
                selectionRect: _selectionRectScreen,
              ),
              // Rulers
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 24,
                child: CustomPaint(
                  painter: _RulerPainter(
                    viewportController: widget.viewportController,
                    isHorizontal: true,
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                width: 24,
                child: CustomPaint(
                  painter: _RulerPainter(
                    viewportController: widget.viewportController,
                    isHorizontal: false,
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              // Ruler corner
              Positioned(
                top: 0,
                left: 0,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
                    border: Border(
                      right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
                    ),
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

class _RulerPainter extends CustomPainter {
  final ViewportController viewportController;
  final bool isHorizontal;
  final Color color;
  final Color backgroundColor;

  _RulerPainter({
    required this.viewportController,
    required this.isHorizontal,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = viewportController.scale;
    final offset = viewportController.offset;
    
    // Draw background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke;
    if (isHorizontal) {
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), borderPaint);
    } else {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), borderPaint);
    }

    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calculate grid intervals
    double interval = 100.0;
    if (scale < 0.5) interval = 200.0;
    if (scale < 0.2) interval = 500.0;
    if (scale > 2.0) interval = 50.0;
    if (scale > 5.0) interval = 10.0;

    final step = interval * scale;
    final startShift = (isHorizontal ? offset.dx : offset.dy) % step;

    for (double i = startShift; i < (isHorizontal ? size.width : size.height); i += step) {
      final worldPos = (isHorizontal ? (i - offset.dx) : (i - offset.dy)) / scale;
      
      // Major tick
      canvas.drawLine(
        isHorizontal ? Offset(i, size.height - 8) : Offset(size.width - 8, i),
        isHorizontal ? Offset(i, size.height) : Offset(size.width, i),
        tickPaint..color = color.withValues(alpha: 0.4),
      );

      // Label
      if (i > 24) { // Don't draw over the corner
        textPainter.text = TextSpan(
          text: worldPos.round().toString(),
          style: TextStyle(
            color: color.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.w300,
          ),
        );
        textPainter.layout();
        if (isHorizontal) {
          textPainter.paint(canvas, Offset(i + 4, 6));
        } else {
          // Vertical labels: aligned to right, rotated for consistency with major design tools
          canvas.save();
          canvas.translate(size.width - 12, i + 4);
          canvas.rotate(-1.5708);
          textPainter.paint(canvas, Offset(-textPainter.width, 0));
          canvas.restore();
        }
      }

      // Minor ticks
      final minorStep = step / 10;
      for (int j = 1; j < 10; j++) {
        final mi = i + (j * minorStep);
        if (mi > (isHorizontal ? size.width : size.height)) break;
        
        final isMid = j == 5;
        canvas.drawLine(
          isHorizontal ? Offset(mi, size.height - (isMid ? 5 : 3)) : Offset(size.width - (isMid ? 5 : 3), mi),
          isHorizontal ? Offset(mi, size.height) : Offset(size.width, mi),
          tickPaint..color = color.withValues(alpha: 0.15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CanvasEdgesPainter extends CustomPainter {
  final CanvasController canvasController;
  final ViewportController viewportController;
  final Offset Function(CanvasNode, String?) _getSideOffset;

  _CanvasEdgesPainter({
    required this.canvasController,
    required this.viewportController,
    required Offset Function(CanvasNode, String?) getSideOffset,
  }) : _getSideOffset = getSideOffset;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing edges
    for (final edge in canvasController.document.edges) {
      final fromNode =
          canvasController.document.getNodeById(edge.fromNodeId);

      final toNode =
          canvasController.document.getNodeById(edge.toNodeId);

      if (fromNode == null || toNode == null) continue;

      final startWorld = _getSideOffset(fromNode, edge.fromSide ?? 'right');
      final endWorld = _getSideOffset(toNode, edge.toSide ?? 'left');

      final start = viewportController.worldToScreen(startWorld);
      final end = viewportController.worldToScreen(endWorld);

      EdgePainter(
        start: start, 
        end: end,
        isSelected: canvasController.selectedEdgeIds.contains(edge.id) || 
                    canvasController.selectedNodeIds.contains(fromNode.id) || 
                    canvasController.selectedNodeIds.contains(toNode.id),
        startSide: edge.fromSide ?? 'right',
        endSide: edge.toSide ?? 'left',
        type: edge.type,
      ).paint(canvas, size);
    }

    // Draw connection preview
    if (canvasController.connectingFromNodeId != null &&
        canvasController.connectionPreviewWorldPosition != null) {
      final fromNode = canvasController.document
          .getNodeById(canvasController.connectingFromNodeId!);

      if (fromNode != null) {
        final startSide = canvasController.connectingFromSide ?? 'right';
        
        final startWorld = _getSideOffset(fromNode, startSide);
        final start = viewportController.worldToScreen(startWorld);

        final end = viewportController.worldToScreen(
          canvasController.connectionPreviewWorldPosition!,
        );

        EdgePainter(
          start: start,
          end: end,
          isPreview: true,
          startSide: startSide,
          endSide: 'left', // Doesn't matter too much for preview, but 'left' is a good default for the mouse end
        ).paint(canvas, size);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridPainter extends CustomPainter {
  final ViewportController viewportController;
  final Color color;

  _GridPainter({
    required this.viewportController,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = viewportController.scale;
    final spacing = 50.0 * scale;

    // Fade out grid if too small
    if (spacing < 10) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 
        (0.15 * (spacing / 50.0).clamp(0.0, 1.0)).clamp(0.05, 0.15),
      );

    final startX = viewportController.offset.dx % spacing;
    final startY = viewportController.offset.dy % spacing;

    for (double x = startX; x < size.width; x += spacing) {
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1 * scale.clamp(0.5, 1.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CanvasBoundsPainter extends CustomPainter {
  final double width;
  final double height;
  final ViewportController viewportController;
  final Color color;

  _CanvasBoundsPainter({
    required this.width,
    required this.height,
    required this.viewportController,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final start = viewportController.worldToScreen(Offset.zero);
    final end = viewportController.worldToScreen(Offset(width, height));
    final rect = Rect.fromPoints(start, end);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = color.computeLuminance() > 0.5 ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(rect.inflate(4), shadowPaint);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CanvasBoundsPainter oldDelegate) {
    return oldDelegate.width != width ||
           oldDelegate.height != height ||
           oldDelegate.color != color;
  }
}

