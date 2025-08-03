import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/premium_service.dart';
import '../../utils/permission_helper.dart';

class ChatImageHandler {
  final ApiService apiService;
  final SocketService socketService;
  final Function(VoidCallback) setState;
  final BuildContext context;
  final String? Function() friendId;

  final ImagePicker _imagePicker = ImagePicker();

  ChatImageHandler({
    required this.apiService,
    required this.socketService,
    required this.setState,
    required this.context,
    required this.friendId,
  });

  void showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Share Location'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement location sharing
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    // Check if user has premium
    final hasPremium = await PremiumService.checkChatImageSending(context);
    if (!hasPremium) {
      return; // User doesn't have premium, popup already shown
    }

    try {
      // print('📸 DEBUG: Starting camera capture');

      // Request camera permission
      final hasPermission =
          await PermissionHelper.requestCameraPermission(context);
      if (!hasPermission) {
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _showImageConfirmation(File(image.path));
      }
    } catch (e) {
      // print('❌ DEBUG: Camera capture error: $e');
      _showError('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    // Check if user has premium
    final hasPremium = await PremiumService.checkChatImageSending(context);
    if (!hasPremium) {
      return; // User doesn't have premium, popup already shown
    }

    try {
      // print('🖼️ DEBUG: Starting gallery picker');

      // Request gallery permission
      final hasPermission =
          await PermissionHelper.requestGalleryPermission(context);
      if (!hasPermission) {
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _showImageConfirmation(File(image.path));
      }
    } catch (e) {
      // print('❌ DEBUG: Gallery picker error: $e');
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _showImageConfirmation(File imageFile) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Send Image?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
                maxWidth: 300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _sendImageMessage(imageFile);
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    final currentFriendId = friendId();
    if (currentFriendId == null) {
      // print('❌ DEBUG: Cannot send image - friendId is null');
      return;
    }

    setState(() {
      // Note: This would need to be handled by the parent widget
      // For now, we'll just show a loading indicator
    });

    try {
      // print('📤 DEBUG: Uploading and sending image');

      // Upload image to backend
      final imageUrl = await apiService.uploadChatImage(imageFile);

      // Save image to media folder
      await _saveImageToMediaFolder(imageFile);

      // Send image message via socket service
      await socketService.sendFriendImageMessage(currentFriendId, imageUrl);

      setState(() {
        // Note: This would need to be handled by the parent widget
      });

      // The message will be received via socket and added to the UI automatically
      _showSuccess('Image sent successfully!');
    } catch (e) {
      // print('🚨 DEBUG: Error sending image: $e');
      setState(() {
        // Note: This would need to be handled by the parent widget
      });
      _showError('Failed to send image: $e');
    }
  }

  Future<void> _saveImageToMediaFolder(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');

      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_sent.jpg';
      final savedFile = File('${mediaDir.path}/$fileName');

      await imageFile.copy(savedFile.path);
      // print('✅ DEBUG: Sent image saved to media folder');
    } catch (e) {
      // print('⚠️ DEBUG: Failed to save sent image to media folder: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
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