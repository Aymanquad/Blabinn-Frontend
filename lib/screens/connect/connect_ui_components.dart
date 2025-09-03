import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants.dart';
import '../../core/theme_extensions.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/glass_container.dart';
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
    final tokens = theme.extension<AppThemeTokens>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced Hero Section
            _buildHeroSection(context, stateManager, tokens),
            
            const SizedBox(height: 32),
            
            // Enhanced Title and Description
            _buildTitleSection(context, theme),
            
            const SizedBox(height: 32),
            
            // Enhanced Gender Preference Section
            _buildEnhancedGenderPreferenceSection(context, stateManager, tokens),
            
            const SizedBox(height: 24),
            
            // Enhanced Distance and Age Range Section
            _buildEnhancedFiltersSection(context, stateManager, tokens),
            
            const SizedBox(height: 24),
            
            // Tips Section
            _buildTipsSection(context, tokens),
          ],
        ),
      ),
    );
  }

  static Widget _buildHeroSection(BuildContext context, ConnectStateManager stateManager, AppThemeTokens? tokens) {
    return ScaleTransition(
      scale: stateManager.scaleAnimation,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: tokens?.primaryGradient ?? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.2),
              AppColors.secondary.withOpacity(0.2),
            ],
          ),
          boxShadow: tokens?.softShadows ?? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/search-people-removebg-preview.png',
            fit: BoxFit.contain,
            width: 140,
            height: 140,
          ),
        ),
      ),
    );
  }

  static Widget _buildTitleSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Text(
          'Find New People',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Connect with people within your preferred distance range',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static Widget _buildEnhancedGenderPreferenceSection(BuildContext context, ConnectStateManager stateManager, AppThemeTokens? tokens) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gender Preference',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Enhanced Dropdown
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: stateManager.genderPreference,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                ),
                dropdownColor: AppColors.cardBackground,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'any',
                    child: Text('Any Gender', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'male',
                    child: Text('Male', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text('Female', style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  
                  // Check if user is trying to select non-'any' gender preference
                  if (value != 'any') {
                    // Check if user has premium
                    final hasPremium = await PremiumService.checkGenderPreferences(context);
                    if (!hasPremium) {
                      return; // User doesn't have premium, popup shown, keep current selection
                    }
                  }

                  stateManager.genderPreference = value;
                  stateManager.globalMatchingService.setGenderPreference(value);
                  stateManager.onStateChanged();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEnhancedFiltersSection(BuildContext context, ConnectStateManager stateManager, AppThemeTokens? tokens) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Matching Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Distance Range
            _buildFilterItem(
              context,
              'Distance Range',
              'Within 50 km',
              Icons.location_on,
              AppColors.primary,
            ),
            
            const SizedBox(height: 16),
            
            // Age Range
            _buildFilterItem(
              context,
              'Age Range',
              '18 - 35 years',
              Icons.cake,
              AppColors.secondary,
            ),
            
            const SizedBox(height: 16),
            
            // Interests
            _buildFilterItem(
              context,
              'Interests',
              'Music, Travel, Sports',
              Icons.favorite,
              AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFilterItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: Colors.white54,
          size: 20,
        ),
      ],
    );
  }

  static Widget _buildTipsSection(BuildContext context, AppThemeTokens? tokens) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tips for Better Matches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTipItem(
              context,
              'Complete your profile with photos and interests',
              Icons.check_circle,
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildTipItem(
              context,
              'Be specific about your preferences',
              Icons.check_circle,
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildTipItem(
              context,
              'Stay active and respond to messages',
              Icons.check_circle,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTipItem(BuildContext context, String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildMatchingScreen(BuildContext context, ConnectStateManager stateManager) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced Matching Animation
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
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
                    color: AppColors.primary,
                    strokeWidth: 4,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Finding People...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Looking for people within your selected distance range',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Enhanced Cancel Button
          OutlinedButton(
            onPressed: stateManager.stopMatching,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildConnectButton(BuildContext context, ConnectStateManager stateManager) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: Semantics(
        label: stateManager.isMatching 
          ? 'Stop matching with people' 
          : 'Start matching with people',
        button: true,
        child: ElevatedButton(
          onPressed: stateManager.isMatching ? stateManager.stopMatching : stateManager.startMatching,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: stateManager.isMatching ? Colors.red : AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            stateManager.isMatching ? 'Stop Matching' : 'Start Matching',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
            child: Column(
              children: [
                Expanded(
                  child: buildMainContent(context, stateManager),
                ),
                buildConnectButton(context, stateManager),
                const SizedBox(height: 16),
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
} 