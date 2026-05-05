import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/board_constants.dart';
import '../../models/shape_model.dart';
import '../../providers/whiteboard_tool_state.dart';
import '../../services/board_firestore_service.dart';

/// Top tool rail: shape modes, palette, delete.
class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({super.key});

  Future<void> _deleteSelected(BuildContext context) async {
    final tools = context.read<WhiteboardToolState>();
    final service = context.read<BoardFirestoreService>();
    final id = tools.selectedShapeId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a shape to delete')),
      );
      return;
    }
    await service.deleteShape(id);
    tools.clearSelection();
  }

  void _onColorTap(BuildContext context, String hex) {
    final tools = context.read<WhiteboardToolState>();
    final service = context.read<BoardFirestoreService>();
    tools.setColor(hex);
    final selected = tools.selectedShapeId;
    if (selected != null) {
      service.updateShape(selected, color: hex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<WhiteboardToolState>();

    return Material(
      elevation: 2,
      color: const Color(0xFFFAFAFA),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 520;
              final toolsRow = Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ToolChip(
                    icon: Icons.crop_square_rounded,
                    label: 'Rect',
                    selected: tools.activeTool == ShapeType.rectangle,
                    onTap: () => tools.setTool(ShapeType.rectangle),
                  ),
                  _ToolChip(
                    icon: Icons.circle_outlined,
                    label: 'Circle',
                    selected: tools.activeTool == ShapeType.circle,
                    onTap: () => tools.setTool(ShapeType.circle),
                  ),
                  _ToolChip(
                    icon: Icons.show_chart,
                    label: 'Line',
                    selected: tools.activeTool == ShapeType.line,
                    onTap: () => tools.setTool(ShapeType.line),
                  ),
                  _ToolChip(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    selected: tools.activeTool == ShapeType.text,
                    onTap: () => tools.setTool(ShapeType.text),
                  ),
                ],
              );
              final colorsRow = Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final hex in kPaletteColors)
                    _ColorDot(
                      hex: hex,
                      selected: tools.activeColor.toUpperCase() == hex.toUpperCase(),
                      onTap: () => _onColorTap(context, hex),
                    ),
                ],
              );
              final deleteBtn = FilledButton.tonalIcon(
                onPressed: () => _deleteSelected(context),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    toolsRow,
                    const SizedBox(height: 8),
                    colorsRow,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: deleteBtn),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  toolsRow,
                  const SizedBox(width: 12),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 12),
                  colorsRow,
                  const Spacer(),
                  deleteBtn,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE2E8F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF64748B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = BoardShape.parseHexColor(hex);
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: selected ? 3 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
