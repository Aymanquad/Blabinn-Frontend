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

/// Global background widget that provides purple aurora background
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
    final String base = switch (variant) {
      BackgroundVariant.home => 'assets/images/wallpaper roxo.jpeg',
      BackgroundVariant.shop => 'assets/images/violettoblack_bg.png',
      BackgroundVariant.media => 'assets/images/violettoblack_bg.png',
      BackgroundVariant.discover => 'assets/images/wallpaper roxo.jpeg',
      BackgroundVariant.chats => 'assets/images/wallpaper roxo.jpeg',
      BackgroundVariant.settings => 'assets/images/wallpaper roxo.jpeg',
      _ => 'assets/images/wallpaper roxo.jpeg',
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base image background
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(base),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Subtle radial depth overlay
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.1, -0.2),
                radius: 1.0,
                colors: [Color(0x803C1E75), Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Child content
        child,
      ],
    );
  }
}
