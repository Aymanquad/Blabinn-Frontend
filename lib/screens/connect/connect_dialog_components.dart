import 'package:flutter/material.dart';
import 'connect_state_manager.dart';
import 'connect_filter_components.dart';

class ConnectDialogComponents {
  static void showClearSessionDialog(BuildContext context, ConnectStateManager stateManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Active Session Found'),
          ],
        ),
        content: const Text(
            'You have an active chat session. Would you like to clear it and start a new one?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              stateManager.clearActiveSession();
            },
            child: const Text('Clear Session'),
          ),
        ],
      ),
    );
  }

  static void showTimeoutDialog(BuildContext context, ConnectStateManager stateManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Match Found'),
          ],
        ),
        content: Text(stateManager.matchMessage ??
            'No match found after 5 minutes. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              stateManager.startMatching();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showFilterDialog(BuildContext context, ConnectStateManager stateManager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConnectFilterComponents.buildFilterDialog(context, stateManager),
    );
  }
} 