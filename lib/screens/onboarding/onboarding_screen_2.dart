import 'package:flutter/material.dart';
import '../../core/theme_extensions.dart';
import '../../widgets/glass_container.dart';

/// Onboarding Screen 2: User Type Selection
class OnboardingScreen2 extends StatefulWidget {
  final Function(String userType) onUserTypeSelected;

  const OnboardingScreen2({
    Key? key,
    required this.onUserTypeSelected,
  }) : super(key: key);

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: tokens.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),
                
                // Header
                Text(
                  'Choose Your Experience',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Select how you\'d like to use Chatify',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // User Type Options
                Expanded(
                  child: Column(
                    children: [
                      _buildUserTypeOption(
                        context,
                        userType: 'guest',
                        title: 'Anonymous',
                        subtitle: 'Quick start, no signup required',
                        icon: Icons.person_outline,
                        color: const Color(0xFF6B7280),
                        features: [
                          'Match with other guests only',
                          'Basic chat features',
                          'No account required',
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildUserTypeOption(
                        context,
                        userType: 'signed_up_free',
                        title: 'Free Account',
                        subtitle: 'Sign up for more features',
                        icon: Icons.star_outline,
                        color: const Color(0xFF3B82F6),
                        features: [
                          'Match with free and premium users',
                          'Add friends and send images',
                          'Profile verification available',
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildUserTypeOption(
                        context,
                        userType: 'premium',
                        title: 'Premium',
                        subtitle: 'Unlock all features',
                        icon: Icons.workspace_premium,
                        color: const Color(0xFFF59E0B),
                        features: [
                          'Match with everyone',
                          'Ad-free experience',
                          'Unlimited friends and features',
                          'Instant matches and boosts',
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedUserType != null
                        ? () => widget.onUserTypeSelected(selectedUserType!)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedUserType != null
                          ? tokens.primaryColor
                          : Colors.grey.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusL),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Back Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(
    BuildContext context, {
    required String userType,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedUserType == userType;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUserType = userType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 24,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
