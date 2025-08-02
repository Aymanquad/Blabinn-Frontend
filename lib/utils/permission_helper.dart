import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Utility class for handling gallery permissions across the app
class PermissionHelper {
  /// Requests gallery permission and shows appropriate dialogs
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    // Request storage permission (use photos permission for Android 13+)
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.storage.request();
    }

    if (status == PermissionStatus.granted) {
      return true;
    }

    // Show permission request dialog
    final shouldRequestAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gallery Permission Required'),
        content: const Text(
            'This app needs access to your gallery to select images. Please grant permission to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    if (shouldRequestAgain == true) {
      // Try requesting permission again
      if (Platform.isAndroid) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
      
      if (status == PermissionStatus.granted) {
        return true;
      }

      // Check if permission is permanently denied
      if (status == PermissionStatus.permanentlyDenied) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gallery Permission Required'),
            content: const Text(
                'Please grant gallery permission in app settings to select images.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
    }

    return false;
  }

  /// Requests camera permission and shows appropriate dialogs
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status == PermissionStatus.granted) {
      return true;
    }

    // Show permission request dialog
    final shouldRequestAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
            'This app needs access to your camera to take photos. Please grant permission to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    if (shouldRequestAgain == true) {
      final newStatus = await Permission.camera.request();
      
      if (newStatus == PermissionStatus.granted) {
        return true;
      }

      // Check if permission is permanently denied
      if (newStatus == PermissionStatus.permanentlyDenied) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
                'Please grant camera permission in app settings to take photos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
    }

    return false;
  }
} 