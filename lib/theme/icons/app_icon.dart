import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../extensions.dart';

/// Centralized icon system for the app using Phosphor icons
/// Maps semantic names to specific icons with consistent sizing and theming
class AppIcon extends StatelessWidget {
  /// The semantic kind of icon to display
  final AppIconKind kind;

  /// Size of the icon
  final AppIconSize size;

  /// Color override (if null, uses theme-appropriate color)
  final Color? color;

  /// Weight/stroke of the icon
  final AppIconWeight weight;

  /// Semantic label for accessibility
  final String? semanticLabel;

  const AppIcon({
    super.key,
    required this.kind,
    this.size = AppIconSize.md,
    this.color,
    this.weight = AppIconWeight.regular,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData();
    final iconSize = _getSize();
    final iconColor = color ?? _getThemeColor(context);

    return Icon(
      iconData,
      size: iconSize,
      color: iconColor,
      semanticLabel: semanticLabel ?? kind.name,
    );
  }

  /// Get the appropriate Phosphor icon for the semantic kind
  IconData _getIconData() {
    final isRegular = weight == AppIconWeight.regular;

    switch (kind) {
      // Communication
      case AppIconKind.chat:
        return isRegular
            ? PhosphorIcons.chatCircle()
            : PhosphorIcons.chatCircle(PhosphorIconsStyle.fill);
      case AppIconKind.send:
        return isRegular
            ? PhosphorIcons.paperPlaneRight()
            : PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill);
      case AppIconKind.call:
        return isRegular
            ? PhosphorIcons.phone()
            : PhosphorIcons.phone(PhosphorIconsStyle.fill);
      case AppIconKind.video:
        return isRegular
            ? PhosphorIcons.videoCamera()
            : PhosphorIcons.videoCamera(PhosphorIconsStyle.fill);
      case AppIconKind.mic:
        return isRegular
            ? PhosphorIcons.microphone()
            : PhosphorIcons.microphone(PhosphorIconsStyle.fill);
      case AppIconKind.micOff:
        return isRegular
            ? PhosphorIcons.microphoneSlash()
            : PhosphorIcons.microphoneSlash(PhosphorIconsStyle.fill);

      // Media & Attachments
      case AppIconKind.attach:
        return isRegular
            ? PhosphorIcons.paperclip()
            : PhosphorIcons.paperclip(PhosphorIconsStyle.fill);
      case AppIconKind.camera:
        return isRegular
            ? PhosphorIcons.camera()
            : PhosphorIcons.camera(PhosphorIconsStyle.fill);
      case AppIconKind.image:
        return isRegular
            ? PhosphorIcons.image()
            : PhosphorIcons.image(PhosphorIconsStyle.fill);
      case AppIconKind.file:
        return isRegular
            ? PhosphorIcons.file()
            : PhosphorIcons.file(PhosphorIconsStyle.fill);
      case AppIconKind.download:
        return isRegular
            ? PhosphorIcons.downloadSimple()
            : PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill);
      case AppIconKind.play:
        return isRegular
            ? PhosphorIcons.play()
            : PhosphorIcons.play(PhosphorIconsStyle.fill);
      case AppIconKind.pause:
        return isRegular
            ? PhosphorIcons.pause()
            : PhosphorIcons.pause(PhosphorIconsStyle.fill);

      // Navigation
      case AppIconKind.back:
        return PhosphorIcons.arrowLeft();
      case AppIconKind.forward:
        return PhosphorIcons.arrowRight();
      case AppIconKind.up:
        return PhosphorIcons.arrowUp();
      case AppIconKind.down:
        return PhosphorIcons.arrowDown();
      case AppIconKind.close:
        return PhosphorIcons.x();
      case AppIconKind.menu:
        return PhosphorIcons.list();

      // Main Navigation
      case AppIconKind.home:
        return isRegular
            ? PhosphorIcons.house()
            : PhosphorIcons.house(PhosphorIconsStyle.fill);
      case AppIconKind.chats:
        return isRegular
            ? PhosphorIcons.chatTeardrop()
            : PhosphorIcons.chatTeardrop(PhosphorIconsStyle.fill);
      case AppIconKind.contacts:
        return isRegular
            ? PhosphorIcons.users()
            : PhosphorIcons.users(PhosphorIconsStyle.fill);
      case AppIconKind.calls:
        return isRegular
            ? PhosphorIcons.phone()
            : PhosphorIcons.phone(PhosphorIconsStyle.fill);
      case AppIconKind.settings:
        return isRegular
            ? PhosphorIcons.gear()
            : PhosphorIcons.gear(PhosphorIconsStyle.fill);

      // User Actions
      case AppIconKind.search:
        return PhosphorIcons.magnifyingGlass();
      case AppIconKind.add:
        return PhosphorIcons.plus();
      case AppIconKind.addFriend:
        return PhosphorIcons.userPlus();
      case AppIconKind.edit:
        return PhosphorIcons.pencilSimple();
      case AppIconKind.delete:
        return PhosphorIcons.trash();
      case AppIconKind.block:
        return PhosphorIcons.prohibit();
      case AppIconKind.report:
        return PhosphorIcons.flag();

      // Status & Feedback
      case AppIconKind.bell:
        return isRegular
            ? PhosphorIcons.bell()
            : PhosphorIcons.bell(PhosphorIconsStyle.fill);
      case AppIconKind.bellOff:
        return isRegular
            ? PhosphorIcons.bellSlash()
            : PhosphorIcons.bellSlash(PhosphorIconsStyle.fill);
      case AppIconKind.star:
        return isRegular
            ? PhosphorIcons.star()
            : PhosphorIcons.star(PhosphorIconsStyle.fill);
      case AppIconKind.heart:
        return isRegular
            ? PhosphorIcons.heart()
            : PhosphorIcons.heart(PhosphorIconsStyle.fill);
      case AppIconKind.thumbsUp:
        return isRegular
            ? PhosphorIcons.thumbsUp()
            : PhosphorIcons.thumbsUp(PhosphorIconsStyle.fill);
      case AppIconKind.check:
        return PhosphorIcons.check();
      case AppIconKind.checkDouble:
        return PhosphorIcons.checks();
      case AppIconKind.error:
        return PhosphorIcons.warning();
      case AppIconKind.info:
        return PhosphorIcons.info();

      // Profile & Account
      case AppIconKind.user:
        return isRegular
            ? PhosphorIcons.user()
            : PhosphorIcons.user(PhosphorIconsStyle.fill);
      case AppIconKind.profile:
        return isRegular
            ? PhosphorIcons.userCircle()
            : PhosphorIcons.userCircle(PhosphorIconsStyle.fill);
      case AppIconKind.logout:
        return PhosphorIcons.signOut();
      case AppIconKind.lock:
        return isRegular
            ? PhosphorIcons.lock()
            : PhosphorIcons.lock(PhosphorIconsStyle.fill);
      case AppIconKind.unlock:
        return isRegular
            ? PhosphorIcons.lockOpen()
            : PhosphorIcons.lockOpen(PhosphorIconsStyle.fill);

      // Interface
      case AppIconKind.more:
        return PhosphorIcons.dotsThreeVertical();
      case AppIconKind.moreHorizontal:
        return PhosphorIcons.dotsThree();
      case AppIconKind.visibility:
        return PhosphorIcons.eye();
      case AppIconKind.visibilityOff:
        return PhosphorIcons.eyeSlash();
      case AppIconKind.copy:
        return PhosphorIcons.copy();
      case AppIconKind.share:
        return PhosphorIcons.shareNetwork();

      // Status Indicators
      case AppIconKind.online:
        return PhosphorIcons.circle();
      case AppIconKind.offline:
        return PhosphorIcons.circle();
      case AppIconKind.typing:
        return PhosphorIcons.chatCenteredDots();

      // Theme & Display
      case AppIconKind.lightMode:
        return PhosphorIcons.sun();
      case AppIconKind.darkMode:
        return PhosphorIcons.moon();
      case AppIconKind.autoMode:
        return PhosphorIcons.circleHalf();

      // Reactions
      case AppIconKind.laugh:
        return PhosphorIcons.smiley();
      case AppIconKind.love:
        return PhosphorIcons.heart();
      case AppIconKind.angry:
        return PhosphorIcons.smileyXEyes();
      case AppIconKind.sad:
        return PhosphorIcons.smileySad();
      case AppIconKind.wow:
        return PhosphorIcons.smileyWink();
    }
  }

  /// Get the pixel size for the icon
  double _getSize() {
    switch (size) {
      case AppIconSize.xs:
        return 16.0;
      case AppIconSize.sm:
        return 20.0;
      case AppIconSize.md:
        return 24.0;
      case AppIconSize.lg:
        return 28.0;
      case AppIconSize.xl:
        return 32.0;
    }
  }

  /// Get the appropriate color from theme if not specified
  Color _getThemeColor(BuildContext context) {
    switch (kind) {
      // Primary actions
      case AppIconKind.send:
      case AppIconKind.call:
      case AppIconKind.video:
        return context.colorScheme.primary;

      // Secondary actions
      case AppIconKind.search:
      case AppIconKind.add:
      case AppIconKind.edit:
        return context.colorScheme.secondary;

      // Success/positive
      case AppIconKind.check:
      case AppIconKind.checkDouble:
      case AppIconKind.thumbsUp:
        return context.brandColors.success;

      // Error/negative
      case AppIconKind.error:
      case AppIconKind.delete:
      case AppIconKind.block:
        return context.brandColors.error;

      // Warning
      case AppIconKind.report:
        return context.brandColors.warning;

      // Status indicators
      case AppIconKind.online:
        return context.presenceOnlineColor;
      case AppIconKind.offline:
        return context.presenceOfflineColor;

      // Default to onSurface
      default:
        return context.colorScheme.onSurface;
    }
  }
}

