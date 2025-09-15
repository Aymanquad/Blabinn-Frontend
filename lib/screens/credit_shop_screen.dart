import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/chatify_ad_service.dart';
import '../services/api_service.dart';
import '../services/billing_service.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../widgets/consistent_app_bar.dart';

class CreditShopScreen extends StatefulWidget {
  const CreditShopScreen({super.key});

  @override
  State<CreditShopScreen> createState() => _CreditShopScreenState();
}

class _CreditShopScreenState extends State<CreditShopScreen> {
  final BillingService _billingService = BillingService();
  final ChatifyAdService _adService = ChatifyAdService();

  // Display-only override for prices. Update here for new pricing.
  static const Map<String, String> _displayCreditPrices = {
    '8248-1325-3123-2424-credits-70': '₹49.00',
    '8248-1325-3123-2424-credits-150': '₹99.00',
    '8248-1325-3123-2424-credits-400': '₹249.00',
    '8248-1325-3123-2424-credits-900': '₹499.00',
    '8248-1325-3123-2424-credits-2000': '₹999.00',
  };

  @override
  void initState() {
    super.initState();
    _initializeBilling();
    _listenToPurchases();
    // Trigger interstitial on entering Credit Shop
    _adService.onEnterCreditShop();
  }

  void _listenToPurchases() {
    _billingService.purchaseStream.listen((purchaseDetails) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      }
    });
  }

  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Refresh user data from server
      final api = ApiService();
      final profile = await api.getMyProfile();
      if (profile['profile'] != null) {
        userProvider.updateCurrentUser(User.fromJson(profile['profile']));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully purchased ${purchaseDetails.productID}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Purchase successful but failed to update profile: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _initializeBilling() async {
    await _billingService.initialize();
    
    // Debug: Print available products
    print('🔍 CreditShop: Available products: ${_billingService.products.length}');
    for (final product in _billingService.products) {
      print('📦 CreditShop: ${product.id} - ${product.title} - ${product.price}');
    }
    
    if (_billingService.products.isEmpty) {
      print('⚠️ CreditShop: No products available. Check Google Play Console setup.');
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ConsistentAppBar(
        title: 'Credit Shop',
        showBackButton: false,
        actions: [
          if (_billingService.isAvailable)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () async {
                await _billingService.restorePurchases();
              },
              tooltip: 'Restore Purchases',
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: _billingService.loading
            ? const Center(child: CircularProgressIndicator())
            : _billingService.queryProductError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading products',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _billingService.queryProductError!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _HeaderBalance(),
                      const SizedBox(height: 16),
                      // Removed old credit bundles section; we now show only new pricing sections below
                      const SizedBox(height: 8),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Earn Credits (Watch Ads)'),
                      const SizedBox(height: 8),
                      _EarnCreditsCard(),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Premium Plans'),
                      const SizedBox(height: 8),
                      ..._buildPremiumPlans(theme),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildCreditBundles() {
    final creditProducts = _billingService.products
        .where((product) => product.id.startsWith('8248-1325-3123-2424-credits-'))
        .toList()
      ..sort((a, b) {
        // Extract credit amount and sort
        final aCredits = int.tryParse(a.id.replaceAll('8248-1325-3123-2424-credits-', '')) ?? 0;
        final bCredits = int.tryParse(b.id.replaceAll('8248-1325-3123-2424-credits-', '')) ?? 0;
        return aCredits.compareTo(bCredits);
      });

    return creditProducts.map((product) {
      final isMostPopular = product.id == '8248-1325-3123-2424-credits-150';
      final displayPrice = _displayCreditPrices[product.id] ?? product.price;
      return _CreditBundleCard(
        title: '${product.id.replaceAll('8248-1325-3123-2424-credits-', '')} credits',
        price: displayPrice,
        productId: product.id,
        isMostPopular: isMostPopular,
        billingService: _billingService,
      );
    }).toList();
  }

  List<Widget> _buildPremiumPlans(ThemeData theme) {
    // Desired order and fallback pricing with new Google Play product IDs
    final desired = [
      {'id': '8248-1325-3123-2424-premium-weekly', 'title': '1 Week', 'price': '₹299'},
      {'id': '8248-1325-3123-2424-premium-monthly', 'title': '1 Month', 'price': '₹599'},
      {'id': '8248-1325-3123-2424-premium-3months', 'title': '3 Months', 'price': '₹1499'},
      {'id': '8248-1325-3123-2424-premium-6months', 'title': '6 Months', 'price': '₹1999'},
      {'id': '8248-1325-3123-2424-premium-yearly', 'title': '12 Months', 'price': '₹2500'},
      {'id': '8248-1325-3123-2424-premium-lifetime', 'title': 'Lifetime', 'price': '₹4999'},
    ];

    final byId = {
      for (final p
          in _billingService.products.where((p) => p.id.startsWith('8248-1325-3123-2424-premium-')))
        p.id: p
    };

    return desired.map((plan) {
      final product = byId[plan['id']];
      final displayPrice = product?.price ?? plan['price'] as String;
      return _PremiumPlanCard(
        title: plan['title'] as String,
        subtitle:
            'Ad-free + instant match + boosts + super likes + unlimited friends',
        price: displayPrice,
        productId: plan['id'] as String,
        gradient: LinearGradient(colors: [
          theme.colorScheme.primary.withOpacity(0.15),
          theme.colorScheme.tertiary.withOpacity(0.08),
        ]),
        billingService: _billingService,
      );
    }).toList();
  }
}

class _HeaderBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.tertiary.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monetization_on_outlined, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Credits',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    )),
                const SizedBox(height: 2),
                Text('${user?.credits ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                print('🎯 Claim Daily: Starting process...');
                
                // Show two rewarded ads to claim daily bonus
                print('🎯 Claim Daily: Showing first rewarded ad...');
                final adOk1 = await ChatifyAdService().showRewardedAd();
                print('🎯 Claim Daily: First ad result: $adOk1');
                
                if (!adOk1) {
                  print('❌ Claim Daily: First ad failed, stopping process');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('First ad failed. Please try again.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                
                print('🎯 Claim Daily: Showing second rewarded ad...');
                final adOk2 = await ChatifyAdService().showRewardedAd();
                print('🎯 Claim Daily: Second ad result: $adOk2');
                
                if (!adOk2) {
                  print('❌ Claim Daily: Second ad failed, stopping process');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Second ad failed. Please try again.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                print('✅ Claim Daily: Both ads successful, claiming credits...');
                final api = ApiService();
                final result = await api.claimDailyCredits();
                print('🎯 Claim Daily: API result: $result');
                
                final awarded = (result['awarded'] as int?) ?? 0;
                final credits = (result['credits'] as int?) ?? 0;
                
                if (awarded > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Daily bonus claimed: +$awarded credits! Total: $credits'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  print('✅ Claim Daily: Successfully claimed $awarded credits');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Daily credits already claimed today'),
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                  );
                  print('ℹ️ Claim Daily: Already claimed today');
                }
              } catch (e) {
                print('❌ Claim Daily: Error occurred: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error claiming daily credits: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.redeem_outlined),
            label: const Text('Claim Daily'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
      ),
    );
  }
}

class _CreditBundleCard extends StatefulWidget {
  final String title;
  final String price;
  final String productId;
  final bool isMostPopular;
  final BillingService billingService;
  const _CreditBundleCard({
    required this.title,
    required this.price,
    required this.productId,
    this.isMostPopular = false,
    required this.billingService,
  });

  @override
  State<_CreditBundleCard> createState() => _CreditBundleCardState();
}

class _CreditBundleCardState extends State<_CreditBundleCard> {
  bool _loading = false;

  Future<void> _buy() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // Find the product in billing service
      final product = widget.billingService.products
          .firstWhere(
            (p) => p.id == widget.productId,
            orElse: () => throw Exception('Product not found: ${widget.productId}'),
          );

      // Initiate purchase through billing service
      await widget.billingService.buyProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase initiated for ${widget.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Purchase failed: $e';
        if (e.toString().contains('Product not found')) {
          errorMessage = 'Product not available. Please check Google Play Console setup.';
        } else if (e.toString().contains('Bad state: No element')) {
          errorMessage = 'Product not found. Please ensure products are created in Google Play Console.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.colorScheme.surface.withOpacity(0.9),
          theme.colorScheme.surface.withOpacity(0.75),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monetization_on_outlined, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (widget.isMostPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.purpleAccent.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Most popular',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.price,
                      style: TextStyle(
                          fontSize: 14, color: theme.colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _loading ? null : _buy,
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Buy'),
            )
          ],
        ),
      ),
    );
  }
}

class _PremiumPlanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final String productId;
  final Gradient? gradient;
  final BillingService billingService;
  const _PremiumPlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.productId,
    this.gradient,
    required this.billingService,
  });

  @override
  State<_PremiumPlanCard> createState() => _PremiumPlanCardState();
}

