import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced background with subtle animated elements
class EnhancedBackground extends StatefulWidget {
  final Widget child;
  final BackgroundVariant variant;
  final bool enableAnimation;

  const EnhancedBackground({
    super.key,
    required this.child,
    this.variant = BackgroundVariant.standard,
    this.enableAnimation = true,
  });

  @override
  State<EnhancedBackground> createState() => _EnhancedBackgroundState();
}

class _EnhancedBackgroundState extends State<EnhancedBackground>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableAnimation) {
      _pulseController.repeat(reverse: true);
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getBackgroundDecoration(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated gradient overlay
          if (widget.enableAnimation)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.3 + _floatAnimation.value,
                        -0.2 + _floatAnimation.value * 0.5,
                      ),
                      radius: _pulseAnimation.value,
                      colors: [
                        const Color(0xFF2D1B4E).withOpacity(0.15),
                        const Color(0xFF1A0F3A).withOpacity(0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                );
              },
            ),
          
          // Subtle floating particles
          if (widget.enableAnimation)
            ...List.generate(3, (index) => _buildFloatingParticle(index)),
          
          // Main content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = _floatAnimation.value * (index + 1) * 0.3;
        return Positioned(
          left: 50 + (index * 100) + offset * 20,
          top: 100 + (index * 150) + offset * 30,
          child: Container(
            width: 4 + (index * 2),
            height: 4 + (index * 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B4E).withOpacity(0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D1B4E).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    switch (widget.variant) {
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
