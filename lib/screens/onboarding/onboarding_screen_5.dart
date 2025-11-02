import 'package:flutter/material.dart';
import '../../core/theme_extensions.dart';
import '../../widgets/glass_container.dart';

/// Onboarding Screen 5: Terms of Service & Privacy Policy
class OnboardingScreen5 extends StatefulWidget {
  final Function() onComplete;

  const OnboardingScreen5({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen5> createState() => _OnboardingScreen5State();
}

class _OnboardingScreen5State extends State<OnboardingScreen5> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

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
                  'Terms & Privacy',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Please review and accept our terms to continue',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Terms and Privacy Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTermsSection(theme, tokens),
                        const SizedBox(height: 24),
                        _buildPrivacySection(theme, tokens),
                        const SizedBox(height: 24),
                        _buildDataUsageSection(theme, tokens),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Accept Checkboxes
                _buildAcceptanceCheckboxes(theme, tokens),
                
                const SizedBox(height: 32),
                
                // Complete Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_acceptedTerms && _acceptedPrivacy)
                        ? widget.onComplete
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_acceptedTerms && _acceptedPrivacy)
                          ? tokens.primaryColor
                          : Colors.grey.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusL),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Complete Setup',
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

  Widget _buildTermsSection(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: tokens.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Terms of Service',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'By using Chatify, you agree to:\n\n'
            '• Use the service responsibly and respectfully\n'
            '• Not share inappropriate or harmful content\n'
            '• Respect other users\' privacy and boundaries\n'
            '• Follow community guidelines and local laws\n'
            '• Be at least 13 years old to use the service',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Open full terms of service
              _showFullTerms(theme, tokens);
            },
            child: Text(
              'Read full Terms of Service',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: tokens.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy Policy',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We care about your privacy:\n\n'
            '• We collect only necessary information to provide our service\n'
            '• Your personal data is protected and not shared with third parties\n'
            '• You can delete your account and data at any time\n'
            '• We use your location only for matching (with your permission)\n'
            '• Messages are encrypted and stored securely',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Open full privacy policy
              _showFullPrivacy(theme, tokens);
            },
            child: Text(
              'Read full Privacy Policy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataUsageSection(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: tokens.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Data Usage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We use your data to:\n\n'
            '• Provide personalized matching and recommendations\n'
            '• Improve our service and user experience\n'
            '• Ensure platform safety and prevent abuse\n'
            '• Send you important updates and notifications\n'
            '• Analyze usage patterns to enhance features',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceCheckboxes(ThemeData theme, AppThemeTokens tokens) {
    return Column(
      children: [
        // Terms Checkbox
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() {
                  _acceptedTerms = value ?? false;
                });
              },
              activeColor: tokens.primaryColor,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _acceptedTerms = !_acceptedTerms;
                  });
                },
                child: Text(
                  'I agree to the Terms of Service',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Privacy Checkbox
        Row(
          children: [
            Checkbox(
              value: _acceptedPrivacy,
              onChanged: (value) {
                setState(() {
                  _acceptedPrivacy = value ?? false;
                });
              },
              activeColor: tokens.primaryColor,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _acceptedPrivacy = !_acceptedPrivacy;
                  });
                },
                child: Text(
                  'I agree to the Privacy Policy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFullTerms(ThemeData theme, AppThemeTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Terms of Service',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Full Terms of Service content would be displayed here...\n\n'
            'This is a placeholder for the complete terms of service document.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: tokens.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPrivacy(ThemeData theme, AppThemeTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Privacy Policy',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Full Privacy Policy content would be displayed here...\n\n'
            'This is a placeholder for the complete privacy policy document.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: tokens.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
