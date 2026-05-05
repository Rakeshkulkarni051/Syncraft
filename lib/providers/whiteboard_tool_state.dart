import 'package:flutter/foundation.dart';

import '../core/board_constants.dart';
import '../models/shape_model.dart';

/// Toolbar + selection state (local only; not synced to Firestore).
class WhiteboardToolState extends ChangeNotifier {
  ShapeType _activeTool = ShapeType.rectangle;
  String _activeColor = kPaletteColors[5]; // blue
  String? _selectedShapeId;

  ShapeType get activeTool => _activeTool;
  String get activeColor => _activeColor;
  String? get selectedShapeId => _selectedShapeId;

  void setTool(ShapeType tool) {
    if (_activeTool == tool) return;
    _activeTool = tool;
    notifyListeners();
  }

  void setColor(String color) {
    if (_activeColor == color) return;
    _activeColor = color;
    notifyListeners();
  }

  void selectShape(String? id) {
    if (_selectedShapeId == id) return;
    _selectedShapeId = id;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedShapeId == null) return;
    _selectedShapeId = null;
    notifyListeners();
  }
}
