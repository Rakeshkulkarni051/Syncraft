import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shape_model.dart';
import '../../providers/whiteboard_tool_state.dart';
import '../../services/board_firestore_service.dart';

/// One shape = one `Positioned` subtree. Drag/resize are local until the gesture ends (single Firestore write).
class BoardShapeWidget extends StatefulWidget {
  const BoardShapeWidget({
    super.key,
    required this.shape,
    required this.onSelect,
    required this.service,
  });

  final BoardShape shape;
  final VoidCallback onSelect;
  final BoardFirestoreService service;

  @override
  State<BoardShapeWidget> createState() => _BoardShapeWidgetState();
}

class _BoardShapeWidgetState extends State<BoardShapeWidget> {
  static const _minSize = 36.0;
  static const _maxSide = 800.0;

  Offset _dragAccum = Offset.zero;
  double _resizeW = 0;
  double _resizeH = 0;
  double _resizeCirc = 0;
  bool _dragging = false;
  bool _resizing = false;

  BoardShape get _base => widget.shape;

  BoardShape get _visualMove =>
      _base.copyWith(x: _base.x + _dragAccum.dx, y: _base.y + _dragAccum.dy);

  BoardShape get _visual {
    var s = _visualMove;
    if (!_resizing) return s;

    switch (s.type) {
      case ShapeType.circle:
        final side = (s.width + _resizeCirc).clamp(_minSize, _maxSide);
        return s.copyWith(width: side, height: side);
      case ShapeType.line:
        return s.copyWith(width: s.width + _resizeW, height: s.height + _resizeH);
      case ShapeType.rectangle:
      case ShapeType.text:
        return s.copyWith(
          width: (s.width + _resizeW).clamp(_minSize, 2000.0),
          height: (s.height + _resizeH).clamp(_minSize, 2000.0),
        );
    }
  }

  @override
  void didUpdateWidget(covariant BoardShapeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && !_resizing && oldWidget.shape.id == widget.shape.id) {
      if (oldWidget.shape.x != widget.shape.x || oldWidget.shape.y != widget.shape.y) {
        _dragAccum = Offset.zero;
      }
      if (oldWidget.shape.width != widget.shape.width ||
          oldWidget.shape.height != widget.shape.height) {
        _resizeW = 0;
        _resizeH = 0;
        _resizeCirc = 0;
      }
    }
  }

  Future<void> _commitPosition(double x, double y) {
    return widget.service.updateShape(widget.shape.id, x: x, y: y);
  }

  Future<void> _commitGeometry(BoardShape vis) {
    return widget.service.updateShape(
      widget.shape.id,
      x: vis.x,
      y: vis.y,
      width: vis.width,
      height: vis.height,
    );
  }

  void _onResizeDelta(Offset d) {
    setState(() {
      switch (_base.type) {
        case ShapeType.circle:
          _resizeCirc += (d.dx + d.dy) / 2;
          break;
        case ShapeType.line:
        case ShapeType.rectangle:
        case ShapeType.text:
          _resizeW += d.dx;
          _resizeH += d.dy;
          break;
      }
    });
  }

  void _resetResize() {
    _resizeW = 0;
    _resizeH = 0;
    _resizeCirc = 0;
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<WhiteboardToolState, bool>(
      (t) => t.selectedShapeId == widget.shape.id,
    );

    final s = _visual;
    final r = s.displayRect;

    return Positioned(
      key: ValueKey(s.id),
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSelect,
                onPanStart: (_) {
                  widget.onSelect();
                  setState(() => _dragging = true);
                },
                onPanUpdate: (details) {
                  if (!_dragging) return;
                  setState(() => _dragAccum += details.delta);
                },
                onPanEnd: (_) async {
                  if (!_dragging) return;
                  final nx = _base.x + _dragAccum.dx;
                  final ny = _base.y + _dragAccum.dy;
                  setState(() {
                    _dragging = false;
                    _dragAccum = Offset.zero;
                  });
                  await _commitPosition(nx, ny);
                },
                onPanCancel: () async {
                  if (!_dragging) return;
                  final nx = _base.x + _dragAccum.dx;
                  final ny = _base.y + _dragAccum.dy;
                  setState(() {
                    _dragging = false;
                    _dragAccum = Offset.zero;
                  });
                  await _commitPosition(nx, ny);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: const Color(0xFF0EA5E9), width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _ShapeBody(shape: s, layoutTopLeft: Offset(r.left, r.top)),
                ),
              ),
            ),
            if (isSelected)
              _ResizeHandle(
                onPanStart: () {
                  widget.onSelect();
                  setState(() => _resizing = true);
                },
                onPanUpdate: _onResizeDelta,
                onPanEnd: () async {
                  if (!_resizing) return;
                  final vis = _visual;
                  setState(() {
                    _resizing = false;
                    _resetResize();
                  });
                  await _commitGeometry(vis);
                },
                onPanCancel: () {
                  if (!_resizing) return;
                  setState(() {
                    _resizing = false;
                    _resetResize();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  final VoidCallback onPanStart;
  final void Function(Offset delta) onPanUpdate;
  final Future<void> Function() onPanEnd;
  final VoidCallback onPanCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -6,
      bottom: -6,
      width: 22,
      height: 22,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onPanStart(),
        onPanUpdate: (d) => onPanUpdate(d.delta),
        onPanEnd: (_) {
          onPanEnd();
        },
        onPanCancel: onPanCancel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0EA5E9), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeBody extends StatelessWidget {
  const _ShapeBody({
    required this.shape,
    required this.layoutTopLeft,
  });

  final BoardShape shape;
  final Offset layoutTopLeft;

  @override
  Widget build(BuildContext context) {
    switch (shape.type) {
      case ShapeType.rectangle:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: shape.colorValue.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: shape.colorValue, width: 2),
          ),
        );
      case ShapeType.circle:
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: shape.colorValue.withValues(alpha: 0.26),
            border: Border.all(color: shape.colorValue, width: 2),
          ),
        );
      case ShapeType.line:
        return CustomPaint(
          painter: _LinePainter(
            start: Offset(shape.x - layoutTopLeft.dx, shape.y - layoutTopLeft.dy),
            end: Offset(
              shape.x + shape.width - layoutTopLeft.dx,
              shape.y + shape.height - layoutTopLeft.dy,
            ),
            color: shape.colorValue,
            strokeWidth: 3,
          ),
          child: const SizedBox.expand(),
        );
      case ShapeType.text:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: shape.colorValue.withValues(alpha: 0.35)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                (shape.text == null || shape.text!.isEmpty) ? 'Text' : shape.text!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: shape.colorValue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.start,
    required this.end,
    required this.color,
    required this.strokeWidth,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
