import 'package:flutter/material.dart';
import 'gradient_button.dart';

/// Animated button with subtle micro-interactions
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool isLoading;
  final bool isEnabled;
  final Duration animationDuration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.isLoading = false,
    this.isEnabled = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: -2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _elevationAnimation.value),
              child: GradientButton(
                onPressed: null, // Handled by GestureDetector
                padding: widget.padding,
                borderRadius: widget.borderRadius,
                gradient: widget.gradient,
                backgroundColor: widget.backgroundColor,
                foregroundColor: widget.foregroundColor,
                elevation: widget.elevation,
                isLoading: widget.isLoading,
                isEnabled: widget.isEnabled,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated card with hover and press effects
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool useGradient;
  final Gradient? gradient;
  final Duration animationDuration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.useGradient = false,
    this.gradient,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: -4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _elevationAnimation.value),
              child: Container(
                margin: widget.margin,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  gradient: widget.useGradient ? widget.gradient : null,
                  borderRadius: widget.borderRadius,
                  boxShadow: widget.boxShadow,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated profile avatar with subtle scale effect
class AnimatedProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? displayName;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool useGradient;
  final Gradient? gradient;
  final Duration animationDuration;

  const AnimatedProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.size = 60,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 3,
    this.useGradient = false,
    this.gradient,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<AnimatedProfileAvatar> createState() => _AnimatedProfileAvatarState();
}

class _AnimatedProfileAvatarState extends State<AnimatedProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.useGradient ? null : widget.backgroundColor,
                gradient: widget.useGradient ? widget.gradient : null,
                borderRadius: BorderRadius.circular(widget.size / 2),
                border: Border.all(
                  color: widget.borderColor ?? Theme.of(context).colorScheme.primary,
                  width: widget.borderWidth,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                      )
                    : _buildFallbackAvatar(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade300,
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: widget.size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
