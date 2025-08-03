import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/chat.dart';
import '../../providers/user_provider.dart';

class ChatUserActions {
  final BuildContext context;
  final Chat chat;
  final String? Function() friendId;

  ChatUserActions({
    required this.context,
    required this.chat,
    required this.friendId,
  });

  /// Block the current friend user
  Future<void> blockUser() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block User'),
          content: Text(
              'Are you sure you want to block ${chat.name}? You will no longer be able to see their messages or find them in search.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final currentFriendId = friendId();
        if (currentFriendId == null) {
          _showError('Unable to block user: Friend ID not found');
          return;
        }

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Block the user using UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final success = await userProvider.blockUser(currentFriendId);

        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${chat.name} has been blocked'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to previous screen
          Navigator.pop(context);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to block user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error blocking user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
} 