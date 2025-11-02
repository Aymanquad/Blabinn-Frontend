import 'package:flutter/material.dart';
import '../core/theme_extensions.dart';

/// Modern gradient button with enhanced styling
class GradientButton extends StatelessWidget {
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

  const GradientButton({
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    final buttonBorderRadius = BorderRadius.circular(borderRadius ?? tokens?.radiusMedium ?? 20);
    final buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final buttonGradient = gradient ?? tokens?.primaryGradient;
    final buttonElevation = elevation ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled ? buttonGradient : null,
        color: isEnabled ? null : theme.colorScheme.surfaceVariant,
        borderRadius: buttonBorderRadius,
        boxShadow: isEnabled ? tokens?.softShadows : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: buttonBorderRadius,
          child: Container(
            padding: buttonPadding,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          foregroundColor ?? Colors.white,
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: TextStyle(
                        color: foregroundColor ?? Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern outlined gradient button
class GradientOutlinedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double borderWidth;
  final bool isLoading;
  final bool isEnabled;

  const GradientOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.borderWidth = 2.0,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    final buttonBorderRadius = BorderRadius.circular(borderRadius ?? tokens?.radiusMedium ?? 20);
    final buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final buttonGradient = gradient ?? tokens?.primaryGradient;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: buttonBorderRadius,
        border: Border.all(
          color: isEnabled 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: borderWidth,
        ),
        boxShadow: tokens?.microShadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: buttonBorderRadius,
          child: Container(
            padding: buttonPadding,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: TextStyle(
                        color: isEnabled 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern icon button with gradient
class GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isLoading;
  final bool isEnabled;

  const GradientIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.iconColor,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    final buttonSize = size ?? 48;
    final buttonBorderRadius = BorderRadius.circular(borderRadius ?? tokens?.radiusSmall ?? 12);
    final buttonGradient = gradient ?? tokens?.primaryGradient;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: isEnabled ? buttonGradient : null,
        color: isEnabled ? null : theme.colorScheme.surfaceVariant,
        borderRadius: buttonBorderRadius,
        boxShadow: isEnabled ? tokens?.microShadows : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: buttonBorderRadius,
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        iconColor ?? Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
