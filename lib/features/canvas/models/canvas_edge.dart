class CanvasEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final String? fromSide;
  final String? toSide;
  final String? type;

  const CanvasEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.fromSide,
    this.toSide,
    this.type,
  });

  CanvasEdge copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    String? fromSide,
    String? toSide,
    String? type,
  }) {
    return CanvasEdge(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      fromSide: fromSide ?? this.fromSide,
      toSide: toSide ?? this.toSide,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'fromSide': fromSide,
      'toSide': toSide,
      'type': type,
    };
  }

  factory CanvasEdge.fromJson(Map<String, dynamic> json) {
    return CanvasEdge(
      id: json['id'],
      fromNodeId: json['fromNodeId'],
      toNodeId: json['toNodeId'],
      fromSide: json['fromSide'],
      toSide: json['toSide'],
      type: json['type'],
    );
  }
}
