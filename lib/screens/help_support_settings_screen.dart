import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class HelpSupportSettingsScreen extends StatelessWidget {
  const HelpSupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.text;
    final iconColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
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
                    Icons.help_outline_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We are here to help you with any questions or issues.',
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
              'Support Resources',
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
                      leading: Icon(Icons.email, color: iconColor),
                      title: Text('For any questions or issues, please contact our support team at support@chatify.com.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.question_answer, color: iconColor),
                      title: Text('Check our FAQ section in the app or on our website for quick answers.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.feedback, color: iconColor),
                      title: Text('We value your feedback and are always working to improve your experience.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.favorite, color: iconColor),
                      title: Text('Thank you for being a part of the Chatify community!',
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