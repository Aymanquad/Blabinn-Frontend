import 'package:flutter/material.dart';
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: stateManager.scaleAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/search-people-removebg-preview.png',
                    fit: BoxFit.contain,
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Find New People',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: const Text(
                'Connect with people within your preferred distance range',
                style: TextStyle(
                  color: Colors.white,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    color: const Color(0xFF8B5CF6),
                    strokeWidth: 4,
                  ),
                ),
                const Icon(
                  Icons.search,
                  size: 50,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Finding People...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Looking for people within your selected distance range',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 48,
            child: OutlinedButton(
              onPressed: stateManager.stopMatching,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildConnectButton(BuildContext context, ConnectStateManager stateManager) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: stateManager.isMatching ? stateManager.stopMatching : stateManager.startMatching,
        style: ElevatedButton.styleFrom(
          backgroundColor: stateManager.isMatching ? Colors.red : const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: Text(
          stateManager.isMatching ? 'Stop Matching' : 'Start Matching',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Widget buildGenderPreferenceSection(BuildContext context, ConnectStateManager stateManager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Gender Preference',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonFormField<String>(
              value: stateManager.genderPreference,
              style: const TextStyle(color: Colors.white),
              dropdownColor: const Color(0xFF2D1B69),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(Icons.person, color: Colors.white),
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
          ),
        ],
      ),
    );
  }

  static Widget buildMainScaffold(BuildContext context, ConnectStateManager stateManager) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69), // Dark purple background
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Main Content
                Expanded(
                  child: buildMainContent(context, stateManager),
                ),
                
                // Connect Button
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
      ),
    );
  }

  static Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Title in center
          const Expanded(
            child: Text(
              'Random Connect',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Empty space for balance
          const SizedBox(width: 48),
        ],
      ),
    );
  }
} 