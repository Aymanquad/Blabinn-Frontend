import 'package:flutter/material.dart';
import '../core/theme_extensions.dart';

/// A performance-friendly glass container that uses theme tokens
/// instead of heavy BackdropFilter for better performance.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Color? tintColor;
  final bool useSurfaceTint;
  final bool useGlassTint;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.shadows,
    this.tintColor,
    this.useSurfaceTint = true,
    this.useGlassTint = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    if (tokens == null) {
      // Fallback to basic container if tokens not available
      return Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: child,
      );
    }

    // Use theme tokens for optimal performance
    Color effectiveTint = tintColor ?? Colors.transparent;
    if (useSurfaceTint) {
      effectiveTint = Color.lerp(
        effectiveTint,
        tokens.surfaceTint,
        0.3,
      )!;
    }
    if (useGlassTint) {
      effectiveTint = Color.lerp(
        effectiveTint,
        tokens.glassTint,
        0.2,
      )!;
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveTint,
        borderRadius: borderRadius ?? BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: shadows ?? tokens.microShadows,
      ),
      child: child,
    );
  }
}

/// A specialized glass card with consistent styling
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    if (tokens == null) {
      return Card(
        margin: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? tokens?.spacingMedium ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: elevated ? tokens.surfaceTint : tokens.glassTint,
        borderRadius: borderRadius ?? BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: elevated ? tokens.softShadows : tokens.microShadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(tokens.radiusMedium),
          child: Padding(
            padding: padding ?? tokens.spacingMedium,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A glass surface for elevated content areas
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool useMacroShadows;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.useMacroShadows = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    if (tokens == null) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: tokens.surfaceTint,
        borderRadius: borderRadius ?? BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: useMacroShadows ? tokens.macroShadows : tokens.softShadows,
      ),
      child: child,
    );
  }
}
