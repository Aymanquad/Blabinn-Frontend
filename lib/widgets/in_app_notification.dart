import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';


class InAppNotification extends StatefulWidget {
  final String senderName;
  final String message;
  final String senderId;
  final String? chatId;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotification({
    super.key,
    required this.senderName,
    required this.message,
    required this.senderId,
    this.chatId,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuart,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the animation
    _animationController.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: _onTap,
                      onPanUpdate: (details) {
                        // Allow swipe up to dismiss
                        if (details.delta.dy < -5) {
                          _dismiss();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                                  color: AppColors.cardBackground.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                widget.senderName.isNotEmpty 
                                    ? widget.senderName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Message content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.senderName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Chat icon and close button
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _dismiss,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }
}

// Global method to show in-app notification
void showInAppNotification({
  required BuildContext context,
  required String senderName,
  required String message,
  required String senderId,
  String? chatId,
  VoidCallback? onTap,
}) {
  final overlay = Overlay.of(context);
  
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 0,
      right: 0,
      child: InAppNotification(
        senderName: senderName,
        message: message,
        senderId: senderId,
        chatId: chatId,
        onTap: onTap,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    ),
  );

  overlay.insert(overlayEntry);
}