import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/chatify_purple_logo.png',
        fit: BoxFit.contain,
        colorBlendMode: BlendMode.dstOver, // Ensures transparency is preserved
        errorBuilder: (context, error, stackTrace) {
          // Fallback to alternate logo if primary is missing
          return Image.asset(
            'assets/images/Chatify_logo.png',
            fit: BoxFit.contain,
            colorBlendMode: BlendMode.dstOver,
            errorBuilder: (context, error, stackTrace) {
              // Final fallback: branded icon
              return Icon(
                Icons.chat_bubble_outline,
                size: size * 0.6,
                color: Theme.of(context).colorScheme.onPrimary,
              );
            },
          );
        },
      ),
    );
  }
}
