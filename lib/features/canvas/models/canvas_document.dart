import 'canvas_node.dart';
import 'canvas_edge.dart';

class CanvasDocument {
  final String id;
  final String name;
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  final double? canvasWidth;
  final double? canvasHeight;
  
  final double? viewportOffsetDx;
  final double? viewportOffsetDy;
  final double? viewportScale;

  const CanvasDocument({
    required this.id,
    required this.name,
    required this.nodes,
    required this.edges,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.canvasWidth,
    this.canvasHeight,
    this.viewportOffsetDx,
    this.viewportOffsetDy,
    this.viewportScale,
  });

  CanvasDocument copyWith({
    String? id,
    String? name,
    List<CanvasNode>? nodes,
    List<CanvasEdge>? edges,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    double? canvasWidth,
    double? canvasHeight,
    bool clearCanvasSize = false,
    double? viewportOffsetDx,
    double? viewportOffsetDy,
    double? viewportScale,
  }) {
    return CanvasDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      canvasWidth: clearCanvasSize ? null : (canvasWidth ?? this.canvasWidth),
      canvasHeight: clearCanvasSize ? null : (canvasHeight ?? this.canvasHeight),
      viewportOffsetDx: viewportOffsetDx ?? this.viewportOffsetDx,
      viewportOffsetDy: viewportOffsetDy ?? this.viewportOffsetDy,
      viewportScale: viewportScale ?? this.viewportScale,
    );
  }

  CanvasNode? getNodeById(String id) {
    try {
      return nodes.firstWhere((node) => node.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CanvasEdge> getEdgesForNode(String nodeId) {
    return edges.where((edge) {
      return edge.fromNodeId == nodeId || edge.toNodeId == nodeId;
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'viewportOffsetDx': viewportOffsetDx,
      'viewportOffsetDy': viewportOffsetDy,
      'viewportScale': viewportScale,
    };
  }

  factory CanvasDocument.fromJson(Map<String, dynamic> json) {
    return CanvasDocument(
      id: json['id'],
      name: json['name'],
      nodes: (json['nodes'] as List)
          .map((n) => CanvasNode.fromJson(n))
          .toList(),
      edges: (json['edges'] as List)
          .map((e) => CanvasEdge.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPinned: json['isPinned'] ?? false,
      canvasWidth: json['canvasWidth'] != null ? (json['canvasWidth'] as num).toDouble() : null,
      canvasHeight: json['canvasHeight'] != null ? (json['canvasHeight'] as num).toDouble() : null,
      viewportOffsetDx: json['viewportOffsetDx'] != null ? (json['viewportOffsetDx'] as num).toDouble() : null,
      viewportOffsetDy: json['viewportOffsetDy'] != null ? (json['viewportOffsetDy'] as num).toDouble() : null,
      viewportScale: json['viewportScale'] != null ? (json['viewportScale'] as num).toDouble() : null,
    );
  }
}
