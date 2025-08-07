import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'connect_state_manager.dart';

class ConnectFilterComponents {
  static Widget buildFilterDialog(BuildContext context, ConnectStateManager stateManager) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDistanceFilter(context, stateManager),
                  const SizedBox(height: 16),
                  buildLanguageFilter(context, stateManager),

                  // Premium features
                  if (stateManager.isPremium) ...[
                    const SizedBox(height: 16),
                    buildAgeRangeFilter(context, stateManager),
                    const SizedBox(height: 16),
                    buildInterestsFilter(context, stateManager),
                  ] else ...[
                    const SizedBox(height: 16),
                    buildPremiumFeatureCard(context, stateManager),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    stateManager.initializeFilters();
                    Navigator.pop(context);
                    stateManager.onStateChanged();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    stateManager.onStateChanged();
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildDistanceFilter(BuildContext context, ConnectStateManager stateManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distance Range',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: stateManager.filters['distance'] ?? '1-5',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: AppConstants.distanceRanges.map((range) {
            return DropdownMenuItem<String>(
              value: range['value'] as String,
              child: Text(range['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            stateManager.filters['distance'] = value;
            stateManager.onStateChanged();
          },
        ),
      ],
    );
  }

  static Widget buildLanguageFilter(BuildContext context, ConnectStateManager stateManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: stateManager.filters['language'] ?? 'any',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.language),
          ),
          items: const [
            DropdownMenuItem(value: 'any', child: Text('Any Language')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'es', child: Text('Spanish')),
            DropdownMenuItem(value: 'fr', child: Text('French')),
            DropdownMenuItem(value: 'de', child: Text('German')),
            DropdownMenuItem(value: 'it', child: Text('Italian')),
            DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
            DropdownMenuItem(value: 'ru', child: Text('Russian')),
            DropdownMenuItem(value: 'ja', child: Text('Japanese')),
            DropdownMenuItem(value: 'ko', child: Text('Korean')),
            DropdownMenuItem(value: 'zh', child: Text('Chinese')),
          ],
          onChanged: (value) {
            stateManager.filters['language'] = value;
            stateManager.onStateChanged();
          },
        ),
      ],
    );
  }

  static Widget buildPremiumFeatureCard(BuildContext context, ConnectStateManager stateManager) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Premium Features',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Age Range & Interest Matching',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Get better matches with advanced age filters and interest-based connections.',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showPremiumDialog(context),
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Premium'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(color: AppColors.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAgeRangeFilter(BuildContext context, ConnectStateManager stateManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Age Range',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.star, color: AppColors.warning, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: stateManager.filters['ageRange'] ?? 'all',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.person),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Ages')),
            DropdownMenuItem(value: '18-25', child: Text('18-25')),
            DropdownMenuItem(value: '26-35', child: Text('26-35')),
            DropdownMenuItem(value: '36-45', child: Text('36-45')),
            DropdownMenuItem(value: '46+', child: Text('46+')),
          ],
          onChanged: (value) {
            stateManager.filters['ageRange'] = value;
            stateManager.onStateChanged();
          },
        ),
      ],
    );
  }

  static Widget buildInterestsFilter(BuildContext context, ConnectStateManager stateManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Interests',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.star, color: AppColors.warning, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: AppConstants.availableInterests.map((interest) {
            final isSelected =
                (stateManager.filters['interests'] as List?)?.contains(interest) ?? false;
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                if (stateManager.filters['interests'] == null) {
                  stateManager.filters['interests'] = [];
                }
                if (selected) {
                  stateManager.filters['interests'].add(interest);
                } else {
                  stateManager.filters['interests'].remove(interest);
                }
                stateManager.onStateChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  static void showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Premium Features'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upgrade to Premium to access:'),
            const SizedBox(height: 16),
            ...AppConstants.premiumFeatures.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text(
              'Premium features include advanced age filters and interest matching for better connections.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement premium upgrade
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
} 