class _PremiumPlanCardState extends State<_PremiumPlanCard> {
  bool _loading = false;

  Future<void> _buy() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // Find the product in billing service
      final product = widget.billingService.products
          .firstWhere(
            (p) => p.id == widget.productId,
            orElse: () => throw Exception('Product not found: ${widget.productId}'),
          );

      // Initiate purchase through billing service
      await widget.billingService.buyProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase initiated for ${widget.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Purchase failed: $e';
        if (e.toString().contains('Product not found')) {
          errorMessage = 'Product not available. Please check Google Play Console setup.';
        } else if (e.toString().contains('Bad state: No element')) {
          errorMessage = 'Product not found. Please ensure products are created in Google Play Console.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: widget.gradient ??
            LinearGradient(colors: [
              theme.colorScheme.surface.withOpacity(0.9),
              theme.colorScheme.surface.withOpacity(0.75),
            ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(widget.price,
                    style: TextStyle(
                        fontSize: 14, color: theme.colorScheme.primary)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loading ? null : _buy,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10)),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))
                      : const Text('Activate'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EarnCreditsCard extends StatefulWidget {
  @override
  State<_EarnCreditsCard> createState() => _EarnCreditsCardState();
}

class _EarnCreditsCardState extends State<_EarnCreditsCard> {
  bool _loading = false;

  Future<void> _watchAdForCredits(int amount) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final adOk = await ChatifyAdService().showRewardedAd();
      if (!adOk) return;

      final api = ApiService();
      final result = await api.grantAdCredits(
          amount: amount, trigger: 'credit_shop_reward');
      final granted = (result['granted'] as int?) ?? amount;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Credits awarded: +$granted')),
        );
      }

      // Refresh user credits display
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final profile = await ApiService().getMyProfile();
        if (profile['profile'] != null) {
          userProvider.updateCurrentUser(User.fromJson(profile['profile']));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to award credits: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.colorScheme.surface.withOpacity(0.9),
          theme.colorScheme.surface.withOpacity(0.75),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Watch a short ad to earn credits'),
          const SizedBox(height: 12),
          Row(
            children: [
              _earnButton('Watch Ad (+10)', 10),
              const SizedBox(width: 12),
              _earnButton('Watch Ad (+20)', 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earnButton(String label, int amount) {
    return Expanded(
      child: ElevatedButton(
        onPressed: _loading ? null : () => _watchAdForCredits(amount),
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      ),
    );
  }
}
