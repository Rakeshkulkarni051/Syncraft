import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shape_model.dart';
import '../../providers/whiteboard_tool_state.dart';
import '../../services/board_firestore_service.dart';
import 'board_grid_background.dart';
import 'board_shape_widget.dart';

/// Board: static grid + gesture layer (never tied to Firestore stream), shapes in a narrow `StreamBuilder`.
class WhiteboardCanvas extends StatelessWidget {
  const WhiteboardCanvas({super.key});

  static Size _defaultSize(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return const Size(140, 92);
      case ShapeType.circle:
        return const Size(92, 92);
      case ShapeType.line:
        return const Size(132, 56);
      case ShapeType.text:
        return const Size(200, 48);
    }
  }

  Future<String?> _promptText(BuildContext context) async {
    final controller = TextEditingController(text: 'Label');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add text'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Type something…'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Place'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _handleBackgroundTap(
    BuildContext context,
    Offset local,
    Size canvasSize,
  ) async {
    final tools = context.read<WhiteboardToolState>();
    final service = context.read<BoardFirestoreService>();

    tools.clearSelection();

    String? text;
    if (tools.activeTool == ShapeType.text) {
      text = await _promptText(context);
      if (text == null || text.isEmpty) return;
    }

    final def = _defaultSize(tools.activeTool);
    final w = def.width;
    final h = def.height;
    late final double x;
    late final double y;
    late final double outW;
    late final double outH;

    if (tools.activeTool == ShapeType.line) {
      outW = w * 0.72;
      outH = h * 0.55;
      x = (local.dx - outW / 2).clamp(0.0, canvasSize.width - outW);
      y = (local.dy - outH / 2).clamp(0.0, canvasSize.height - outH);
    } else {
      outW = w;
      outH = h;
      x = (local.dx - w / 2).clamp(0.0, canvasSize.width - w);
      y = (local.dy - h / 2).clamp(0.0, canvasSize.height - h);
    }

    await service.createShape(
      type: tools.activeTool,
      x: x,
      y: y,
      width: outW,
      height: outH,
      color: tools.activeColor,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<BoardFirestoreService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onTapDown: (d) => _handleBackgroundTap(
                      context,
                      d.localPosition,
                      size,
                    ),
                    child: const BoardGridBackground(),
                  ),
                ),
                Positioned.fill(
                  child: StreamBuilder<List<BoardShape>>(
                    stream: service.watchShapes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Could not load board.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final shapes = snapshot.data ?? [];
                      final tools = context.read<WhiteboardToolState>();

                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (final shape in shapes)
                            BoardShapeWidget(
                              key: ValueKey(shape.id),
                              shape: shape,
                              onSelect: () => tools.selectShape(shape.id),
                              service: service,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
