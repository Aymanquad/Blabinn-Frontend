import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/constants.dart';
import '../models/user.dart';

class MatchPopup extends StatefulWidget {
  final User matchedUser;
  final VoidCallback onContinueChat;
  final VoidCallback? onAddFriend;
  final VoidCallback? onSkip;

  const MatchPopup({
    super.key,
    required this.matchedUser,
    required this.onContinueChat,
    this.onAddFriend,
    this.onSkip,
  });

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start animations with staggered timing
    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _slideController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return '♂';
      case 'female':
        return '♀';
      default:
        return '⚧';
    }
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: widget.matchedUser.profileImage != null &&
                widget.matchedUser.profileImage!.isNotEmpty
            ? Image.network(
                widget.matchedUser.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width > 600;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10 * _fadeAnimation.value,
              sigmaY: 10 * _fadeAnimation.value,
            ),
            child: Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                      width: isTablet
                          ? 400
                          : (isSmallScreen
                              ? screenSize.width * 0.9
                              : screenSize.width * 0.85),
                      constraints: BoxConstraints(
                        maxHeight: screenSize.height * 0.8,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with sparkles
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(22),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Match title with sparkle effect
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '✨',
                                      style: TextStyle(
                                        fontSize: isTablet ? 28 : 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'It\'s a Match!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium!
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isTablet ? 32 : 28,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '✨',
                                      style: TextStyle(
                                        fontSize: isTablet ? 28 : 24,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You found someone to chat with!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        color: Colors.grey[300],
                                        fontSize: isTablet ? 18 : 16,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Profile section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: Column(
                              children: [
                                // Profile image
                                _buildProfileImage(),

                                const SizedBox(height: 20),

                                // User info
                                Column(
                                  children: [
                                    // Name and age
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.matchedUser.username,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium!
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: isTablet ? 28 : 24,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        if (widget.matchedUser.age != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.4),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '${widget.matchedUser.age}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Gender
                                    if (widget.matchedUser.gender != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _getGenderIcon(
                                                  widget.matchedUser.gender),
                                              style: TextStyle(
                                                fontSize: isTablet ? 20 : 18,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.matchedUser.gender!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    color: Colors.grey[300],
                                                    fontWeight: FontWeight.w500,
                                                    fontSize:
                                                        isTablet ? 18 : 16,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 20),

                                    // Online status
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Online Now',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // Action buttons
                                Column(
                                  children: [
                                    // Continue to Chat button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: widget.onContinueChat,
                                        icon: const Icon(
                                          Icons.chat_bubble_rounded,
                                          size: 20,
                                        ),
                                        label: Text(
                                          'Start Chatting',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: isTablet ? 18 : 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 8,
                                          shadowColor: AppColors.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Secondary actions row
                                    Row(
                                      children: [
                                        if (widget.onAddFriend != null)
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: widget.onAddFriend,
                                              icon: const Icon(
                                                Icons.person_add,
                                                size: 18,
                                              ),
                                              label: Text(
                                                'Add Friend',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 16 : 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: BorderSide(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.5),
                                                  width: 1.5,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: isTablet ? 16 : 14,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (widget.onAddFriend != null &&
                                            widget.onSkip != null)
                                          const SizedBox(width: 12),
                                        if (widget.onSkip != null)
                                          Expanded(
                                            child: TextButton(
                                              onPressed: widget.onSkip,
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.grey[400],
                                                padding: EdgeInsets.symmetric(
                                                  vertical: isTablet ? 16 : 14,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                'Skip',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 16 : 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows a match popup dialog
Future<void> showMatchPopup({
  required BuildContext context,
  required User matchedUser,
  required VoidCallback onContinueChat,
  VoidCallback? onAddFriend,
  VoidCallback? onSkip,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => MatchPopup(
      matchedUser: matchedUser,
      onContinueChat: () {
        Navigator.of(context).pop(); // Close the popup first
        onContinueChat(); // Then execute the callback
      },
      onAddFriend: onAddFriend != null ? () async {
        try {
          onAddFriend(); // Execute the add friend callback
          
          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Friend Added!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        } catch (e) {
          // Handle error
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Failed to add friend',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      } : null,
      onSkip: onSkip != null ? () {
        Navigator.of(context).pop(); // Close the popup first
        onSkip(); // Then execute the callback
      } : null,
    ),
  );
}
