import '../models/shape_model.dart';

/// Minimal per-shape CRDT cache.
///
/// Each shape is an independent CRDT element resolved by:
/// 1) higher `version`
/// 2) newer `timestamp` when versions are equal
/// 3) lexical `lastUpdatedBy` tie-break for deterministic output
class ShapeCrdtService {
  final Map<String, BoardShape> _state = <String, BoardShape>{};

  BoardShape? getById(String id) => _state[id];

  List<BoardShape> getAllSorted() {
    final list = _state.values.toList(growable: false);
    list.sort((a, b) {
      final byTs = a.timestamp.compareTo(b.timestamp);
      if (byTs != 0) return byTs;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// Local edits are applied optimistically so UI stays local-first/offline-first.
  BoardShape applyLocalUpdate(BoardShape shape) {
    final merged = merge(_state[shape.id], shape);
    _state[shape.id] = merged;
    return merged;
  }

  /// Remote updates go through the exact same deterministic merge function.
  BoardShape applyRemoteUpdate(BoardShape shape) {
    final merged = merge(_state[shape.id], shape);
    _state[shape.id] = merged;
    return merged;
  }

  void remove(String id) {
    _state.remove(id);
  }

  /// CRDT merge: commutative + idempotent + deterministic.
  ///
  /// - Commutative: comparing metadata yields same winner regardless of order.
  /// - Idempotent: merging same value repeatedly does not change state.
  /// - Eventual consistency: all replicas converge after exchanging updates.
  BoardShape merge(BoardShape? localShape, BoardShape remoteShape) {
    if (localShape == null) return remoteShape;

    if (remoteShape.version > localShape.version) return remoteShape;
    if (remoteShape.version < localShape.version) return localShape;

    if (remoteShape.timestamp > localShape.timestamp) return remoteShape;
    if (remoteShape.timestamp < localShape.timestamp) return localShape;

    if (remoteShape.lastUpdatedBy.compareTo(localShape.lastUpdatedBy) > 0) {
      return remoteShape;
    }
    return localShape;
  }
}
