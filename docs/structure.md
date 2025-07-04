

lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   └── config.dart
├── models/
│   ├── user.dart
│   ├── message.dart
│   └── chat.dart
├── services/
│   ├── api_service.dart
│   ├── socket_service.dart
│   ├── translator_service.dart
│   └── auth_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── profile_screen.dart
│   ├── connect_screen.dart
│   └── video_call_screen.dart
├── widgets/
│   ├── chat_bubble.dart
│   └── profile_card.dart
└── providers/
    ├── user_provider.dart
    └── chat_provider.dart







Architecture Diagram Simple Flow : 


+----------------------+
|    Flutter App       |
|                      |
| - REST API (Profile) |
| - WebSocket (Chat)   |
| - Image Upload       |
| - Video Signaling    |
+----------+-----------+
           |
           ▼
+---------------------------+
|    Node.js Backend (Railway)   |
+---------------------------+
| /api/users                 |
| /api/chat                  |
| /socket.io (chat, match)   |
| /api/media                 |
| /api/friends               |
+---------------------------+
| Redis (Queue, PubSub)     |
| PostgreSQL (User, Chats)  |
| S3/Cloudinary (Images)    |
| Google Translate API      |
| WebRTC/Agora (Video)      |
+---------------------------+
