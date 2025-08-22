import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/api_service.dart';
import '../services/billing_service.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class CreditShopScreen extends StatefulWidget {
  const CreditShopScreen({super.key});

  @override
  State<CreditShopScreen> createState() => _CreditShopScreenState();
}

class _CreditShopScreenState extends State<CreditShopScreen> {
  final BillingService _billingService = BillingService();

  @override
  void initState() {
    super.initState();
    _initializeBilling();
    _listenToPurchases();
  }

  void _listenToPurchases() {
    _billingService.purchaseStream.listen((purchaseDetails) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      }
    });
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
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
            content: Text('Successfully purchased ${purchaseDetails.productID}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase successful but failed to update profile: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _initializeBilling() async {
    await _billingService.initialize();
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
      appBar: AppBar(
        title: const Text('Credit Shop'),
        centerTitle: true,
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
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading products',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _billingService.queryProductError!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _HeaderBalance(),
                      const SizedBox(height: 16),
                      _SectionHeader(title: 'Buy Credits'),
                      const SizedBox(height: 8),
                      // Credit bundles from billing service
                      ..._buildCreditBundles(),
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
        .where((product) => product.id.startsWith('credits_'))
        .toList()
      ..sort((a, b) {
        // Extract credit amount and sort
        final aCredits = int.tryParse(a.id.replaceAll('credits_', '')) ?? 0;
        final bCredits = int.tryParse(b.id.replaceAll('credits_', '')) ?? 0;
        return aCredits.compareTo(bCredits);
      });

    return creditProducts.map((product) {
      final isMostPopular = product.id == 'credits_150';
      return _CreditBundleCard(
        title: '${product.id.replaceAll('credits_', '')} credits',
        price: product.price,
        productId: product.id,
        isMostPopular: isMostPopular,
        billingService: _billingService,
      );
    }).toList();
  }

  List<Widget> _buildPremiumPlans(ThemeData theme) {
    final premiumProducts = _billingService.products
        .where((product) => product.id.startsWith('premium_'))
        .toList();

    return premiumProducts.map((product) {
      final isMonthly = product.id == 'premium_monthly';
      return _PremiumPlanCard(
        title: isMonthly ? 'Monthly Premium' : 'Yearly Premium',
        subtitle: isMonthly 
            ? '120 daily credits + media folder + unlimited image sending to friends + ads-free experience'
            : '300 daily credits + media folder + unlimited image sending to friends + ads-free experience',
        price: product.price,
        productId: product.id,
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
                Text('Available Credits', style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                )),
                const SizedBox(height: 2),
                Text('${user?.credits ?? 0}', style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                )),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                final api = ApiService();
                final result = await api.claimDailyCredits();
                final awarded = (result['awarded'] as int?) ?? 0;
                if (awarded > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Daily bonus claimed: +$awarded')),
                  );
                }
              } catch (_) {}
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
          .firstWhere((p) => p.id == widget.productId);
      
      // Initiate purchase through billing service
      await widget.billingService.buyProduct(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase initiated for ${widget.title}')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (widget.isMostPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Most popular',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.price, style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _loading ? null : _buy,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
              child: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
          .firstWhere((p) => p.id == widget.productId);
      
      // Initiate purchase through billing service
      await widget.billingService.buyProduct(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase initiated for ${widget.title}')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
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
        gradient: widget.gradient ?? LinearGradient(colors: [
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
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(widget.subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(widget.price, style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loading ? null : _buy,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
                  child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2,)) : const Text('Activate'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


