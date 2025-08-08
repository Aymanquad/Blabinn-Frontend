import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../models/message.dart';
import '../../widgets/chat_bubble.dart';

class ChatUIComponents {
  static Widget buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin chatting!',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildMessageList(
    BuildContext context,
    List<Message> messages,
    String? currentUserId,
    bool hasMoreMessages,
    bool isLoadingEarlier,
    VoidCallback onLoadEarlierMessages,
    ScrollController scrollController, {
    int? firstUnreadMessageIndex,
    bool hasUnreadMessages = false,
    int unreadCount = 0,
    VoidCallback? onChatTap,
    VoidCallback? onUnreadIndicatorTap,
  }) {
    Widget listView = ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (hasMoreMessages ? 1 : 0) + (hasUnreadMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Show "Load Earlier Messages" button at the top
        if (index == 0 && hasMoreMessages) {
          return _buildLoadEarlierButton(
            context,
            isLoadingEarlier,
            onLoadEarlierMessages,
          );
        }

        // Calculate the position where unread indicator should appear
        int unreadIndicatorPosition = (hasMoreMessages ? 1 : 0) + (firstUnreadMessageIndex ?? 0);
        
        // Show unread messages indicator just above the first unread message
        if (hasUnreadMessages && 
            firstUnreadMessageIndex != null && 
            index == unreadIndicatorPosition) {
          return _buildUnreadMessagesIndicator(context, unreadCount, onUnreadIndicatorTap);
        }

        // Adjust index for messages
        int messageIndex = index;
        if (hasMoreMessages) messageIndex -= 1;
        if (hasUnreadMessages && index > unreadIndicatorPosition) messageIndex -= 1;
        
        // Ensure messageIndex is within bounds
        if (messageIndex < 0 || messageIndex >= messages.length) {
          return const SizedBox.shrink();
        }
        
        final message = messages[messageIndex];

        return ChatBubble(
          message: message,
          currentUserId: currentUserId,
        );
      },
    );

    // Wrap with GestureDetector if onChatTap is provided
    if (onChatTap != null) {
      return GestureDetector(
        onTap: onChatTap,
        child: listView,
      );
    }

    return listView;
  }

  static Widget _buildLoadEarlierButton(
    BuildContext context,
    bool isLoadingEarlier,
    VoidCallback onLoadEarlierMessages,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: isLoadingEarlier ? null : onLoadEarlierMessages,
          icon: isLoadingEarlier
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.keyboard_arrow_up),
          label: Text(
            isLoadingEarlier ? 'Loading...' : 'Load Earlier Messages',
            style: const TextStyle(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildUnreadMessagesIndicator(BuildContext context, int unreadCount, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_unread,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  unreadCount == 1 ? '1 new message' : '$unreadCount new messages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildMessageInput(
    BuildContext context,
    TextEditingController messageController,
    Function(String) onMessageChanged,
    VoidCallback onSendMessage,
    VoidCallback onAttachmentOptions,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: theme.colorScheme.onSurface),
            onPressed: onAttachmentOptions,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  onChanged: (value) {
                    onMessageChanged(value);
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.typeMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: messageController.text.length > 900
                        ? Icon(
                            Icons.warning,
                            color: messageController.text.length >= 1000
                                ? Colors.red
                                : Colors.orange,
                            size: 16,
                          )
                        : null,
                  ),
                  maxLines: 2, // Reduced from 4 to 2 for shorter height
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 1000,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                ),
                if (messageController.text.length > 900)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      '${messageController.text.length}/1000',
                      style: TextStyle(
                        fontSize: 12,
                        color: messageController.text.length >= 1000
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onSendMessage,
            ),
          ),
        ],
      ),
    );
  }

  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
