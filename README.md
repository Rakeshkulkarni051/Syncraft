🚀 Syncraft

Syncraft is a cross-platform collaborative whiteboard built with Flutter and Firebase, demonstrating real-time synchronization and offline-first behavior using a simplified CRDT (Conflict-free Replicated Data Type) model.

It allows multiple users to interact with a shared canvas seamlessly while ensuring conflict-free merging and eventual consistency across devices.

🎯 Features
✏️ Draw shapes (Rectangle, Circle, Line, Text)
🎨 Change colors and edit objects
🖱️ Drag and move shapes smoothly
🔄 Real-time synchronization across devices
📡 Offline-first support (works without internet)
🔁 Automatic sync on reconnect
⚡ Conflict-free updates using CRDT-inspired logic
🧠 How It Works

Syncraft combines:

Flutter → UI + cross-platform support
Firebase Firestore → real-time database + offline persistence
CRDT-inspired model → conflict-free synchronization
🔥 CRDT Implementation (Core Idea)

Each shape in Syncraft is treated as an independent replicated object.

Every update includes:

{
  "id": "shape_1",
  "version": 3,
  "timestamp": 1710000000,
  "lastUpdatedBy": "deviceA"
}
🧩 Merge Strategy

When conflicts occur (multiple users update same shape):

Higher version wins
If equal → newer timestamp wins
If still equal → device ID tie-breaker
✅ Why This Works

This ensures:

✔ Commutativity → order doesn’t matter
✔ Idempotency → repeated updates don’t break state
✔ Eventual Consistency → all devices converge
🧠 In Simple Terms

Every device can update independently, and the system automatically merges changes without conflicts.

🏗 Architecture
Flutter UI (Canvas)
        ↓
Local CRDT State
        ↓
Firestore (Realtime Sync)
        ↓
Other Devices
📱 Demo Scenario
Open Syncraft on mobile and web
Draw shapes → instantly visible on both
Turn off internet on one device
Continue drawing
Reconnect → changes sync automatically
⚙️ Tech Stack
Flutter (Cross-platform UI)
Firebase Firestore (Realtime DB)
Dart
CRDT-inspired synchronization model
🚀 Getting Started
1. Clone the repository
git clone https://github.com/your-username/syncraft.git
cd syncraft
2. Install dependencies
flutter pub get
3. Add Firebase configuration

Add your Firebase config files:

android/app/google-services.json
ios/Runner/GoogleService-Info.plist
4. Run the app
flutter run
⚠️ Notes
Firestore rules are open for demo purposes
In production, authentication and secure rules should be implemented
🎓 Academic Context

This project was developed as part of a Technical Seminar to demonstrate:

Distributed Systems concepts
Conflict-free data synchronization
Real-time collaboration architecture
🏆 Key Learning
Designing local-first applications
Handling concurrent updates
Implementing CRDT-inspired systems
Building scalable real-time apps
📌 Future Improvements
Full CRDT implementation (beyond LWW)
Multi-board collaboration
User authentication
Undo/Redo system
Advanced canvas tools

👨‍💻 Author
Rakesh Kulkarni
