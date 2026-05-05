import 'package:flutter/material.dart';

/// Isolated grid layer: lives outside `StreamBuilder` so shape updates never repaint it.
class BoardGridBackground extends StatelessWidget {
  const BoardGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _OptimizedGridPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

/// Fewer primitives than a dense minor/major grid; one muted color for speed.
class _OptimizedGridPainter extends CustomPainter {
  const _OptimizedGridPainter();

  static const _step = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OptimizedGridPainter oldDelegate) => false;
}
