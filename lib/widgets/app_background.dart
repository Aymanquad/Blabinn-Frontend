import 'package:flutter/material.dart';

/// Background variants for different screen types
enum BackgroundVariant {
  standard,
  home,
  chats,
  shop,
  media,
  discover,
  settings,
}

/// Modern gradient background widget with vibrant purple theme
class AppBackground extends StatelessWidget {
  final Widget child;
  final BackgroundVariant variant;

  const AppBackground({
    super.key,
    required this.child,
    this.variant = BackgroundVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getBackgroundDecoration(variant),
      child: child,
    );
  }

  BoxDecoration _getBackgroundDecoration(BackgroundVariant variant) {
    switch (variant) {
      case BackgroundVariant.home:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0B2E), // Very dark purple
              Color(0xFF1A0F3A), // Dark purple
              Color(0xFF2D1B4E), // Medium dark purple
              Color(0xFF1A0F3A), // Dark purple
              Color(0xFF0F0B2E), // Very dark purple
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        );
      
      case BackgroundVariant.chats:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0B2E), // Very dark purple
              Color(0xFF1A0F3A), // Dark purple
              Color(0xFF0F0B2E), // Very dark purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        );
      
      case BackgroundVariant.discover:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0F3A), // Dark purple
              Color(0xFF2D1B4E), // Medium dark purple
              Color(0xFF0F0B2E), // Very dark purple
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        );
      
      default:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0B2E), // Very dark purple
              Color(0xFF1A0F3A), // Dark purple
              Color(0xFF0F0B2E), // Very dark purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        );
    }
  }
}
