import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../core/board_constants.dart';
import '../models/shape_model.dart';
import 'crdt_service.dart';

/// Firestore access for the single shared board.
///
/// Shapes live at `boards/{boardId}/shapes/{shapeId}` with the schema from the spec.
class BoardFirestoreService {
  BoardFirestoreService(
    this._firestore, {
    String boardId = kDefaultBoardId,
    required String actorId,
  })  : _boardId = boardId,
        _actorId = actorId {
    _startRemoteSync();
  }

  final FirebaseFirestore _firestore;
  final String _boardId;
  final String _actorId;
  final ShapeCrdtService _crdt = ShapeCrdtService();
  final StreamController<List<BoardShape>> _shapesController =
      StreamController<List<BoardShape>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSubscription;

  CollectionReference<Map<String, dynamic>> get _shapes =>
      _firestore.collection('boards').doc(_boardId).collection('shapes');

  void _startRemoteSync() {
    _remoteSubscription = _shapes
        .snapshots(includeMetadataChanges: false)
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _crdt.remove(change.doc.id);
          continue;
        }
        final data = change.doc.data();
        if (data == null) continue;
        final remote = BoardShape.fromFirestore(change.doc.id, data);
        _crdt.applyRemoteUpdate(remote);
      }
      _emitShapes();
    });
  }

  void _emitShapes() {
    if (!_shapesController.isClosed) {
      _shapesController.add(_crdt.getAllSorted());
    }
  }

  /// UI stream already contains merged CRDT state (not raw snapshot data).
  Stream<List<BoardShape>> watchShapes() {
    _emitShapes();
    return _shapesController.stream;
  }

  Future<String> createShape({
    required ShapeType type,
    required double x,
    required double y,
    required double width,
    required double height,
    required String color,
    String? text,
  }) async {
    final ref = _shapes.doc();
    final id = ref.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final shape = BoardShape(
      id: id,
      type: type,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      text: text,
      version: 1,
      lastUpdatedBy: _actorId,
      timestamp: now,
    );

    // Local-first: render immediately, then sync to Firestore.
    _crdt.applyLocalUpdate(shape);
    _emitShapes();
    await ref.set(shape.toFirestore());
    return id;
  }

  /// Partial update; version and timestamp advance once per logical edit.
  Future<void> updateShape(
    String id, {
    double? x,
    double? y,
    double? width,
    double? height,
    String? color,
    String? text,
  }) async {
    final current = _crdt.getById(id);
    if (current == null) return;

    final next = current.copyWith(
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      text: text,
      version: current.version + 1,
      lastUpdatedBy: _actorId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _crdt.applyLocalUpdate(next);
    _emitShapes();
    await _shapes.doc(id).set(next.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteShape(String id) async {
    _crdt.remove(id);
    _emitShapes();
    await _shapes.doc(id).delete();
  }

  Future<void> dispose() async {
    await _remoteSubscription?.cancel();
    await _shapesController.close();
  }
}
