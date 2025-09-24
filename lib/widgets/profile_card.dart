import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/user.dart';

class ProfileCard extends StatefulWidget {
  final User user;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onVideoCall;
  final VoidCallback? onAddRemoveFriend;
  final bool showOnlineStatus;

  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.onMessage,
    this.onVideoCall,
    this.onAddRemoveFriend,
    this.showOnlineStatus = true,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackground.withOpacity(0.8),
                  AppColors.cardBackground.withOpacity(0.6),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildModernProfileHeader(theme),
                      const SizedBox(height: 20),
                      _buildModernProfileInfo(theme),
                      if (widget.showOnlineStatus) ...[
                        const SizedBox(height: 20),
                        _buildModernActions(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernProfileHeader(ThemeData theme) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.secondary.withOpacity(0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.cardBackground,
                backgroundImage: widget.user.hasProfileImage
                    ? NetworkImage(widget.user.profileImage!)
                    : null,
                child: !widget.user.hasProfileImage
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.user.displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (widget.user.isOnline)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.online.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.user.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.user.isPremium)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.user.isOnline ? AppColors.online : AppColors.offline,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.user.isOnline ? AppColors.online : AppColors.offline)
                              .withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.user.statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernProfileInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              widget.user.bio!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.user.interests.isNotEmpty) ...[
          Text(
            'Interests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.user.interests.take(6).map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.language,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Language: ${widget.user.language.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.user.hasLocation) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.user.location ?? 'Location available',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildModernActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Message',
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            onPressed: widget.onMessage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernActionButton(
            icon: Icons.videocam_outlined,
            label: 'Video Call',
            gradient: LinearGradient(
              colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
            ),
            onPressed: widget.onVideoCall,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernActionButton(
            icon: widget.user.isFriend ? Icons.person_remove_outlined : Icons.person_add_outlined,
            label: widget.user.isFriend ? 'Remove' : 'Add Friend',
            gradient: LinearGradient(
              colors: widget.user.isFriend 
                ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                : [AppColors.accent, AppColors.accent.withOpacity(0.8)],
            ),
            onPressed: widget.onAddRemoveFriend,
          ),
        ),
      ],
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }
}

class CompactProfileCard extends StatefulWidget {
  final User user;
  final VoidCallback? onTap;
  final bool showOnlineStatus;

  const CompactProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.showOnlineStatus = true,
  });

  @override
  State<CompactProfileCard> createState() => _CompactProfileCardState();
}

class _CompactProfileCardState extends State<CompactProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackground.withOpacity(0.7),
                  AppColors.cardBackground.withOpacity(0.5),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildModernProfileImage(context),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModernProfileInfo(context),
                      ),
                      if (widget.showOnlineStatus) _buildModernOnlineStatus(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernProfileImage(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.secondary.withOpacity(0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.cardBackground,
            backgroundImage: widget.user.hasProfileImage
                ? NetworkImage(widget.user.profileImage!)
                : null,
            child: !widget.user.hasProfileImage
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.user.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (widget.user.isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBackground,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.online.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModernProfileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.user.displayName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: 0.3,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.user.location != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.user.location!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildModernOnlineStatus() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: widget.user.isOnline ? AppColors.online : AppColors.offline,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (widget.user.isOnline ? AppColors.online : AppColors.offline)
                .withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
