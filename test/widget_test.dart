import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncraft/models/shape_model.dart';

void main() {
  test('BoardShape.fromFirestore maps fields and type', () {
    final now = DateTime(2026, 1, 1);
    final shape = BoardShape.fromFirestore('doc1', {
      'id': 'doc1',
      'type': 'line',
      'x': 10.0,
      'y': 20.0,
      'width': 30.0,
      'height': -5.0,
      'color': '#FF0000',
      'text': null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    expect(shape.id, 'doc1');
    expect(shape.type, ShapeType.line);
    expect(shape.displayRect.left, 10);
    expect(shape.displayRect.bottom, 20);
  });
}
