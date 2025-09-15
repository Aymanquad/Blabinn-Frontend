import 'package:flutter/material.dart';
import '../core/theme_extensions.dart';

/// Modern card widget with enhanced styling and purple theme
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool useGradient;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.useGradient = false,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    final cardBorderRadius = borderRadius ?? BorderRadius.circular(tokens?.radiusMedium ?? 20);
    final cardPadding = padding ?? tokens?.spacingMedium ?? const EdgeInsets.all(16);
    final cardMargin = margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    Widget cardContent = Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        gradient: useGradient ? (gradient ?? tokens?.primaryGradient) : null,
        borderRadius: cardBorderRadius,
        boxShadow: boxShadow ?? tokens?.softShadows,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: cardContent,
      );
    }

    return Container(
      margin: cardMargin,
      child: cardContent,
    );
  }
}

/// Modern elevated card with gradient background
class ModernElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const ModernElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();

    return ModernCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      useGradient: true,
      gradient: gradient ?? tokens?.primaryGradient,
      boxShadow: tokens?.macroShadows,
      child: child,
    );
  }
}

/// Modern profile card with enhanced styling
class ModernProfileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isSelected;

  const ModernProfileCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();

    return ModernCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      backgroundColor: isSelected 
          ? theme.colorScheme.primary.withOpacity(0.1)
          : theme.colorScheme.surface,
      boxShadow: isSelected ? tokens?.macroShadows : tokens?.softShadows,
      child: child,
    );
  }
}

/// Modern button card with enhanced styling
class ModernButtonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isEnabled;
  final Color? backgroundColor;

  const ModernButtonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.isEnabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();

    return ModernCard(
      padding: padding,
      margin: margin,
      onTap: isEnabled ? onTap : null,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      boxShadow: tokens?.microShadows,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: child,
      ),
    );
  }
}
