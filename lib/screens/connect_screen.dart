import 'package:flutter/material.dart';
import '../core/constants.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isMatching = false;
  Map<String, dynamic> _filters = {};
  bool _isPremium = false; // Simulated premium status - would come from user provider

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    _filters = {
      'distance': '1-5', // Default to closest range
      'language': 'any',
      // Premium features - only available for premium users
      'ageRange': 'all',
      'interests': [],
    };
  }

  void _startMatching() {
    if (_isMatching) return;

    setState(() {
      _isMatching = true;
    });

    // TODO: Implement actual matching logic
  }

  void _stopMatching() {
    if (!_isMatching) return;

    setState(() {
      _isMatching = false;
    });

    // TODO: Stop matching logic
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterDialog(),
    );
  }

  void _showPremiumDialog() {
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
                  const Icon(Icons.check, color: AppColors.success, size: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.connect),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _showPremiumDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _buildMainContent(),
            ),
            _buildConnectButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isMatching) {
      return _buildMatchingScreen();
    }

    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Find New People',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Connect with people within your preferred distance range',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _buildFilterSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    final selectedRange = AppConstants.distanceRanges.firstWhere(
      (range) => range['value'] == _filters['distance'],
      orElse: () => AppConstants.distanceRanges[0],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 16),
                const SizedBox(width: 8),
                const Text('Current Filters'),
                const Spacer(),
                if (!_isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFilterItem('Distance', selectedRange['label']),
            _buildFilterItem('Language', _filters['language'] ?? 'Any'),
            
            // Premium features
            if (_isPremium) ...[
              _buildFilterItem('Age Range', _filters['ageRange'] ?? 'All'),
              if (_filters['interests']?.isNotEmpty == true)
                _buildFilterItem('Interests', '${_filters['interests'].length} selected'),
            ] else ...[
              _buildPremiumFilterItem('Age Range', 'Premium Only'),
              _buildPremiumFilterItem('Interests', 'Premium Only'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPremiumFilterItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: AppColors.warning),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                Icon(
                  Icons.search,
                  size: 40,
                  color: AppColors.primary,
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _stopMatching,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isMatching ? _stopMatching : _startMatching,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _isMatching ? Colors.red : AppColors.primary,
        ),
        child: Text(
          _isMatching ? 'Stop Matching' : 'Start Matching',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterDialog() {
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
                  _buildDistanceFilter(),
                  const SizedBox(height: 16),
                  _buildLanguageFilter(),
                  
                  // Premium features
                  if (_isPremium) ...[
                    const SizedBox(height: 16),
                    _buildAgeRangeFilter(),
                    const SizedBox(height: 16),
                    _buildInterestsFilter(),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildPremiumFeatureCard(),
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
                    _initializeFilters();
                    Navigator.pop(context);
                    setState(() {});
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
                    setState(() {});
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

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distance Range', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters['distance'] ?? '1-5',
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
            setState(() {
              _filters['distance'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLanguageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters['language'] ?? 'any',
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
            setState(() {
              _filters['language'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPremiumFeatureCard() {
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
              const Text(
                'Premium Features',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Age Range & Interest Matching',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Get better matches with advanced age filters and interest-based connections.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showPremiumDialog,
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

  // Premium-only filters (kept for premium users)
  Widget _buildAgeRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Age Range', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.star, color: AppColors.warning, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters['ageRange'] ?? 'all',
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
            setState(() {
              _filters['ageRange'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.star, color: AppColors.warning, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            'Music', 'Sports', 'Travel', 'Food', 'Technology',
            'Art', 'Books', 'Movies', 'Gaming', 'Fitness',
            'Photography', 'Cooking', 'Dancing', 'Writing', 'Nature'
          ].map((interest) {
            final isSelected = (_filters['interests'] as List?)?.contains(interest) ?? false;
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (_filters['interests'] == null) {
                    _filters['interests'] = [];
                  }
                  if (selected) {
                    _filters['interests'].add(interest);
                  } else {
                    _filters['interests'].remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
} 