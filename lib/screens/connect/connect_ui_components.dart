import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../services/premium_service.dart';
import 'connect_state_manager.dart';

class ConnectUIComponents {
  static Widget buildMainContent(BuildContext context, ConnectStateManager stateManager) {
    if (stateManager.isMatching) {
      return buildMatchingScreen(context, stateManager);
    }

    return buildWelcomeScreen(context, stateManager);
  }

  static Widget buildWelcomeScreen(BuildContext context, ConnectStateManager stateManager) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: stateManager.scaleAnimation,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/search-people-removebg-preview.png',
                    fit: BoxFit.contain,
                    width: 130,
                    height: 130,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Find New People',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Connect with people within your preferred distance range',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            buildGenderPreferenceSection(context, stateManager),
          ],
        ),
      ),
    );
  }

  static Widget buildMatchingScreen(BuildContext context, ConnectStateManager stateManager) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 3,
                  ),
                ),
                Icon(
                  Icons.search,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding People...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for people within your selected distance range',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: stateManager.stopMatching,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static Widget buildConnectButton(BuildContext context, ConnectStateManager stateManager) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: stateManager.isMatching ? stateManager.stopMatching : stateManager.startMatching,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: stateManager.isMatching ? Colors.red : theme.colorScheme.primary,
        ),
        child: Text(
          stateManager.isMatching ? 'Stop Matching' : 'Start Matching',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static Widget buildGenderPreferenceSection(BuildContext context, ConnectStateManager stateManager) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person,
                    size: 16, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text('Gender Preference',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: stateManager.genderPreference,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(Icons.person),
              ),
              items: const [
                DropdownMenuItem(value: 'any', child: Text('Any Gender')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) async {
                // Check if user is trying to select non-'any' gender preference
                if (value != 'any' && value != null) {
                  // Check if user has premium
                  final hasPremium =
                      await PremiumService.checkGenderPreferences(context);
                  if (!hasPremium) {
                    return; // User doesn't have premium, popup shown, keep current selection
                  }
                }

                stateManager.genderPreference = value!;
                stateManager.globalMatchingService.setGenderPreference(value!);
                stateManager.onStateChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildMainScaffold(BuildContext context, ConnectStateManager stateManager) {
    return Scaffold(
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/violettoblack_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: buildMainContent(context, stateManager),
              ),
              buildConnectButton(context, stateManager),
              const SizedBox(height: 8),
              // Banner Ad at the bottom
              const BannerAdWidget(
                height: 50,
                margin: EdgeInsets.only(bottom: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 