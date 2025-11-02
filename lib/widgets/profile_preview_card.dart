import 'package:flutter/material.dart';

import '../core/constants.dart';

class ProfilePreviewCard extends StatelessWidget {
  final String? imageUrl;
  final String title; // e.g., "Luna Rae, 20"
  final String? subtitle; // e.g., location/distance
  final List<String> chips;
  final String? bio;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onMessage;
  final bool isOnline;

  const ProfilePreviewCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.chips = const [],
    this.bio,
    this.onPass,
    this.onLike,
    this.onMessage,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(imageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade900),
          ),
          // Top gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          // Content panel bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBottomContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isOnline)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isOnline) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: -8,
              children: chips.take(3).map((c) => _buildChip(c)).toList(),
            ),
          ],
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (onPass != null || onLike != null || onMessage != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onPass != null) _circleButton(icon: Icons.close, color: Colors.grey.shade800, onTap: onPass),
                if (onPass != null && (onLike != null || onMessage != null)) const SizedBox(width: 18),
                if (onLike != null) _circleButton(icon: Icons.favorite, color: AppColors.primary, onTap: onLike),
                if (onLike != null && onMessage != null) const SizedBox(width: 18),
                if (onMessage != null) _circleButton(icon: Icons.chat_bubble_rounded, color: Colors.grey.shade800, onTap: onMessage),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}


