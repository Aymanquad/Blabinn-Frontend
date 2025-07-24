import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class PrivacySecuritySettingsScreen extends StatelessWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.text;
    final iconColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                    isDarkMode ? AppColors.darkPrimary.withOpacity(0.8) : AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.privacy_tip_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Privacy & Security',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your privacy and security are our top priorities.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.block, color: iconColor),
                      title: Text('No screenshots or screen recordings are allowed in chat for your safety.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.lock, color: iconColor),
                      title: Text('Your data is encrypted and stored securely.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.verified_user, color: iconColor),
                      title: Text('We do not share your personal information with third parties.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.settings, color: iconColor),
                      title: Text('You are always in control of your privacy settings.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: iconColor),
                      title: Text('For more details, see our Privacy Policy.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 