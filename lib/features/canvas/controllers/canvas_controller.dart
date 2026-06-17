import 'dart:math';
import 'package:flutter/material.dart';

import '../models/canvas_document.dart';
import '../models/canvas_edge.dart';
import '../models/canvas_node.dart';
import 'history_controller.dart';
import '../../../services/canvas_service.dart';

class CanvasController extends ChangeNotifier {
  CanvasDocument _document;

  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedEdgeIds = {};
  final Random _random = Random();
  final HistoryController history = HistoryController();

  String? _connectingFromNodeId;
  Offset? _connectionPreviewWorldPosition;

  bool _nodeInteractionActive = false;

  String _searchQuery = '';
  List<String> _searchResults = [];
  int _currentSearchIndex = -1;
  bool _isSearchOpen = false;
  String? _pulsingNodeId;
  String? _editingNodeId;

  CanvasController({
    required CanvasDocument document,
  }) : _document = document;

  CanvasDocument get document => _document;

  Set<String> get selectedNodeIds => _selectedNodeIds;
  Set<String> get selectedEdgeIds => _selectedEdgeIds;

  String? get connectingFromNodeId => _connectingFromNodeId;

  Offset? get connectionPreviewWorldPosition =>
      _connectionPreviewWorldPosition;

  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;

  bool get nodeInteractionActive => _nodeInteractionActive;

  String get searchQuery => _searchQuery;
  List<String> get searchResults => _searchResults;
  int get currentSearchIndex => _currentSearchIndex;
  bool get isSearchOpen => _isSearchOpen;
  String? get pulsingNodeId => _pulsingNodeId;
  String? get editingNodeId => _editingNodeId;

  List<CanvasNode> get selectedNodes {
    return _document.nodes
        .where((node) => _selectedNodeIds.contains(node.id))
        .toList();
  }

  void setSearchOpen(bool open) {
    _isSearchOpen = open;
    if (!open) {
      _searchQuery = '';
      _searchResults = [];
      _currentSearchIndex = -1;
    }
    notifyListeners();
  }

