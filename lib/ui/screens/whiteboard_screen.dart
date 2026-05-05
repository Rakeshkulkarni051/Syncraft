import 'package:flutter/material.dart';

import '../widgets/canvas_toolbar.dart';
import '../widgets/whiteboard_canvas.dart';

/// Primary workspace: toolbar + live canvas.
class WhiteboardScreen extends StatelessWidget {
  const WhiteboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Syncraft'),
            Text(
              'Live board · Firestore offline cache',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CanvasToolbar(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: WhiteboardCanvas(),
            ),
          ),
        ],
      ),
    );
  }
}
