import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/billing_service.dart';
import '../services/matching_service.dart';
import '../models/user.dart';
import '../widgets/user_type_badge.dart';
import '../widgets/chatify_banner_ad.dart';
import '../core/theme_extensions.dart';
import '../providers/user_provider.dart';

/// Subscription Plans Screen
/// Shows premium subscription plans with Indian pricing
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final BillingService _billingService = BillingService();
  final MatchingService _matchingService = MatchingService();
  
  bool _isLoading = false;
  String? _error;

  // Indian pricing plans with new Google Play product IDs
  final List<Map<String, dynamic>> _plans = [
    {
      'id': '8248-1325-3123-2424-premium-weekly',
      'title': '1 Week',
      'price': '₹299',
      'duration': '1 week',
      'originalPrice': null,
      'discount': null,
      'features': [
        'Ad-free experience',
        'Instant match',
        '2 Boosts',
        '5 Super likes',
        'Unlimited "Who Liked You"',
        'Unlimited friends',
        'Premium badge',
      ],
      'popular': false,
    },
    {
      'id': '8248-1325-3123-2424-premium-monthly',
      'title': '1 Month',
      'price': '₹599',
      'duration': '1 month',
      'originalPrice': '₹1,198',
      'discount': '50% OFF',
      'features': [
        'Ad-free experience',
        'Instant match',
        '2 Boosts',
        '5 Super likes',
        'Unlimited "Who Liked You"',
        'Unlimited friends',
        'Premium badge',
      ],
      'popular': true,
    },
    {
      'id': '8248-1325-3123-2424-premium-3months',
      'title': '3 Months',
      'price': '₹1499',
      'duration': '3 months',
      'originalPrice': '₹3,597',
      'discount': '59% OFF',
      'features': [
        'Ad-free experience',
        'Instant match',
        '2 Boosts',
        '5 Super likes',
        'Unlimited "Who Liked You"',
        'Unlimited friends',
        'Premium badge',
      ],
      'popular': false,
    },
    {
      'id': '8248-1325-3123-2424-premium-6months',
      'title': '6 Months',
      'price': '₹1999',
      'duration': '6 months',
      'originalPrice': '₹5,994',
      'discount': '73% OFF',
      'features': [
        'Ad-free experience',
        'Instant match',
        '2 Boosts',
        '5 Super likes',
        'Unlimited "Who Liked You"',
        'Unlimited friends',
        'Premium badge',
      ],
      'popular': false,
    },
    {
      'id': '8248-1325-3123-2424-premium-yearly',
      'title': '12 Months',
      'price': '₹2500',
      'duration': '1 year',
      'originalPrice': '₹7,188',
      'discount': '65% OFF',
      'features': [
        'Ad-free experience',
        'Instant match',
        '2 Boosts',
        '5 Super likes',
        'Unlimited "Who Liked You"',
        'Unlimited friends',
        'Premium badge',
      ],
      'popular': false,
    },
    {
      'id': '8248-1325-3123-2424-premium-lifetime',
      'title': 'Lifetime',
      'price': '₹4999',
      'duration': 'Lifetime',
      'originalPrice': null,
      'discount': null,
      'features': [
        'Ad-free experience',
        'Instant match',
        '2 Boosts',
        '5 Super likes',
        'Unlimited "Who Liked You"',
        'Unlimited friends',
        'Premium badge',
        'Lifetime access',
      ],
      'popular': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    if (!_billingService.isAvailable) {
      await _billingService.initialize();
    }
  }

  Future<void> _purchasePlan(String planId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Find the product details
      final product = _billingService.products.firstWhere(
        (p) => p.id == planId,
        orElse: () => throw Exception('Product not found'),
      );

      // Purchase the product
      await _billingService.buyProduct(product);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premium activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh user data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.refreshUser();
        
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Plans'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _billingService.restorePurchases,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Ad
          const ChatifyBannerAd(),
          
          // Current User Status
          if (currentUser != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentUser.isPremiumUser 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(tokens.radiusM),
                border: Border.all(
                  color: currentUser.isPremiumUser 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    currentUser.isPremiumUser ? Icons.star : Icons.star_border,
                    color: currentUser.isPremiumUser ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.isPremiumUser 
                              ? 'Premium Active' 
                              : 'Free Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUser.isPremiumUser) ...[
                          Text(
                            'Plan: ${currentUser.premiumPlan ?? 'Unknown'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Upgrade to unlock premium features',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  UserTypeBadge(user: currentUser, compact: true),
                ],
              ),
            ),
          ],

          // Plans List
          Expanded(
            child: _buildPlansList(theme, tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(ThemeData theme, AppThemeTokens tokens) {
    if (_billingService.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading plans',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeBilling,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return _buildPlanCard(plan, theme, tokens);
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, ThemeData theme, AppThemeTokens tokens) {
    final isPopular = plan['popular'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: isPopular 
            ? Colors.purple.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusL),
          side: BorderSide(
            color: isPopular 
                ? Colors.purple.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan['title'],
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'POPULAR',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              plan['price'],
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '/ ${plan['duration']}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        if (plan['originalPrice'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                plan['originalPrice'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.5),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plan['discount'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Features
              ...(plan['features'] as List<String>).map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),

              const SizedBox(height: 20),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _purchasePlan(plan['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular 
                        ? Colors.purple
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusM),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Get ${plan['title']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
