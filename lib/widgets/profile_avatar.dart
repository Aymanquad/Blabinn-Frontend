import 'package:flutter/material.dart';
import '../core/theme_extensions.dart';
import '../core/constants.dart';

/// Modern profile avatar with enhanced styling
class ProfileAvatar extends StatelessWidget {
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

  const ProfileAvatar({
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    final avatarBorderRadius = BorderRadius.circular(size / 2);
    final avatarBackgroundColor = backgroundColor ?? theme.colorScheme.surfaceVariant;
    final avatarBorderColor = borderColor ?? theme.colorScheme.primary;
    final avatarGradient = gradient ?? tokens?.primaryGradient;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: useGradient ? null : avatarBackgroundColor,
        gradient: useGradient ? avatarGradient : null,
        borderRadius: avatarBorderRadius,
        border: Border.all(
          color: avatarBorderColor,
          width: borderWidth,
        ),
        boxShadow: tokens?.microShadows,
      ),
      child: ClipRRect(
        borderRadius: avatarBorderRadius,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
              )
            : _buildFallbackAvatar(),
      ),
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    if (showOnlineStatus) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF10B981) : theme.colorScheme.outline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
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
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Large profile avatar for profile screens
class LargeProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final VoidCallback? onEdit;

  const LargeProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.onTap,
    this.showEditIcon = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: ProfileAvatar(
              imageUrl: imageUrl,
              displayName: displayName,
              size: 120,
              onTap: onTap,
              useGradient: false,
              borderWidth: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        if (showEditIcon)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                        color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small profile avatar for chat lists
class SmallProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;

  const SmallProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.showOnlineStatus = true,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      size: 48,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      onTap: onTap,
      borderWidth: 2,
    );
  }
}

/// Medium profile avatar for user cards
class MediumProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;

  const MediumProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      size: 80,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      onTap: onTap,
      borderWidth: 3,
    );
  }
}
