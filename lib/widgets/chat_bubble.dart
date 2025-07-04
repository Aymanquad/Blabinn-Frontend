import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final User? currentUser;

  const ChatBubble({
    super.key,
    required this.message,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = currentUser?.id == message.senderId;
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 64 : 8,
          right: isCurrentUser ? 8 : 64,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(),
            const SizedBox(height: 4),
            _buildMessageTime(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isCurrentUser 
            ? AppColors.sentMessage 
            : AppColors.receivedMessage,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: _isCurrentUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: _isCurrentUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
      ),
      child: _buildMessageBody(),
    );
  }

  Widget _buildMessageBody() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.displayContent,
          style: TextStyle(
            color: _isCurrentUser 
                ? AppColors.sentMessageText 
                : AppColors.receivedMessageText,
            fontSize: 16,
          ),
        );
      
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
        return Text(
          message.displayContent,
          style: TextStyle(
            color: _isCurrentUser 
                ? AppColors.sentMessageText 
                : AppColors.receivedMessageText,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        if (message.metadata?['caption'] != null) ...[
          const SizedBox(height: 8),
          Text(
            message.metadata!['caption'],
            style: TextStyle(
              color: _isCurrentUser 
                  ? AppColors.sentMessageText 
                  : AppColors.receivedMessageText,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Icon(
                    Icons.video_library,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
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
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _buildMessageTime() {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCurrentUser ? 0 : 16,
        right: _isCurrentUser ? 16 : 0,
      ),
      child: Text(
        message.formattedTime,
        style: TextStyle(
          color: AppColors.text.withOpacity(0.5),
          fontSize: 12,
        ),
      ),
    );
  }

  bool get _isCurrentUser => message.senderId == 'current_user'; // TODO: Get actual current user ID
} 