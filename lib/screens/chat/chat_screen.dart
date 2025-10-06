// This file serves as the main chat screen entry point
// Re-export the chat screen implementation from the chat subdirectory

import 'package:flutter/material.dart';
import '../../models/chat.dart';

// Chat screen that accepts a Chat model object
class ChatScreen extends StatelessWidget {
  final Chat chat;

  const ChatScreen({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chat.name ?? 'Chat'),
      ),
      body: Center(
        child: Text('Chat functionality coming soon'),
      ),
    );
  }
}
