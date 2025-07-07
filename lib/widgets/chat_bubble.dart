import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../services/firebase_auth_service.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final String? currentUserId;

  const ChatBubble({
    super.key,
    required this.message,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: _isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          const SizedBox(height: 2),
          _buildMessageTime(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: _isCurrentUser ? AppColors.sentMessage : AppColors.receivedMessage,
        borderRadius: BorderRadius.circular(18).copyWith(
          topLeft: _isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
          topRight: _isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(),
          _buildMessageStatus(),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.location:
        return _buildLocationMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.system:
        return _buildSystemMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        message.content,
        style: TextStyle(
          color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            color: Colors.grey[300],
          ),
          child: message.imageUrl != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.image,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
        ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.content,
              style: TextStyle(
                color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            color: Colors.grey[300],
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.content,
              style: TextStyle(
                color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioMessage() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.play_arrow,
            color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Message',
                  style: TextStyle(
                    color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const LinearProgressIndicator(
                  value: 0.3,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage() {
    final latitude = message.metadata?['latitude']?.toDouble();
    final longitude = message.metadata?['longitude']?.toDouble();
    final address = message.metadata?['address'];

    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.grey[300],
            ),
            child: const Center(
              child: Icon(
                Icons.location_on,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: TextStyle(
                    color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage() {
    final fileName = message.metadata?['fileName'] ?? 'File';
    final fileSize = message.metadata?['fileSize'] ?? 'Unknown size';

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.attach_file,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fileSize,
                  style: TextStyle(
                    color: _isCurrentUser ? AppColors.sentMessageText : AppColors.receivedMessageText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.text.withOpacity(0.2)),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: AppColors.text.withOpacity(0.7),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!_isCurrentUser) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: AppColors.sentMessageText.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  Widget _buildMessageTime() {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCurrentUser ? 0 : 16,
        right: _isCurrentUser ? 16 : 0,
      ),
      child: Text(
        message.formattedTime ?? _formatTime(message.timestamp),
        style: TextStyle(
          color: AppColors.text.withOpacity(0.5),
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDay == today) {
      // Show time for today's messages
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // Show date for older messages
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }

  bool get _isCurrentUser {
    if (currentUserId != null) {
      return message.senderId == currentUserId;
    }
    
    // Fallback: Try to get current user ID from Firebase
    final authService = FirebaseAuthService();
    final user = authService.currentUser;
    if (user != null) {
      return message.senderId == user.uid;
    }
    
    return false;
  }
} 