/// Semantic icon kinds - maps to specific use cases
enum AppIconKind {
  // Communication
  chat,
  send,
  call,
  video,
  mic,
  micOff,

  // Media & Attachments
  attach,
  camera,
  image,
  file,
  download,
  play,
  pause,

  // Navigation
  back,
  forward,
  up,
  down,
  close,
  menu,

  // Main Navigation
  home,
  chats,
  contacts,
  calls,
  settings,

  // User Actions
  search,
  add,
  addFriend,
  edit,
  delete,
  block,
  report,

  // Status & Feedback
  bell,
  bellOff,
  star,
  heart,
  thumbsUp,
  check,
  checkDouble,
  error,
  info,

  // Profile & Account
  user,
  profile,
  logout,
  lock,
  unlock,

  // Interface
  more,
  moreHorizontal,
  visibility,
  visibilityOff,
  copy,
  share,

  // Status Indicators
  online,
  offline,
  typing,

  // Theme & Display
  lightMode,
  darkMode,
  autoMode,

  // Reactions
  laugh,
  love,
  angry,
  sad,
  wow,
}

/// Icon sizes following design tokens
enum AppIconSize {
  xs, // 16px
  sm, // 20px
  md, // 24px - default
  lg, // 28px
  xl, // 32px
}

/// Icon weights/strokes
enum AppIconWeight {
  regular,
  bold, // Uses filled variant when available
}