  void setEditingNodeId(String? nodeId) {
    _editingNodeId = nodeId;
    // We don't necessarily need to notifyListeners just for this, 
    // but it's safe to do so.
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      _currentSearchIndex = -1;
    } else {
      final q = query.toLowerCase();
      _searchResults = _document.nodes
          .where((node) =>
              node.title.toLowerCase().contains(q) ||
              node.content.toLowerCase().contains(q))
          .map((node) => node.id)
          .toList();
      _currentSearchIndex = _searchResults.isNotEmpty ? 0 : -1;
    }
    notifyListeners();
  }

  void nextSearchIndex() {
    if (_searchResults.isEmpty) return;
    _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    notifyListeners();
  }

  void previousSearchIndex() {
    if (_searchResults.isEmpty) return;
    _currentSearchIndex =
        (_currentSearchIndex - 1 + _searchResults.length) %
            _searchResults.length;
    notifyListeners();
  }

  void startNodeInteraction() {
    _nodeInteractionActive = true;
  }

  void endNodeInteraction() {
    _nodeInteractionActive = false;
    _save();
  }

  void setDocument(CanvasDocument document) {
    _document = document;
    history.clear();
    clearSelection();
    _save();
    notifyListeners();
  }

  void pushHistory() {
    history.push(_document);
  }

  Offset _findNonOverlappingPosition(Offset targetPosition, Size size) {
    Offset currentPosition = targetPosition;
    bool hasOverlap = true;
    int attempts = 0;
    const maxAttempts = 50; // Safety cap

    while (hasOverlap && attempts < maxAttempts) {
      hasOverlap = false;
      final currentRect = Rect.fromLTWH(
        currentPosition.dx,
        currentPosition.dy,
        size.width,
        size.height,
      );

      for (final node in _document.nodes) {
        final nodeRect = Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          node.size.width,
          node.size.height,
        );

        if (currentRect.overlaps(nodeRect)) {
          // If they overlap, shift the new node slightly down and right
          currentPosition = currentPosition + const Offset(30, 30);
          hasOverlap = true;
          attempts++;
          break;
        }
      }
    }
    return currentPosition;
  }

  void _save() {
    try {
      CanvasService.saveProject(_document);
    } catch (e) {
      debugPrint('Error saving project: $e');
    }
  }

  void saveViewportState(Offset offset, double scale) {
    _document = _document.copyWith(
      viewportOffsetDx: offset.dx,
      viewportOffsetDy: offset.dy,
      viewportScale: scale,
    );
    _save();
  }

  void addNode({
    required String title,
    required String content,
    required CanvasNodeType type,
    required Offset position,
    Size? size,
  }) {
    history.push(_document);

    final now = DateTime.now();
    final nodeSize = size ?? const Size(280, 180);
    final finalPosition = _findNonOverlappingPosition(position, nodeSize);

    final node = CanvasNode(
      id: 'node_${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      type: type,
      position: finalPosition,
      size: nodeSize,
      createdAt: now,
      updatedAt: now,
    );

    _document = _document.copyWith(
      nodes: [..._document.nodes, node],
      updatedAt: now,
    );

    _selectedNodeIds
      ..clear()
      ..add(node.id);

    _save();
    notifyListeners();
  }

  void moveNode(String nodeId, Offset newPosition) {
    final now = DateTime.now();
    final node = _document.nodes.firstWhere((n) => n.id == nodeId);
    final delta = newPosition - node.position;

    // If the node is a group, move its children too
    final isGroup = node.type == CanvasNodeType.group;
    final childrenIds = isGroup 
        ? _document.nodes.where((n) => n.parentId == nodeId).map((n) => n.id).toSet()
        : <String>{};

    // If the node is selected, move all selected nodes by the same delta
    if (_selectedNodeIds.contains(nodeId) && _selectedNodeIds.length > 1) {
      final updatedNodes = _document.nodes.map((n) {
        if (!_selectedNodeIds.contains(n.id) && !childrenIds.contains(n.id)) return n;
        return n.copyWith(
          position: n.position + delta,
          updatedAt: now,
        );
      }).toList();

      _document = _document.copyWith(
        nodes: updatedNodes,
        updatedAt: now,
      );
    } else {
      // Move only the target node and its children (if it's a group)
      final updatedNodes = _document.nodes.map((n) {
        if (n.id != nodeId && !childrenIds.contains(n.id)) return n;
        return n.copyWith(
          position: n.position + (n.id == nodeId ? (newPosition - n.position) : delta),
          updatedAt: now,
        );
      }).toList();

      _document = _document.copyWith(
        nodes: updatedNodes,
        updatedAt: now,
      );
    }

    notifyListeners();
  }

  void updateNodeStyle(String nodeId, {Color? accentColor, double? borderWidth}) {
    history.push(_document);
    final now = DateTime.now();
    _document = _document.copyWith(
      nodes: _document.nodes.map((n) {
        if (n.id == nodeId) {
          return n.copyWith(
            accentColor: accentColor ?? n.accentColor,
            borderWidth: borderWidth ?? n.borderWidth,
            updatedAt: now,
          );
        }
        return n;
      }).toList(),
      updatedAt: now,
    );
    notifyListeners();
    _save();
  }

  void updateNodeType(String nodeId, CanvasNodeType newType) {
    history.push(_document);
    final now = DateTime.now();
    _document = _document.copyWith(
      nodes: _document.nodes.map((n) {
        if (n.id == nodeId) {
          return n.copyWith(type: newType, updatedAt: now);
        }
        return n;
      }).toList(),
      updatedAt: now,
    );
    notifyListeners();
    _save();
  }

  void updateCanvasSize(double? width, double? height) {
    history.push(_document);
    final now = DateTime.now();
    _document = _document.copyWith(
      canvasWidth: width,
      canvasHeight: height,
      clearCanvasSize: width == null && height == null,
      updatedAt: now,
    );
    _save();
    notifyListeners();
  }

  void updateNodeSize(String nodeId, Size newSize) {
    final now = DateTime.now();
    
    // Size constraints (Obsidian-like caps)
    final clampedSize = Size(
      newSize.width.clamp(180.0, 1200.0),
      newSize.height.clamp(120.0, 1200.0),
    );

    final updatedNodes = _document.nodes.map((node) {
      if (node.id != nodeId) return node;
      return node.copyWith(
        size: clampedSize,
        updatedAt: now,
      );
    }).toList();

    _document = _document.copyWith(
      nodes: updatedNodes,
      updatedAt: now,
    );

    notifyListeners();
  }

  void updateNodeData(String nodeId, {String? title, String? content}) {
    final now = DateTime.now();
    
    final updatedNodes = _document.nodes.map((node) {
      if (node.id != nodeId) return node;
      return node.copyWith(
        title: title ?? node.title,
        content: content ?? node.content,
        updatedAt: now,
      );
    }).toList();

    _document = _document.copyWith(
      nodes: updatedNodes,
      updatedAt: now,
    );

    _save();
    notifyListeners();
  }

  void toggleTitleVisibility(String nodeId) {
    final now = DateTime.now();
    final updatedNodes = _document.nodes.map((node) {
      if (node.id != nodeId) return node;
      return node.copyWith(
        showTitle: !(node.showTitle ?? true),
        updatedAt: now,
      );
    }).toList();

    _document = _document.copyWith(
      nodes: updatedNodes,
      updatedAt: now,
    );

    _save();
    notifyListeners();
  }

  void selectNode(
    String nodeId, {
    bool additive = false,
  }) {
    if (!additive) {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    }

    final targetNode = _document.getNodeById(nodeId);
    if (targetNode == null) return;

    final isLogicalGroup = targetNode.parentId != null && targetNode.parentId!.startsWith('logical_group_');
    final isContainer = targetNode.type == CanvasNodeType.group;
    
    List<String> nodeIdsToSelect = [];
    if (isLogicalGroup) {
      nodeIdsToSelect = _document.nodes.where((n) => n.parentId == targetNode.parentId).map((n) => n.id).toList();
    } else if (isContainer) {
      nodeIdsToSelect = _document.nodes.where((n) => n.parentId == targetNode.id).map((n) => n.id).toList();
      nodeIdsToSelect.add(targetNode.id);
    } else {
      nodeIdsToSelect = [nodeId];
    }

    if (additive && _selectedNodeIds.containsAll(nodeIdsToSelect)) {
      // Toggle off
      _selectedNodeIds.removeAll(nodeIdsToSelect);
    } else {
      // Select all
      _selectedNodeIds.addAll(nodeIdsToSelect);
    }

    notifyListeners();
  }

  void selectEdge(String edgeId, {bool additive = false}) {
    if (!additive) {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    }
    
    if (additive && _selectedEdgeIds.contains(edgeId)) {
      _selectedEdgeIds.remove(edgeId);
    } else {
      _selectedEdgeIds.add(edgeId);
    }
    notifyListeners();
  }

  void updateEdgeType(String edgeId, String type) {
    history.push(_document);
    final now = DateTime.now();
    _document = _document.copyWith(
      edges: _document.edges.map((e) {
        if (e.id == edgeId) {
          return e.copyWith(type: type);
        }
        return e;
      }).toList(),
      updatedAt: now,
    );
    notifyListeners();
    _save();
  }

  void selectNodesInRect(Rect selectionRect) {
    _selectedNodeIds.clear();

    for (final node in _document.nodes) {
      final nodeRect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height,
      );

      if (selectionRect.overlaps(nodeRect)) {
        _selectedNodeIds.add(node.id);
      }
    }

    notifyListeners();
  }

  void clearSelection() {
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    notifyListeners();
  }

  void deleteNode(String nodeId) {
    history.push(_document);

    final remainingNodes = _document.nodes
        .where((node) => node.id != nodeId)
        .toList();

    final remainingEdges = _document.edges.where((edge) {
      return edge.fromNodeId != nodeId && edge.toNodeId != nodeId;
    }).toList();

    _document = _document.copyWith(
      nodes: remainingNodes,
      edges: remainingEdges,
      updatedAt: DateTime.now(),
    );

    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    }

    _save();
    notifyListeners();
  }

  void deleteSelectedNodes() {
    if (_selectedNodeIds.isEmpty && _selectedEdgeIds.isEmpty) return;

    history.push(_document);

    final remainingNodes = _document.nodes
        .where((node) => !_selectedNodeIds.contains(node.id))
        .toList();

    final remainingEdges = _document.edges.where((edge) {
      if (_selectedEdgeIds.contains(edge.id)) return false;
      return !_selectedNodeIds.contains(edge.fromNodeId) &&
          !_selectedNodeIds.contains(edge.toNodeId);
    }).toList();

    _document = _document.copyWith(
      nodes: remainingNodes,
      edges: remainingEdges,
      updatedAt: DateTime.now(),
    );

    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();

    _save();
    notifyListeners();
  }

  void duplicateSelectedNodes() {
    if (_selectedNodeIds.isEmpty) return;

    history.push(_document);

    final now = DateTime.now();
    final newNodes = [..._document.nodes];

    for (final node in selectedNodes) {
      final duplicated = node.copyWith(
        id: 'node_${now.microsecondsSinceEpoch}_${_random.nextInt(9999)}',
        title: '${node.title} Copy',
        position: node.position + const Offset(40, 40),
        createdAt: now,
        updatedAt: now,
      );

      newNodes.add(duplicated);
    }

    _document = _document.copyWith(
      nodes: newNodes,
      updatedAt: now,
    );

    _save();
    notifyListeners();
  }

  void addConnection(String fromId, String toId) {
    if (fromId == toId) return;
    
    // Check if edge already exists
    final exists = _document.edges.any((e) => 
      (e.fromNodeId == fromId && e.toNodeId == toId) ||
      (e.fromNodeId == toId && e.toNodeId == fromId)
    );
    if (exists) return;

    history.push(_document);
    final now = DateTime.now();
    final edge = CanvasEdge(
      id: 'edge_${now.microsecondsSinceEpoch}',
      fromNodeId: fromId,
      toNodeId: toId,
    );

    _document = _document.copyWith(
      edges: [..._document.edges, edge],
      updatedAt: now,
    );
    
    _save();
    notifyListeners();
  }

  List<String> findNodesByTitle(String title) {
    final lowerTitle = title.toLowerCase().trim();
    final matches = _document.nodes
        .where((node) => node.title.toLowerCase().contains(lowerTitle))
        .map((node) => node.id)
        .toList();
    
    _searchResults = matches;
    
    if (_searchResults.isNotEmpty) {
      _isSearchOpen = true;
      _currentSearchIndex = 0;
    } else {
      _isSearchOpen = false;
      _currentSearchIndex = -1;
    }
    notifyListeners();
    return matches;
  }

  void triggerNodePulse(String nodeId) {
    _pulsingNodeId = nodeId;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_pulsingNodeId == nodeId) {
        _pulsingNodeId = null;
        notifyListeners();
      }
    });
  }

  String? _connectingFromSide;
  String? get connectingFromSide => _connectingFromSide;

  void startConnection(String fromId, String fromSide) {
    _connectingFromNodeId = fromId;
    _connectingFromSide = fromSide;
    _connectionPreviewWorldPosition = null;
    notifyListeners();
  }

  void updateConnectionPreview(Offset worldPosition) {
    _connectionPreviewWorldPosition = worldPosition;
    notifyListeners();
  }

  void completeConnection(String targetNodeId, String toSide) {
    if (_connectingFromNodeId == null) return;
    if (_connectingFromNodeId == targetNodeId) {
      cancelConnection();
      return;
    }

    history.push(_document);

    final now = DateTime.now();

    final existingEdges = _document.edges.where((e) => 
      (e.fromNodeId == _connectingFromNodeId && e.toNodeId == targetNodeId) ||
      (e.fromNodeId == targetNodeId && e.toNodeId == _connectingFromNodeId)
    ).toList();
    
    List<CanvasEdge> newEdges = _document.edges.where((e) => 
      !((e.fromNodeId == _connectingFromNodeId && e.toNodeId == targetNodeId) ||
        (e.fromNodeId == targetNodeId && e.toNodeId == _connectingFromNodeId))
    ).toList();

    final edge = CanvasEdge(
      id: 'edge_${now.microsecondsSinceEpoch}',
      fromNodeId: _connectingFromNodeId!,
      toNodeId: targetNodeId,
      fromSide: _connectingFromSide,
      toSide: toSide,
    );
    newEdges.add(edge);

    _document = _document.copyWith(
      edges: newEdges,
      updatedAt: now,
    );

    cancelConnection();

    _save();
    notifyListeners();
  }

  void disconnectSelectedNodes() {
    if (_selectedNodeIds.isEmpty) return;

    history.push(_document);
    final now = DateTime.now();

    final newEdges = _document.edges.where((e) => 
      !_selectedNodeIds.contains(e.fromNodeId) && !_selectedNodeIds.contains(e.toNodeId)
    ).toList();

    if (newEdges.length == _document.edges.length) return; // Nothing disconnected

    _document = _document.copyWith(
      edges: newEdges,
      updatedAt: now,
    );

    _save();
    notifyListeners();
  }

  void addContainerBehindSelected() {
    if (_selectedNodeIds.isEmpty) return;

    history.push(_document);
    final now = DateTime.now();
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    final selected = selectedNodes;
    for (final node in selected) {
      minX = min(minX, node.position.dx);
      minY = min(minY, node.position.dy);
      maxX = max(maxX, node.position.dx + node.size.width);
      maxY = max(maxY, node.position.dy + node.size.height);
    }

    const padding = 40.0;
    final containerId = 'container_${now.microsecondsSinceEpoch}';
    
    final containerNode = CanvasNode(
      id: containerId,
      title: 'Container',
      content: '',
      type: CanvasNodeType.group, // Reusing 'group' type as visual container
      position: Offset(minX - padding, minY - padding),
      size: Size(maxX - minX + padding * 2, maxY - minY + padding * 2),
      createdAt: now,
      updatedAt: now,
    );

    final updatedNodes = _document.nodes.map((n) {
      if (_selectedNodeIds.contains(n.id)) {
        return n.copyWith(parentId: containerId, updatedAt: now);
      }
      return n;
    }).toList();
    updatedNodes.add(containerNode);

    _document = _document.copyWith(
      nodes: updatedNodes,
      updatedAt: now,
    );

    _selectedNodeIds.clear();
    _selectedNodeIds.add(containerId);
    
    _save();
    notifyListeners();
  }

  void logicallyGroupSelectedNodes() {
    if (_selectedNodeIds.length <= 1) return;

    history.push(_document);
    final now = DateTime.now();
    final groupId = 'logical_group_${now.microsecondsSinceEpoch}';

    final updatedNodes = _document.nodes.map((node) {
      if (_selectedNodeIds.contains(node.id)) {
        return node.copyWith(parentId: groupId, updatedAt: now);
      }
      return node;
    }).toList();

    _document = _document.copyWith(
      nodes: updatedNodes,
      updatedAt: now,
    );

    // Keep selection but now they act as a group
    _save();
    notifyListeners();
  }

  void ungroupNodes(String targetId) {
    history.push(_document);
    final now = DateTime.now();

    // Find the node to check if it's a visual container or part of a logical group
    final node = _document.getNodeById(targetId);
    if (node == null) return;

    List<CanvasNode> updatedNodes;

    if (node.type == CanvasNodeType.group) {
      // It's a visual container (which previously grouped things via parentId). 
      // If there are any nodes parented to this container, unparent them.
      updatedNodes = _document.nodes.map((n) {
        if (n.parentId == targetId) {
          return n.copyWith(clearParentId: true, updatedAt: now);
        }
        return n;
      }).toList();
      // Wait, should we also delete the container? Ungrouping a visual container usually means removing it.
      // But let's just delete the container node itself to match standard "ungroup" behavior.
      updatedNodes.removeWhere((n) => n.id == targetId);
    } else if (node.parentId != null) {
      // It's a logical group or a visual container. Unparent all nodes in this group.
      final groupId = node.parentId;
      updatedNodes = _document.nodes.map((n) {
        if (n.parentId == groupId) {
          return n.copyWith(clearParentId: true, updatedAt: now);
        }
        return n;
      }).toList();
      
      // If it was a visual container, we need to remove the container node as well
      updatedNodes.removeWhere((n) => n.id == groupId);
    } else {
      return;
    }

    _document = _document.copyWith(
      nodes: updatedNodes,
      updatedAt: now,
    );

    _selectedNodeIds.clear();
    _save();
    notifyListeners();
  }

  void cancelConnection() {
    _connectingFromNodeId = null;
    _connectionPreviewWorldPosition = null;
    notifyListeners();
  }

  void undo() {
    final previous = history.undo(_document);

    if (previous == null) return;

    _document = previous;
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    _save();
    notifyListeners();
  }

  void redo() {
    final next = history.redo(_document);

    if (next == null) return;

    _document = next;
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    _save();
    notifyListeners();
  }
}
