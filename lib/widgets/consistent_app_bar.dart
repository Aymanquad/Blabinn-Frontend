import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme_extensions.dart';

/// A consistent AppBar widget that follows our design system
/// and provides unified styling across all screens.
class ConsistentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final bool useGlassEffect;

  const ConsistentAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
    this.useGlassEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final theme = Theme.of(context);
    
    // Determine colors based on context and preferences
    final effectiveBackgroundColor = backgroundColor ?? 
        (useGlassEffect ? Colors.transparent : AppColors.background);
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: effectiveForegroundColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      bottom: bottom,
      
      // Leading widget (back button or custom)
      leading: leading ?? _buildLeadingWidget(context, effectiveForegroundColor),
      
      // Actions
      actions: actions ?? _buildDefaultActions(context, effectiveForegroundColor),
      
      // Flexible space for glass effect
      flexibleSpace: useGlassEffect ? _buildGlassEffect(tokens) : null,
      
      // Shape and styling
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(BuildContext context, Color foregroundColor) {
    if (!showBackButton) return const SizedBox.shrink();
    
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_rounded,
        color: foregroundColor,
        size: 24,
      ),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      tooltip: 'Go back',
      style: IconButton.styleFrom(
        backgroundColor: foregroundColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context, Color foregroundColor) {
    return [
      // Add default actions here if needed
      // For example: notifications, settings, etc.
    ];
  }

  Widget? _buildGlassEffect(AppThemeTokens? tokens) {
    if (!useGlassEffect) return null;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: tokens?.microShadows ?? [],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// A specialized AppBar for screens that need a gradient background
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Gradient? gradient;
  final Color? foregroundColor;
  final double? elevation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.gradient,
    this.foregroundColor,
    this.elevation = 0,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final theme = Theme.of(context);
    final effectiveGradient = gradient ?? tokens?.primaryGradient;
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: effectiveForegroundColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      bottom: bottom,
      
      // Leading widget
      leading: leading ?? _buildLeadingWidget(context, effectiveForegroundColor),
      
      // Actions
      actions: actions,
      
      // Gradient background
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      
      // Shape
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(BuildContext context, Color foregroundColor) {
    if (!showBackButton) return const SizedBox.shrink();
    
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_rounded,
        color: foregroundColor,
        size: 24,
      ),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      tooltip: 'Go back',
      style: IconButton.styleFrom(
        backgroundColor: foregroundColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// A specialized AppBar for settings and configuration screens
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final VoidCallback? onBackPressed;

  const SettingsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: true,
      backgroundColor: AppColors.cardBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      
      // Leading widget
      leading: leading ?? IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 24,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Go back',
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Actions
      actions: actions,
      
      // Shape
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
