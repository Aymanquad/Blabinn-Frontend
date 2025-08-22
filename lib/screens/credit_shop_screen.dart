import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class CreditShopScreen extends StatelessWidget {
  const CreditShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Shop'),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _HeaderBalance(),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Buy Credits'),
            const SizedBox(height: 8),
            // Credit bundles in increasing order
            _CreditBundleCard(title: '70 credits', price: '₹49', productId: 'credits_70'),
            _CreditBundleCard(
              title: '150 credits',
              price: '₹99',
              productId: 'credits_150',
              isMostPopular: true,
            ),
            _CreditBundleCard(title: '400 credits', price: '₹249', productId: 'credits_400'),
            _CreditBundleCard(title: '900 credits', price: '₹499', productId: 'credits_900'),
            _CreditBundleCard(title: '2000 credits', price: '₹999', productId: 'credits_2000'),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Premium Plans'),
            const SizedBox(height: 8),
                         _PremiumPlanCard(
               title: 'Monthly Premium',
               subtitle: '120 daily credits + media folder + unlimited image sending to friends + ads-free experience',
               price: '₹299/month',
               productId: 'premium_monthly',
               gradient: LinearGradient(colors: [
                 theme.colorScheme.primary.withOpacity(0.15),
                 theme.colorScheme.tertiary.withOpacity(0.08),
               ]),
             ),
             _PremiumPlanCard(
               title: 'Yearly Premium',
               subtitle: '300 daily credits + media folder + unlimited image sending to friends + ads-free experience',
               price: '₹2499/year',
               productId: 'premium_yearly',
               gradient: LinearGradient(colors: [
                 theme.colorScheme.secondary.withOpacity(0.15),
                 theme.colorScheme.primary.withOpacity(0.08),
               ]),
             ),
          ],
        ),
      ),
    );
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
  const _CreditBundleCard({required this.title, required this.price, required this.productId, this.isMostPopular = false});

  @override
  State<_CreditBundleCard> createState() => _CreditBundleCardState();
}

class _CreditBundleCardState extends State<_CreditBundleCard> {
  bool _loading = false;

  Future<void> _buy() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final api = ApiService();
      await api.verifyPurchase(
        platform: Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android',
        productId: widget.productId,
        purchaseType: 'consumable',
      );
      // Refresh credits from server
      final balance = await api.getCreditBalance();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        final newCredits = (balance['credits'] as int?) ?? userProvider.currentUser!.credits;
        userProvider.updateCurrentUser(userProvider.currentUser!.copyWith(credits: newCredits));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${widget.title}')), 
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
  const _PremiumPlanCard({required this.title, required this.subtitle, required this.price, required this.productId, this.gradient});

  @override
  State<_PremiumPlanCard> createState() => _PremiumPlanCardState();
}

class _PremiumPlanCardState extends State<_PremiumPlanCard> {
  bool _loading = false;

  Future<void> _buy() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final api = ApiService();
      await api.verifyPurchase(
        platform: Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android',
        productId: widget.productId,
        purchaseType: 'subscription',
      );
             // Refresh profile
       final userProvider = Provider.of<UserProvider>(context, listen: false);
       try {
         final profile = await api.getMyProfile();
         if (profile['profile'] != null) {
           userProvider.updateCurrentUser(User.fromJson(profile['profile']));
         } else if (userProvider.currentUser != null) {
           userProvider.updateCurrentUser(userProvider.currentUser!.copyWith(
             isPremium: true,
             adsFree: true, // Enable ads-free for premium users
           ));
         }
       } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activated ${widget.title}')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activation failed: $e')),
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


