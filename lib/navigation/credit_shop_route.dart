import 'package:flutter/material.dart';

/// iOS-style slide transition route for Credit Shop
/// Opens: page slides from top → down (enter from above)
/// Closes: page slides from bottom → up (exit upward)
class CreditShopRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  CreditShopRoute({required this.builder})
      : super(
          opaque: true,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // PUSH: top -> down (enter from above)
            final inTween = Tween<Offset>(
              begin: const Offset(0, -1), // Start from top
              end: Offset.zero, // End at center
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            // POP will automatically reverse (bottom -> up) due to reverseAnimation
            final slide = SlideTransition(
              position: animation.drive(inTween),
              child: child,
            );

            // Ensure opaque background with no transparency
            return DecoratedBox(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: slide,
            );
          },
          maintainState: true,
        );
}
