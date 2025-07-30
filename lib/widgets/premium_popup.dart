import 'package:flutter/material.dart';

/// Premium Popup Widget
/// Shows a gold-themed popup when non-premium users try to access premium features
class PremiumPopup extends StatelessWidget {
  final String feature;
  final String description;
  final VoidCallback? onBuyPremium;
  final VoidCallback? onCancel;

  const PremiumPopup({
    Key? key,
    required this.feature,
    required this.description,
    this.onBuyPremium,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD700), // Gold
              Color(0xFFFFE55C), // Light Gold
              Color(0xFFFFB347), // Orange Gold
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with crown icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.orange.shade500,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Crown Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.diamond,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'PREMIUM FEATURE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Premium Benefits
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium Benefits:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBenefitItem('Upload profile pictures'),
                        _buildBenefitItem('Send & receive images in chats'),
                        _buildBenefitItem(
                            'Gender preferences for random connections'),
                        _buildBenefitItem('Store images in media folder'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Only ₹1,500',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Buy Premium button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onBuyPremium ??
                          () {
                            Navigator.of(context).pop();
                            // TODO: Navigate to payment screen
                          },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Buy Premium',
                        style: TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show premium popup dialog
  /// PREMIUM POPUP DISABLED FOR TESTING - DOES NOTHING
  static Future<void> show({
    required BuildContext context,
    required String feature,
    required String description,
    VoidCallback? onBuyPremium,
    VoidCallback? onCancel,
  }) {
    // PREMIUM POPUP DISABLED FOR TESTING - JUST RETURN
    // print('🔧 DEBUG: Premium popup disabled for testing - feature: $feature');
    return Future.value();

    /* ORIGINAL PREMIUM POPUP CODE - COMMENTED OUT FOR TESTING
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PremiumPopup(
        feature: feature,
        description: description,
        onBuyPremium: onBuyPremium,
        onCancel: onCancel,
      ),
    );
    */
  }
}
