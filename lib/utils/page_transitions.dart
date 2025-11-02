import 'package:flutter/material.dart';

/// Collection of modern page transition animations
class PageTransitions {
  /// Creates an iPhone-style slide from bottom transition
  static Route<T> slideFromBottom<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from bottom animation
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Scale animation for the underlying page
        final scaleAnimation = Tween(
          begin: 1.0,
          end: 0.95,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        // Fade animation for overlay effect
        final fadeAnimation = Tween(
          begin: 0.0,
          end: 0.3,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        ));

        return Stack(
          children: [
            // Background page with scale effect
            Transform.scale(
              scale: scaleAnimation.value,
              child: Container(
                color: Colors.black.withValues(alpha: fadeAnimation.value),
              ),
            ),
            // Sliding page
            SlideTransition(
              position: slideAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Creates an iOS-style modal presentation
  static Route<T> modalPresentation<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: false,
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from bottom with rounded corners
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

        // Background scale and fade
        final backgroundScale = Tween(
          begin: 1.0,
          end: 0.92,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        final backgroundFade = Tween(
          begin: 0.0,
          end: 0.4,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Stack(
              children: [
                // Dimmed background
                Container(
                  color: Colors.black.withValues(alpha: backgroundFade.value),
                ),
                // Background page with scale effect
                Transform.scale(
                  scale: backgroundScale.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * animation.value),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),
                // Modal page sliding from bottom
                SlideTransition(
                  position: slideAnimation,
                  child: Container(
                    margin: EdgeInsets.only(
                      top: 20 * animation.value,
                    ),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: child,
        );
      },
    );
  }

  /// Creates a modern slide from bottom to top transition
  static Route<T> slideFromBottomToTop<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from bottom animation
        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero; // End at center
        const curve = Curves.easeOutCubic;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// Creates a modern slide from right transition (like iOS push)
  static Route<T> modernSlide<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from right animation
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Previous page slides out to the left
        final slideOutAnimation = Tween(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        return Stack(
          children: [
            // Previous page sliding out
            SlideTransition(
              position: slideOutAnimation,
              child: Container(),
            ),
            // New page sliding in
            SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Creates a smooth fade transition
  static Route<T> fade<T extends Object?>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Creates a modern scale transition with fade
  static Route<T> scaleWithFade<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween(
          begin: 0.85,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

        final fadeAnimation = Tween(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
