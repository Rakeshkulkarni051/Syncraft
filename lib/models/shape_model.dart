import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Wire values: rectangle | circle | line | text
enum ShapeType {
  rectangle,
  circle,
  line,
  text,
}

/// Immutable board element stored in `boards/{boardId}/shapes/{id}`.
class BoardShape {
  const BoardShape({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.text,
    required this.version,
    required this.lastUpdatedBy,
    required this.timestamp,
  });

  final String id;
  final ShapeType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String color;
  final String? text;
  final int version;
  final String lastUpdatedBy;
  final int timestamp;

  static ShapeType _parseType(String? raw) {
    if (raw == null) return ShapeType.rectangle;
    return ShapeType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ShapeType.rectangle,
    );
  }

  static int _asEpoch(dynamic v) {
    if (v is Timestamp) return v.toDate().millisecondsSinceEpoch;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is num) return v.toInt();
    return DateTime.now().millisecondsSinceEpoch;
  }

  factory BoardShape.fromFirestore(String docId, Map<String, dynamic> data) {
    final id = (data['id'] as String?) ?? docId;
    return BoardShape(
      id: id,
      type: _parseType(data['type'] as String?),
      x: (data['x'] as num?)?.toDouble() ?? 0,
      y: (data['y'] as num?)?.toDouble() ?? 0,
      width: (data['width'] as num?)?.toDouble() ?? 80,
      height: (data['height'] as num?)?.toDouble() ?? 80,
      color: (data['color'] as String?) ?? '#2563EB',
      text: data['text'] as String?,
      version: (data['version'] as num?)?.toInt() ?? 0,
      lastUpdatedBy: (data['lastUpdatedBy'] as String?) ?? 'unknown',
      timestamp: _asEpoch(data['timestamp'] ?? data['updatedAt'] ?? data['createdAt']),
    );
  }

  /// Hit-testing / layout bounds in board coordinates.
  Rect get bounds {
    switch (type) {
      case ShapeType.line:
        final x2 = x + width;
        final y2 = y + height;
        final left = x < x2 ? x : x2;
        final top = y < y2 ? y : y2;
        final right = x > x2 ? x : x2;
        final bottom = y > y2 ? y : y2;
        // Widen thin lines for easier grabs.
        return Rect.fromLTRB(left, top, right, bottom).inflate(12);
      case ShapeType.rectangle:
      case ShapeType.circle:
      case ShapeType.text:
        return Rect.fromLTWH(x, y, width, height);
    }
  }

  Color get colorValue => parseHexColor(color);

  /// Bounding box for layout/painting (line uses true geometry, not hit slop).
  Rect get displayRect {
    switch (type) {
      case ShapeType.line:
        final x2 = x + width;
        final y2 = y + height;
        var left = x < x2 ? x : x2;
        var top = y < y2 ? y : y2;
        var right = x > x2 ? x : x2;
        var bottom = y > y2 ? y : y2;
        if ((right - left).abs() < 1) {
          right = left + 1;
        }
        if ((bottom - top).abs() < 1) {
          bottom = top + 1;
        }
        return Rect.fromLTRB(left, top, right, bottom);
      case ShapeType.rectangle:
      case ShapeType.circle:
      case ShapeType.text:
        return Rect.fromLTWH(x, y, width, height);
    }
  }

  BoardShape copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? color,
    String? text,
    int? version,
    String? lastUpdatedBy,
    int? timestamp,
  }) {
    return BoardShape(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      text: text ?? this.text,
      version: version ?? this.version,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
      if (text != null && text!.isNotEmpty) 'text': text,
      'version': version,
      'lastUpdatedBy': lastUpdatedBy,
      'timestamp': timestamp,
    };
  }

  static Color parseHexColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return const Color(0xFF2563EB);
  }
}
