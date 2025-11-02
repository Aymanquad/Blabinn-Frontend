import 'package:flutter/material.dart';
import 'tokens.dart';

/// Extension methods to easily access theme extensions
extension ThemeExtensions on BuildContext {
  /// Access brand colors from theme
  BrandColors get brandColors => Theme.of(this).extension<BrandColors>()!;

  /// Access brand spacing from theme
  BrandSpacing get brandSpacing => Theme.of(this).extension<BrandSpacing>()!;

  /// Access brand radii from theme
  BrandRadii get brandRadii => Theme.of(this).extension<BrandRadii>()!;

  /// Access brand shadows from theme
  BrandShadows get brandShadows => Theme.of(this).extension<BrandShadows>()!;

  /// Access background tokens from theme
  BackgroundTokensExtension get backgroundTokens =>
      Theme.of(this).extension<BackgroundTokensExtension>()!;
}

/// Extension methods for common theme access
extension MaterialThemeExtensions on BuildContext {
  /// Quick access to color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to theme data
  ThemeData get theme => Theme.of(this);

  /// V2 Semantic color helpers - Neon Night theme
  Color get chatOutgoingColor => colorScheme.primary; // Magenta
  Color get chatIncomingColor => colorScheme.surfaceVariant;
  Color get chatOutgoingTextColor => colorScheme.onPrimary;
  Color get chatIncomingTextColor =>
      colorScheme.onSurface.withOpacity(0.9); // 90% opacity
  Color get timestampColor =>
      colorScheme.onSurface.withOpacity(0.65); // 65% opacity
  Color get unreadBadgeColor => brandColors.accent; // Lime
  Color get presenceOnlineColor => const Color(0xFF7CFF4F); // Lime for online
  Color get presenceOfflineColor => const Color(0xFF93A4BE);

  /// V2 System message colors
  Color get systemMessageColor =>
      colorScheme.onSurface.withOpacity(0.8); // 80% opacity
  Color get reactionPillColor => colorScheme.surfaceVariant;
  Color get reactionIconColor => colorScheme.secondary; // Cyan tint
}

/// Helper methods for creating consistent UI components
extension BrandColorHelpers on BrandColors {
  /// Get appropriate text color for given background
  Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? onSurface : surface;
  }

  /// Get success color with opacity
  Color get successWithOpacity => success.withOpacity(0.12);

  /// Get warning color with opacity
  Color get warningWithOpacity => warning.withOpacity(0.12);

  /// Get error color with opacity
  Color get errorWithOpacity => error.withOpacity(0.12);
}

/// Helper methods for spacing
extension BrandSpacingHelpers on BrandSpacing {
  /// Get horizontal padding
  EdgeInsets get horizontalSm =>
      EdgeInsets.symmetric(horizontal: BrandTokens.spaceSm);
  EdgeInsets get horizontalMd =>
      EdgeInsets.symmetric(horizontal: BrandTokens.spaceMd);
  EdgeInsets get horizontalLg =>
      EdgeInsets.symmetric(horizontal: BrandTokens.spaceLg);
  EdgeInsets get horizontalXl =>
      EdgeInsets.symmetric(horizontal: BrandTokens.spaceXl);

  /// Get vertical padding
  EdgeInsets get verticalSm =>
      EdgeInsets.symmetric(vertical: BrandTokens.spaceSm);
  EdgeInsets get verticalMd =>
      EdgeInsets.symmetric(vertical: BrandTokens.spaceMd);
  EdgeInsets get verticalLg =>
      EdgeInsets.symmetric(vertical: BrandTokens.spaceLg);
  EdgeInsets get verticalXl =>
      EdgeInsets.symmetric(vertical: BrandTokens.spaceXl);
}

/// Helper methods for creating consistent decorations
extension DecorationHelpers on BuildContext {
  /// Create a card decoration with brand styling
  BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? brandColors.surface,
      borderRadius: borderRadius ?? brandRadii.md,
      boxShadow: shadows ?? brandShadows.level1,
    );
  }

  /// Create a chat bubble decoration with V2 neon glow effect
  BoxDecoration chatBubbleDecoration({
    required bool isOutgoing,
    BorderRadius? borderRadius,
    bool withGlow = false,
  }) {
    return BoxDecoration(
      color: isOutgoing ? colorScheme.primary : colorScheme.surfaceVariant,
      borderRadius: borderRadius ?? brandRadii.md, // md for chat bubbles
      boxShadow: withGlow && isOutgoing
          ? [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
              ...brandShadows.level1,
            ]
          : brandShadows.level1,
    );
  }

  /// Create an unread badge decoration with Lime accent
  BoxDecoration unreadBadgeDecoration({
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: unreadBadgeColor, // Lime
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: unreadBadgeColor.withOpacity(0.4),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Create a system message chip decoration
  BoxDecoration systemMessageDecoration({
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: colorScheme.surfaceVariant,
      borderRadius: borderRadius ?? brandRadii.xl,
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.3),
        width: 0.5,
      ),
    );
  }

  /// Create an input decoration with brand styling
  BoxDecoration inputDecoration({
    Color? color,
    Color? borderColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? brandColors.surfaceVariant,
      borderRadius: borderRadius ?? brandRadii.sm,
      border: borderColor != null ? Border.all(color: borderColor) : null,
    );
  }

  /// Create a button decoration with brand styling
  BoxDecoration buttonDecoration({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? brandColors.primary,
      borderRadius: borderRadius ?? brandRadii.md,
      boxShadow: shadows ?? brandShadows.level2,
    );
  }
}
