import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme_extensions.dart';

/// A shimmer loading skeleton widget that can be used for lists and cards
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool primary;

  const SkeletonList({
    super.key,
    this.itemCount = 3,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      primary: primary,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// A skeleton item that shows a shimmer effect
class SkeletonItem extends StatefulWidget {
  final double height;
  final double? width;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? shimmerColor;

  const SkeletonItem({
    super.key,
    this.height = 80,
    this.width,
    this.margin,
    this.borderRadius,
    this.color,
    this.shimmerColor,
  });

  @override
  State<SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(tokens?.radiusMedium ?? 16),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.color ?? theme.colorScheme.surface,
                widget.shimmerColor ??
                    theme.colorScheme.surface.withOpacity(0.6),
                widget.color ?? theme.colorScheme.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Predefined skeleton layouts for common use cases
class SkeletonLayouts {
  /// Chat list item skeleton
  static Widget chatItem({
    double height = 80,
    EdgeInsets? margin,
  }) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Avatar skeleton
          SkeletonItem(
            height: 56,
            width: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          const SizedBox(width: 16),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Name skeleton
                SkeletonItem(
                  height: 16,
                  width: 120,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                // Message preview skeleton
                SkeletonItem(
                  height: 14,
                  width: 200,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Time skeleton
          SkeletonItem(
            height: 12,
            width: 40,
          ),
        ],
      ),
    );
  }

  /// Profile card skeleton
  static Widget profileCard({
    double height = 120,
    EdgeInsets? margin,
  }) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header with avatar and name
          Row(
            children: [
              SkeletonItem(
                height: 48,
                width: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonItem(
                      height: 18,
                      width: 140,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    SkeletonItem(
                      height: 14,
                      width: 100,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio skeleton
          SkeletonItem(
            height: 16,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          SkeletonItem(
            height: 16,
            width: 200,
          ),
        ],
      ),
    );
  }

  /// Search result skeleton
  static Widget searchResult({
    double height = 60,
    EdgeInsets? margin,
  }) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SkeletonItem(
            height: 40,
            width: 40,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonItem(
                  height: 16,
                  width: 150,
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                SkeletonItem(
                  height: 12,
                  width: 100,
                ),
              ],
            ),
          ),
          SkeletonItem(
            height: 32,
            width: 80,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  /// Grid item skeleton
  static Widget gridItem({
    double size = 120,
    EdgeInsets? margin,
  }) {
    return Container(
      width: size,
      height: size,
      margin: margin ?? const EdgeInsets.all(8),
      child: Column(
        children: [
          SkeletonItem(
            height: size * 0.7,
            width: size,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          SkeletonItem(
            height: 16,
            width: size * 0.8,
          ),
        ],
      ),
    );
  }
}

/// A simple shimmer text skeleton
class SkeletonText extends StatelessWidget {
  final double height;
  final double? width;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const SkeletonText({
    super.key,
    this.height = 16,
    this.width,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonItem(
      height: height,
      width: width,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
    );
  }
}