/// Helper extensions for common icon patterns
extension AppIconHelpers on AppIcon {
  /// Create a button-sized icon (typically md/lg)
  static AppIcon button(AppIconKind kind, {Color? color}) {
    return AppIcon(
      kind: kind,
      size: AppIconSize.md,
      color: color,
    );
  }

  /// Create a small UI icon (typically sm)
  static AppIcon small(AppIconKind kind, {Color? color}) {
    return AppIcon(
      kind: kind,
      size: AppIconSize.sm,
      color: color,
    );
  }

  /// Create a large feature icon (typically lg/xl)
  static AppIcon large(AppIconKind kind, {Color? color}) {
    return AppIcon(
      kind: kind,
      size: AppIconSize.lg,
      color: color,
    );
  }
}

/// State-aware icon that changes color based on interaction states
class StatefulAppIcon extends StatelessWidget {
  final AppIconKind kind;
  final AppIconSize size;
  final Color? baseColor;
  final AppIconWeight weight;
  final bool isPressed;
  final bool isHovered;
  final bool isFocused;
  final bool isDisabled;

  const StatefulAppIcon({
    super.key,
    required this.kind,
    this.size = AppIconSize.md,
    this.baseColor,
    this.weight = AppIconWeight.regular,
    this.isPressed = false,
    this.isHovered = false,
    this.isFocused = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = baseColor ?? context.colorScheme.onSurface;

    if (isDisabled) {
      iconColor = iconColor.withOpacity(0.38);
    } else if (isPressed) {
      iconColor = iconColor.withOpacity(0.86);
    } else if (isHovered) {
      iconColor = iconColor.withOpacity(0.92);
    } else if (isFocused) {
      iconColor = iconColor.withOpacity(0.88);
    }

    return AppIcon(
      kind: kind,
      size: size,
      color: iconColor,
      weight: weight,
    );
  }
}
