import 'package:flutter/material.dart';
import '../../core/theme_extensions.dart';
import '../../widgets/glass_container.dart';

/// Onboarding Screen 4: Gender Selection & Verification Prompt
class OnboardingScreen4 extends StatefulWidget {
  final String userType;
  final Map<String, dynamic> profileData;
  final Function(bool wantsVerification) onVerificationChoice;

  const OnboardingScreen4({
    Key? key,
    required this.userType,
    required this.profileData,
    required this.onVerificationChoice,
  }) : super(key: key);

  @override
  State<OnboardingScreen4> createState() => _OnboardingScreen4State();
}

class _OnboardingScreen4State extends State<OnboardingScreen4> {
  bool? _wantsVerification;

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
                  'Verification',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Get verified to build trust and unlock more features',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Profile Summary
                _buildProfileSummary(theme, tokens),
                
                const SizedBox(height: 48),
                
                // Verification Benefits
                _buildVerificationBenefits(theme, tokens),
                
                const SizedBox(height: 48),
                
                // Verification Choice
                _buildVerificationChoice(theme, tokens),
                
                const Spacer(),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _wantsVerification != null
                        ? () => widget.onVerificationChoice(_wantsVerification!)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wantsVerification != null
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

  Widget _buildProfileSummary(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: Column(
        children: [
          // Profile Image
          if (widget.profileData['profileImage'] != null)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: Image.file(
                  widget.profileData['profileImage'],
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Profile Info
          Text(
            widget.profileData['displayName'] ?? 'Unknown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.profileData['gender'] == 'male' ? Icons.male : Icons.female,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.profileData['age']} years old',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBenefits(ThemeData theme, AppThemeTokens tokens) {
    final benefits = [
      {
        'icon': Icons.verified_user,
        'title': 'Build Trust',
        'description': 'Verified users are more trusted by others',
      },
      {
        'icon': Icons.star,
        'title': 'Priority Matching',
        'description': 'Get shown to more potential matches',
      },
      {
        'icon': Icons.security,
        'title': 'Enhanced Security',
        'description': 'Help keep the community safe',
      },
    ];

    return Column(
      children: benefits.map((benefit) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: tokens.primaryColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      benefit['description'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildVerificationChoice(ThemeData theme, AppThemeTokens tokens) {
    return Column(
      children: [
        // Yes Option
        GestureDetector(
          onTap: () {
            setState(() {
              _wantsVerification = true;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _wantsVerification == true
                  ? tokens.primaryColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _wantsVerification == true
                    ? tokens.primaryColor
                    : Colors.white.withOpacity(0.3),
                width: _wantsVerification == true ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: _wantsVerification == true
                      ? tokens.primaryColor
                      : Colors.white.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yes, verify my profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'We\'ll guide you through the verification process',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // No Option
        GestureDetector(
          onTap: () {
            setState(() {
              _wantsVerification = false;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _wantsVerification == false
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _wantsVerification == false
                    ? Colors.grey
                    : Colors.white.withOpacity(0.3),
                width: _wantsVerification == false ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: _wantsVerification == false
                      ? Colors.grey
                      : Colors.white.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maybe later',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'You can verify your profile anytime in settings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
