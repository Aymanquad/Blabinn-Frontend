import 'package:flutter/material.dart';
import '../models/user.dart';

/// User Type Badge Widget
/// Displays a badge showing the user's type (Anonymous, Free, Premium)
class UserTypeBadge extends StatelessWidget {
  final User user;
  final double? size;
  final bool showIcon;
  final bool showLabel;

  const UserTypeBadge({
    Key? key,
    required this.user,
    this.size,
    this.showIcon = true,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badge = user.userTypeBadge;
    final badgeSize = size ?? 20.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgeSize * 0.3,
        vertical: badgeSize * 0.15,
      ),
      decoration: BoxDecoration(
        color: Color(badge['color'] as int).withOpacity(0.2),
        borderRadius: BorderRadius.circular(badgeSize * 0.3),
        border: Border.all(
          color: Color(badge['color'] as int),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(
              badge['icon'] as String,
              style: TextStyle(fontSize: badgeSize * 0.6),
            ),
            if (showLabel) SizedBox(width: badgeSize * 0.2),
          ],
          if (showLabel)
            Text(
              badge['label'] as String,
              style: TextStyle(
                fontSize: badgeSize * 0.5,
                fontWeight: FontWeight.w600,
                color: Color(badge['color'] as int),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact User Type Badge (icon only)
class CompactUserTypeBadge extends StatelessWidget {
  final User user;
  final double? size;

  const CompactUserTypeBadge({
    Key? key,
    required this.user,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badge = user.userTypeBadge;
    final badgeSize = size ?? 16.0;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: Color(badge['color'] as int).withOpacity(0.2),
        borderRadius: BorderRadius.circular(badgeSize * 0.3),
        border: Border.all(
          color: Color(badge['color'] as int),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          badge['icon'] as String,
          style: TextStyle(fontSize: badgeSize * 0.6),
        ),
      ),
    );
  }
}

/// User Type Badge with Tooltip
class UserTypeBadgeWithTooltip extends StatelessWidget {
  final User user;
  final double? size;
  final bool showIcon;
  final bool showLabel;

  const UserTypeBadgeWithTooltip({
    Key? key,
    required this.user,
    this.size,
    this.showIcon = true,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badge = user.userTypeBadge;
    final tooltipText = _getTooltipText(badge['type'] as String);

    return Tooltip(
      message: tooltipText,
      child: UserTypeBadge(
        user: user,
        size: size,
        showIcon: showIcon,
        showLabel: showLabel,
      ),
    );
  }

  String _getTooltipText(String userType) {
    switch (userType) {
      case 'guest':
        return 'Anonymous User\n• Can only match with other guests\n• Cannot add friends\n• Cannot send images';
      case 'signed_up_free':
        return 'Free User\n• Can match with free and premium users\n• Can add friends\n• Can send images\n• Limited features';
      case 'premium':
        return 'Premium User\n• Can match with everyone\n• All features unlocked\n• Ad-free experience\n• Unlimited friends';
      default:
        return 'Unknown User Type';
    }
  }
}
