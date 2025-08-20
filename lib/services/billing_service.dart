import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../models/user.dart';
import '../core/config.dart';
import 'api_service.dart';

/// Billing Service for Google Play Billing
/// Handles subscriptions and consumable products (credits)
class BillingService {
  static const String _tag = 'BillingService';
  
  // Product IDs - Update these with your actual Play Console product IDs
  static const String _premiumMonthlyId = 'premium_monthly';
  static const String _premiumYearlyId = 'premium_yearly';
  static const String _credits100Id = 'credits_100';
  static const String _credits500Id = 'credits_500';
  static const String _credits1000Id = 'credits_1000';
  
  // Stream controllers
  final StreamController<List<ProductDetails>> _productsController = 
      StreamController<List<ProductDetails>>.broadcast();
  final StreamController<List<PurchaseDetails>> _purchasesController = 
      StreamController<List<PurchaseDetails>>.broadcast();
  
  // In-app purchase instance
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Available products
  List<ProductDetails> _products = [];
  
  // Streams
  Stream<List<ProductDetails>> get productsStream => _productsController.stream;
  Stream<List<PurchaseDetails>> get purchasesStream => _purchasesController.stream;
  
  // Getters
  List<ProductDetails> get products => _products;
  
  /// Initialize billing service
  Future<bool> initialize() async {
    try {
      debugPrint('$_tag: Initializing billing service...');
      
      // Check if billing is available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('$_tag: Billing not available');
        return false;
      }
      
      // Set up purchase stream listener
      _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => debugPrint('$_tag: Purchase stream done'),
        onError: (error) => debugPrint('$_tag: Purchase stream error: $error'),
      );
      
      // Load products
      await loadProducts();
      
      debugPrint('$_tag: Billing service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('$_tag: Failed to initialize billing service: $e');
      return false;
    }
  }
  
  /// Load available products from Play Console
  Future<void> loadProducts() async {
    try {
      debugPrint('$_tag: Loading products...');
      
      final Set<String> productIds = {
        _premiumMonthlyId,
        _premiumYearlyId,
        _credits100Id,
        _credits500Id,
        _credits1000Id,
      };
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('$_tag: Products not found: ${response.notFoundIDs}');
      }
      
      if (response.error != null) {
        debugPrint('$_tag: Error loading products: ${response.error}');
        return;
      }
      
      _products = response.productDetails;
      _productsController.add(_products);
      
      debugPrint('$_tag: Loaded ${_products.length} products');
      for (final product in _products) {
        debugPrint('$_tag: Product: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      debugPrint('$_tag: Error loading products: $e');
    }
  }
  
  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      debugPrint('$_tag: Product not found: $productId');
      return null;
    }
  }
  
  /// Get premium subscription products
  List<ProductDetails> getPremiumProducts() {
    return _products.where((product) => 
        product.id == _premiumMonthlyId || product.id == _premiumYearlyId).toList();
  }
  
  /// Get credit products
  List<ProductDetails> getCreditProducts() {
    return _products.where((product) => 
        product.id == _credits100Id || 
        product.id == _credits500Id || 
        product.id == _credits1000Id).toList();
  }
  
  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      debugPrint('$_tag: Purchasing product: ${product.id}');
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      
      bool success = false;
      
      if (product.id == _premiumMonthlyId || product.id == _premiumYearlyId) {
        // Subscription purchase
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Consumable purchase (credits)
        success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
      
      if (success) {
        debugPrint('$_tag: Purchase initiated successfully');
      } else {
        debugPrint('$_tag: Failed to initiate purchase');
      }
      
      return success;
    } catch (e) {
      debugPrint('$_tag: Error purchasing product: $e');
      return false;
    }
  }
  
  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('$_tag: Purchase update received: ${purchaseDetailsList.length} purchases');
    
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('$_tag: Processing purchase: ${purchaseDetails.productID} - ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('$_tag: Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('$_tag: Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('$_tag: Purchase canceled: ${purchaseDetails.productID}');
      }
    }
    
    _purchasesController.add(purchaseDetailsList);
  }
  
  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('$_tag: Handling successful purchase: ${purchaseDetails.productID}');
      
      // Verify purchase with backend
      final bool verified = await _verifyPurchaseWithBackend(purchaseDetails);
      
      if (verified) {
        // Complete the purchase
        await _inAppPurchase.completePurchase(purchaseDetails);
        
        debugPrint('$_tag: Purchase completed successfully');
      } else {
        debugPrint('$_tag: Purchase verification failed');
        // Don't complete the purchase if verification failed
      }
    } catch (e) {
      debugPrint('$_tag: Error handling successful purchase: $e');
    }
  }
  
  /// Verify purchase with backend
  Future<bool> _verifyPurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('$_tag: Verifying purchase with backend...');
      
      // Extract purchase token (Android specific)
      String? purchaseToken;
      if (Platform.isAndroid) {
        final GooglePlayPurchaseDetails googlePlayPurchaseDetails = 
            purchaseDetails as GooglePlayPurchaseDetails;
        purchaseToken = googlePlayPurchaseDetails.billingClientPurchase.purchaseToken;
      }
      
      // Prepare verification data
      final Map<String, dynamic> verificationData = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'productId': purchaseDetails.productID,
        'purchaseToken': purchaseToken,
        'purchaseType': _isSubscription(purchaseDetails.productID) ? 'subscription' : 'consumable',
        'orderId': purchaseDetails.purchaseID,
      };
      
      // Send to backend for verification
      final response = await _sendVerificationRequest(verificationData);
      final responseData = _handleResponse(response);
      
      if (responseData['success'] == true) {
        debugPrint('$_tag: Purchase verified successfully');
        return true;
      } else {
        debugPrint('$_tag: Purchase verification failed: ${responseData['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('$_tag: Error verifying purchase: $e');
      return false;
    }
  }
  
  /// Send verification request to backend
  Future<http.Response> _sendVerificationRequest(Map<String, dynamic> data) async {
    try {
      final apiService = ApiService();
      await apiService.initialize();
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/billing/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Handle response (copied from ApiService)
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      // Handle both direct data and wrapped data responses
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'HTTP ${response.statusCode}');
    }
  }
  
  /// Check if product is a subscription
  bool _isSubscription(String productId) {
    return productId == _premiumMonthlyId || productId == _premiumYearlyId;
  }
  
  /// Restore purchases (for iOS)
  Future<void> restorePurchases() async {
    try {
      debugPrint('$_tag: Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('$_tag: Error restoring purchases: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _productsController.close();
    _purchasesController.close();
  }
}

/// Singleton instance
final BillingService billingService = BillingService();
