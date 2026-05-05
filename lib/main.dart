import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/whiteboard_tool_state.dart';
import 'services/board_firestore_service.dart';
import 'ui/screens/whiteboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final actorId = 'client-${DateTime.now().millisecondsSinceEpoch}';

  // Offline persistence: mobile uses durable cache; web uses IndexedDB when enabled.
  try {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } on Object catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firestore settings skipped: $e\n$st');
    }
  }

  final boardService = BoardFirestoreService(firestore, actorId: actorId);

  runApp(
    MultiProvider(
      providers: [
        Provider<BoardFirestoreService>.value(value: boardService),
        ChangeNotifierProvider(create: (_) => WhiteboardToolState()),
      ],
      child: const SyncraftApp(),
    ),
  );
}

class SyncraftApp extends StatelessWidget {
  const SyncraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Syncraft',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEEF2F6),
      ),
      home: const WhiteboardScreen(),
    );
  }
}
