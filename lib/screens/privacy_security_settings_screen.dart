import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/consistent_app_bar.dart';


class PrivacySecuritySettingsScreen extends StatelessWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.cardBackground;
    final textColor = AppColors.text;
    final iconColor = AppColors.primary;
    return Scaffold(
      appBar: const ConsistentAppBar(
        title: 'Privacy & Security',
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/violettoblack_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.transparent,
                    Colors.black.withOpacity(0.18),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
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
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.block, color: iconColor),
                      title: Text('No screenshots or screen recordings are allowed in chat for your safety.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.lock, color: iconColor),
                      title: Text('Your data is encrypted and stored securely.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.verified_user, color: iconColor),
                      title: Text('We do not share your personal information with third parties.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.settings, color: iconColor),
                      title: Text('You are always in control of your privacy settings.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: iconColor),
                      title: Text('For more details, see our Privacy Policy.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
} 