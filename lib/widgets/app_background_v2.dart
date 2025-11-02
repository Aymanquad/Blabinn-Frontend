import 'package:flutter/material.dart';

/// Background variants for different screen types in V2
enum BackgroundV2Variant {
  standard,
  homeHero,
  chat,
  shop,
  media,
  settings,
}

/// V2 Background widget with roxo image and subtle radial overlays
/// This replaces the neon-heavy V1 background with a more subtle, elegant design using the roxo wallpaper
class AppBackgroundV2 extends StatelessWidget {
  final Widget child;
  final BackgroundV2Variant variant;

  const AppBackgroundV2({
    super.key,
    required this.child,
    this.variant = BackgroundV2Variant.standard,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base roxo image background
        _buildBaseBackground(),

        // 2. Subtle radial gradient overlays
        _buildRadialOverlays(),

        // 3. Optional vignette for depth
        _buildVignette(),

        // 4. Child content
        child,
      ],
    );
  }

  /// Base roxo image background with proper fit
  Widget _buildBaseBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/wallpaper roxo.jpeg',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to solid gradient if image fails to load
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3C1E75), // Purple core
                  Color(0xFF0B0F15), // Deep black
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Subtle radial gradient overlays positioned based on variant
  Widget _buildRadialOverlays() {
    final overlayConfig = _getOverlayConfig();

    return Positioned.fill(
      child: CustomPaint(
        painter: RadialOverlayPainter(
          overlays: overlayConfig,
        ),
      ),
    );
  }

  /// Very soft vignette to darken extreme edges
  Widget _buildVignette() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.05),
              Colors.black.withOpacity(0.08),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  /// Get overlay configuration based on variant
  List<RadialOverlay> _getOverlayConfig() {
    switch (variant) {
      case BackgroundV2Variant.homeHero:
        return [
          RadialOverlay(
            center: const Alignment(-0.7, -0.7),
            radius: 0.8,
            color: const Color(0x803C1E75), // ~50% alpha purple
          ),
          RadialOverlay(
            center: const Alignment(0.6, 0.5),
            radius: 0.6,
            color: const Color(0x605A2EA6), // ~37% alpha purple-mid
          ),
        ];
      case BackgroundV2Variant.chat:
        return [
          RadialOverlay(
            center: const Alignment(-0.5, -0.3),
            radius: 0.7,
            color: const Color(0x603C1E75), // ~37% alpha purple
          ),
          RadialOverlay(
            center: const Alignment(0.7, 0.8),
            radius: 0.5,
            color: const Color(0x405A2EA6), // ~25% alpha purple-mid
          ),
        ];
      case BackgroundV2Variant.shop:
        return [
          RadialOverlay(
            center: const Alignment(-0.6, -0.6),
            radius: 0.8,
            color: const Color(0x703C1E75), // ~44% alpha purple
          ),
          RadialOverlay(
            center: const Alignment(0.4, 0.3),
            radius: 0.6,
            color: const Color(0x505A2EA6), // ~31% alpha purple-mid
          ),
        ];
      case BackgroundV2Variant.media:
        return [
          RadialOverlay(
            center: const Alignment(0.5, -0.8),
            radius: 0.7,
            color: const Color(0x603C1E75), // ~37% alpha purple
          ),
          RadialOverlay(
            center: const Alignment(-0.4, 0.6),
            radius: 0.6,
            color: const Color(0x405A2EA6), // ~25% alpha purple-mid
          ),
        ];
      case BackgroundV2Variant.settings:
        return [
          RadialOverlay(
            center: const Alignment(-0.4, -0.4),
            radius: 0.6,
            color: const Color(0x503C1E75), // ~31% alpha purple
          ),
          RadialOverlay(
            center: const Alignment(0.5, 0.5),
            radius: 0.5,
            color: const Color(0x305A2EA6), // ~19% alpha purple-mid
          ),
        ];
      case BackgroundV2Variant.standard:
        return [
          RadialOverlay(
            center: const Alignment(-0.5, -0.5),
            radius: 0.7,
            color: const Color(0x603C1E75), // ~37% alpha purple
          ),
          RadialOverlay(
            center: const Alignment(0.6, 0.4),
            radius: 0.6,
            color: const Color(0x405A2EA6), // ~25% alpha purple-mid
          ),
          RadialOverlay(
            center: const Alignment(0.2, -0.7),
            radius: 0.4,
            color: const Color(0x303C1E75), // ~19% alpha purple
          ),
        ];
    }
  }
}

/// Configuration for radial overlay effects
class RadialOverlay {
  final Alignment center;
  final double radius;
  final Color color;

  const RadialOverlay({
    required this.center,
    required this.radius,
    required this.color,
  });
}

/// Custom painter for radial overlay effects
class RadialOverlayPainter extends CustomPainter {
  final List<RadialOverlay> overlays;

  RadialOverlayPainter({
    required this.overlays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final overlay in overlays) {
      final center = overlay.center.alongSize(size);
      final radius = overlay.radius * size.width; // Scale by screen width

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            overlay.color,
            overlay.color.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: center,
          radius: radius,
        ));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RadialOverlayPainter oldDelegate) {
    return oldDelegate.overlays != overlays;
  }
}
