import 'dart:ui';

enum CanvasNodeType {
  note,
  text,
  image,
  group,
  audio,
  task,
  goal,
}

class CanvasNode {
  final String id;
  final String title;
  final String content;
  final CanvasNodeType type;
  final Offset position;
  final Size size;
  final Color? accentColor;
  final double? borderWidth;
  final bool? showTitle;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasNode({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.position,
    required this.size,
    this.accentColor,
    this.borderWidth,
    this.showTitle,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  CanvasNode copyWith({
    String? id,
    String? title,
    String? content,
    CanvasNodeType? type,
    Offset? position,
    Size? size,
    Color? accentColor,
    double? borderWidth,
    bool? showTitle,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearParentId = false,
  }) {
    return CanvasNode(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      accentColor: accentColor ?? this.accentColor,
      borderWidth: borderWidth ?? this.borderWidth,
      showTitle: showTitle ?? this.showTitle,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.index,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'accentColor': accentColor?.value,
      'borderWidth': borderWidth,
      'showTitle': showTitle,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CanvasNode.fromJson(Map<String, dynamic> json) {
    return CanvasNode(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: CanvasNodeType.values[json['type']],
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      size: Size(
        (json['size']['width'] as num).toDouble(),
        (json['size']['height'] as num).toDouble(),
      ),
      accentColor: json['accentColor'] != null ? Color(json['accentColor']) : null,
      borderWidth: json['borderWidth'] != null ? (json['borderWidth'] as num).toDouble() : null,
      showTitle: json['showTitle'] ?? true,
      parentId: json['parentId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
