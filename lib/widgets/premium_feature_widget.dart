import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../core/theme_extensions.dart';

/// Premium Feature Widget
/// Shows premium feature buttons with proper access control
class PremiumFeatureWidget extends StatelessWidget {
  final String feature;
  final Widget child;
  final VoidCallback? onTap;
  final String? customMessage;
  final bool showUpgradeButton;

  const PremiumFeatureWidget({
    Key? key,
    required this.feature,
    required this.child,
    this.onTap,
    this.customMessage,
    this.showUpgradeButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    if (currentUser == null) {
      return _buildRestrictedWidget(context, theme, tokens, 'Please log in to use this feature');
    }

    // Check if user has access to the feature
    final hasAccess = currentUser.hasFeatureAccess(feature);
    
    if (hasAccess) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return _buildRestrictedWidget(
      context, 
      theme, 
      tokens, 
      customMessage ?? _getFeatureMessage(feature),
    );
  }

  Widget _buildRestrictedWidget(BuildContext context, ThemeData theme, AppThemeTokens tokens, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(tokens.radiusM),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Blurred/disabled child
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.grey,
              BlendMode.saturation,
            ),
            child: Opacity(
              opacity: 0.6,
              child: child,
            ),
          ),
          
          // Premium overlay
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (showUpgradeButton) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _navigateToSubscriptionPlans(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusS),
                        ),
                      ),
                      child: const Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureMessage(String feature) {
    switch (feature) {
      case 'instant_match':
        return 'Instant match is a premium feature';
      case 'super_likes':
        return 'Super likes are a premium feature';
      case 'boosts':
        return 'Boosts are a premium feature';
      case 'unlimited_who_liked':
        return 'Unlimited "Who Liked You" is a premium feature';
      case 'add_friends':
        return 'Adding friends requires a premium account';
      case 'send_images':
        return 'Sending images requires a premium account';
      case 'ads_free':
        return 'Ad-free experience is a premium feature';
      default:
        return 'This feature requires a premium account';
    }
  }

  void _navigateToSubscriptionPlans(BuildContext context) {
    Navigator.pushNamed(context, '/subscription-plans');
  }
}

/// Instant Match Button
class InstantMatchButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;

  const InstantMatchButton({
    Key? key,
    this.onTap,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return PremiumFeatureWidget(
      feature: 'instant_match',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flash_on,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label ?? 'Instant Match',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Super Like Button
class SuperLikeButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int? remainingCount;

  const SuperLikeButton({
    Key? key,
    this.onTap,
    this.remainingCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return PremiumFeatureWidget(
      feature: 'super_likes',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.8),
          borderRadius: BorderRadius.circular(tokens.radiusM),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.star,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Super Like',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (remainingCount != null) ...[
              Text(
                '$remainingCount left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Boost Button
class BoostButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int? remainingCount;

  const BoostButton({
    Key? key,
    this.onTap,
    this.remainingCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return PremiumFeatureWidget(
      feature: 'boosts',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          borderRadius: BorderRadius.circular(tokens.radiusM),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Boost',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (remainingCount != null) ...[
              Text(
                '$remainingCount left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Premium Badge
class PremiumBadge extends StatelessWidget {
  final bool compact;

  const PremiumBadge({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
