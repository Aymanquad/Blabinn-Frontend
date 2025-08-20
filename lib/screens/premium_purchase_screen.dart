import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/billing_service.dart';
import '../widgets/premium_popup.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<PremiumPurchaseScreen> createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  bool _isLoading = true;
  bool _isPurchasing = false;
  List<ProductDetails> _premiumProducts = [];
  List<ProductDetails> _creditProducts = [];

  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    try {
      final success = await billingService.initialize();
      if (success) {
        _loadProducts();
      } else {
        _showError('Billing not available');
      }
    } catch (e) {
      _showError('Failed to initialize billing: $e');
    }
  }

  void _loadProducts() {
    setState(() {
      _premiumProducts = billingService.getPremiumProducts();
      _creditProducts = billingService.getCreditProducts();
      _isLoading = false;
    });
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await billingService.purchaseProduct(product);
      if (!success) {
        _showError('Failed to initiate purchase');
      }
    } catch (e) {
      _showError('Purchase error: $e');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium & Credits'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Section
                  _buildSectionHeader('Premium Subscription', Icons.diamond),
                  const SizedBox(height: 16),
                  if (_premiumProducts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Premium products not available yet. Please check back later.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ..._premiumProducts.map((product) => _buildProductCard(
                          product,
                          isPremium: true,
                        )),
                  
                  const SizedBox(height: 32),
                  
                  // Credits Section
                  _buildSectionHeader('Buy Credits', Icons.monetization_on),
                  const SizedBox(height: 16),
                  if (_creditProducts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Credit products not available yet. Please check back later.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ..._creditProducts.map((product) => _buildProductCard(
                          product,
                          isPremium: false,
                        )),
                  
                  const SizedBox(height: 32),
                  
                  // Premium Benefits
                  _buildPremiumBenefits(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductDetails product, {required bool isPremium}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isPurchasing ? null : () => _purchaseProduct(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isPremium ? 'Subscribe' : 'Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefits() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Benefits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
                                     _buildBenefitItem('Upload profile pictures'),
                         _buildBenefitItem('Send & receive images in chats (10 credits)'),
                         _buildBenefitItem('Gender preferences for random connections (20 credits)'),
                         _buildBenefitItem('Store images in media folder'),
                         _buildBenefitItem('Priority customer support'),
                         _buildBenefitItem('Ad-free experience'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
