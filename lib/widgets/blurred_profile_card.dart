import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/premium_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Blurred Profile Card Widget
/// Shows a blurred profile card for non-premium users with premium upgrade prompt
class BlurredProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback? onTap;
  final Widget? child;

  const BlurredProfileCard({
    Key? key,
    required this.profile,
    this.onTap,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.currentUser?.isPremium ?? false;

    return GestureDetector(
      onTap: isPremium ? onTap : () => _showPremiumPopup(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Original content
              if (child != null)
                child!
              else
                _buildDefaultProfileContent(),

              // Blur overlay for non-premium users
              if (!isPremium)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildPremiumOverlay(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultProfileContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: profile['profilePicture'] != null
                    ? NetworkImage(profile['profilePicture'] as String)
                    : null,
                child: profile['profilePicture'] == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['displayName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (profile['age'] != null)
                      Text(
                        '${profile['age']} years old',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile['bio'] != null) ...[
            const SizedBox(height: 12),
            Text(
              profile['bio'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (profile['interests'] != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (profile['interests'] as List<dynamic>)
                  .take(3)
                  .map((interest) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          interest.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumOverlay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Premium Feature',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Premium to see full profiles',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showPremiumPopup(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C4CCF),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumPopup(BuildContext context) {
    PremiumService.checkPremiumOrShowPopup(
      context: context,
      feature: 'View Full Profiles',
      description:
          'See complete profiles of who liked you and your matches. Premium users get unlimited access to all profile details.',
    );
  }
}

/// Blurred Profile List Item
/// A smaller version for list views
class BlurredProfileListItem extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback? onTap;

  const BlurredProfileListItem({
    Key? key,
    required this.profile,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.currentUser?.isPremium ?? false;

    return GestureDetector(
      onTap: isPremium ? onTap : () => _showPremiumPopup(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Original content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: profile['profilePicture'] != null
                          ? NetworkImage(profile['profilePicture'] as String)
                          : null,
                      child: profile['profilePicture'] == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile['displayName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (profile['age'] != null)
                            Text(
                              '${profile['age']} years old',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (profile['matchedAt'] != null)
                      Text(
                        _formatDate(profile['matchedAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),

              // Blur overlay for non-premium users
              if (!isPremium)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C4CCF).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        final now = DateTime.now();
        final difference = now.difference(parsedDate);

        if (difference.inDays > 0) {
          return '${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours}h ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes}m ago';
        } else {
          return 'Just now';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showPremiumPopup(BuildContext context) {
    PremiumService.checkPremiumOrShowPopup(
      context: context,
      feature: 'View Full Profiles',
      description:
          'See complete profiles of who liked you and your matches. Premium users get unlimited access to all profile details.',
    );
  }
}
