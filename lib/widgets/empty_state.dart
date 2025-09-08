import 'package:flutter/material.dart';
import '../core/theme_extensions.dart';
import '../core/constants.dart';

/// A reusable empty state widget that displays an icon, title, subtitle,
/// and optional primary action button. Used for empty lists and screens.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final Widget? customContent;
  final EdgeInsets? padding;
  final double? iconSize;
  final Color? iconColor;
  final Gradient? iconBackground; // override background behind icon
  final Color? primaryButtonColor; // override primary action button color

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.customContent,
    this.padding,
    this.iconSize,
    this.iconColor,
    this.iconBackground,
    this.primaryButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: iconBackground ?? tokens?.primaryGradient,
                borderRadius: BorderRadius.circular(
                  tokens?.radiusLarge ?? 20,
                ),
                boxShadow: tokens?.softShadows ?? [],
              ),
              child: Icon(
                icon,
                size: iconSize ?? 48,
                color: iconColor ?? Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (customContent != null) ...[
              const SizedBox(height: 24),
              customContent!,
            ],
            
            if (primaryActionLabel != null && onPrimaryAction != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPrimaryAction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryButtonColor ?? AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        tokens?.radiusMedium ?? 16,
                      ),
                    ),
                  ),
                  child: Text(
                    primaryActionLabel!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for common use cases
class EmptyStates {
  static Widget chats({
    VoidCallback? onFindPeople,
    String? customMessage,
  }) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'No Chats Yet',
      subtitle: customMessage ?? 'Start connecting with people to begin chatting',
      primaryActionLabel: 'Find People',
      onPrimaryAction: onFindPeople,
    );
  }

  static Widget friends({
    VoidCallback? onFindPeople,
    String? customMessage,
  }) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No Friends Yet',
      subtitle: customMessage ?? 'Connect with people to build your network',
      primaryActionLabel: 'Discover People',
      onPrimaryAction: onFindPeople,
    );
  }

  static Widget media({
    VoidCallback? onAddMedia,
    String? customMessage,
  }) {
    return EmptyState(
      icon: Icons.photo_library_outlined,
      title: 'No Media Yet',
      subtitle: customMessage ?? 'Share photos and videos with your connections',
      primaryActionLabel: 'Add Media',
      onPrimaryAction: onAddMedia,
    );
  }

  static Widget searchResults({
    String? customMessage,
  }) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: customMessage ?? 'Try adjusting your search criteria',
    );
  }

  static Widget notifications({
    String? customMessage,
  }) {
    return EmptyState(
      icon: Icons.notifications_none,
      title: 'No Notifications',
      subtitle: customMessage ?? 'You\'re all caught up!',
    );
  }
}
