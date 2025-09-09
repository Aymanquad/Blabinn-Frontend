import 'package:flutter/material.dart';

enum OverlayVariant { standard, home, chats, shop, media, discover, settings }

class AppBackgroundOverlay extends StatelessWidget {
  final Widget child;
  final OverlayVariant variant;
  final Alignment? glowCenter;
  final double? glowRadius;

  const AppBackgroundOverlay({
    super.key,
    required this.child,
    this.variant = OverlayVariant.standard,
    this.glowCenter,
    this.glowRadius,
  });

  // Tuned colors to match a soft violet glow on a deep base
  static const _deepBlack = Color(0xFF0A0D12);
  static const _deepViolet = Color(0xFF151126);
  static const _purpleCore = Color(0xFF6D36F4); // core purple
  static const _purpleHalo = Color(0xFF9B6BFF); // softer halo

  Alignment _variantCenter(OverlayVariant v) {
    switch (v) {
      case OverlayVariant.home:
        return const Alignment(-0.75, -0.65); // top-left
      case OverlayVariant.shop:
        return const Alignment(0.55, -0.35); // upper-right
      case OverlayVariant.media:
        return const Alignment(0.25, 0.65); // bottom-right
      case OverlayVariant.chats:
        return const Alignment(-0.55, -0.15); // left/upper-left
      case OverlayVariant.discover:
        return const Alignment(0.0, -0.6); // top-center
      case OverlayVariant.settings:
        return const Alignment(-0.25, 0.55); // lower-left
      case OverlayVariant.standard:
      default:
        return const Alignment(-0.6, -0.5); // default: top-leftish
    }
  }

  double _variantRadius(OverlayVariant v) {
    switch (v) {
      case OverlayVariant.home:
        return 1.20;
      case OverlayVariant.shop:
        return 1.05;
      case OverlayVariant.media:
        return 1.25;
      case OverlayVariant.chats:
        return 1.10;
      case OverlayVariant.discover:
        return 1.15;
      case OverlayVariant.settings:
        return 1.20;
      case OverlayVariant.standard:
      default:
        return 1.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = glowCenter ?? _variantCenter(variant);
    final radius = glowRadius ?? _variantRadius(variant);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: very dark diagonal wash (black -> deep violet)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [_deepBlack, _deepViolet],
              stops: [0.0, 1.0],
            ),
          ),
        ),

        // Spotlight glow: big soft radial violet, fading to transparent
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: radius,
                colors: [
                  _purpleCore.withOpacity(0.55),
                  _purpleHalo.withOpacity(0.22),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Optional subtle edge vignette to keep text readable
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.transparent,
                  Colors.black.withOpacity(0.12),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Your page content
        child,
      ],
    );
  }
}

