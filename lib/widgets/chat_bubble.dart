import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../services/firebase_auth_service.dart';
import '../providers/theme_provider.dart';
import 'full_screen_image_viewer.dart';

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: _isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildMessageBubble(context, themeProvider.isDarkMode),
              const SizedBox(height: 2),
              _buildMessageTime(themeProvider.isDarkMode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isDarkMode) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: _getBubbleColor(isDarkMode),
        borderRadius: BorderRadius.circular(18).copyWith(
          topLeft: _isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
          topRight: _isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(context, isDarkMode),
          if (message.type != MessageType.text) _buildMessageStatus(isDarkMode),
        ],
      ),
    );
  }

  Color _getBubbleColor(bool isDarkMode) {
    if (_isCurrentUser) {
      // Sent messages: Simple purple in dark mode, primary in light mode
      return isDarkMode ? const Color(0xFF6B46C1) : AppColors.primary;
    } else {
      // Received messages: Simple gray in dark mode
      return isDarkMode ? const Color(0xFF4A4A5E) : AppColors.receivedMessage;
    }
  }

  Color _getTextColor(bool isDarkMode) {
    if (_isCurrentUser) {
      // Sent messages always use white text
      return Colors.white;
    } else {
      // Received messages use theme-appropriate text color
      return isDarkMode ? AppColors.darkText : AppColors.text;
    }
  }

  Widget _buildMessageContent(BuildContext context, bool isDarkMode) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(isDarkMode);
      case MessageType.image:
        return _buildImageMessage(context, isDarkMode);
      case MessageType.video:
        return _buildVideoMessage(isDarkMode);
      case MessageType.audio:
        return _buildAudioMessage(isDarkMode);
      case MessageType.location:
        return _buildLocationMessage(isDarkMode);
      case MessageType.file:
        return _buildFileMessage(isDarkMode);
      case MessageType.system:
        return _buildSystemMessage(isDarkMode);
      default:
        return _buildTextMessage(isDarkMode);
    }
  }

  Widget _buildTextMessage(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message.displayContent,
              style: TextStyle(
                color: _getTextColor(isDarkMode),
                fontSize: 16,
              ),
            ),
          ),
          if (_isCurrentUser) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context, bool isDarkMode) {
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
              ? GestureDetector(
                  onTap: () => _openFullScreenImage(context),
                  child: Hero(
                    tag: 'image_${message.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image failed to load',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                    Icons.image,
                    size: 64,
                    color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image URL',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.displayContent,
              style: TextStyle(
                color: _getTextColor(isDarkMode),
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage(bool isDarkMode) {
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
              message.displayContent,
              style: TextStyle(
                color: _getTextColor(isDarkMode),
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioMessage(bool isDarkMode) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.play_arrow,
            color: _getTextColor(isDarkMode),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Message',
                  style: TextStyle(
                    color: _getTextColor(isDarkMode),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.3,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(bool isDarkMode) {
    final latitude = message.metadata?['latitude']?.toDouble();
    final longitude = message.metadata?['longitude']?.toDouble();
    final address = message.metadata?['address'];

    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
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
                    color: _getTextColor(isDarkMode),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      color: _getTextColor(isDarkMode),
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

  Widget _buildFileMessage(bool isDarkMode) {
    final fileName = message.metadata?['fileName'] ?? 'File';
    final fileSize = message.metadata?['fileSize'] ?? 'Unknown size';

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
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
                    color: _getTextColor(isDarkMode),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fileSize,
                  style: TextStyle(
                    color: _getTextColor(isDarkMode),
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

  Widget _buildSystemMessage(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDarkMode ? AppColors.darkText : AppColors.text).withOpacity(0.2)),
      ),
      child: Text(
        message.displayContent,
        style: TextStyle(
          color: (isDarkMode ? AppColors.darkText : AppColors.text).withOpacity(0.7),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageStatus(bool isDarkMode) {
    if (!_isCurrentUser) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: Colors.white.withOpacity(0.7),
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

  Widget _buildMessageTime(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCurrentUser ? 0 : 16,
        right: _isCurrentUser ? 16 : 0,
      ),
      child: Text(
        message.formattedTime ?? _formatTime(message.timestamp),
        style: TextStyle(
          color: (isDarkMode ? AppColors.darkText : AppColors.text).withOpacity(0.5),
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

  void _openFullScreenImage(BuildContext context) {
    if (message.imageUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(
            imageUrl: message.imageUrl!,
            heroTag: 'image_${message.id}',
          ),
        ),
      );
    }
  }
} 