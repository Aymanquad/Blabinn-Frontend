import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../services/api_service.dart';

class BillingService {
  static const bool _kAutoConsume = true;
  // Cross border products (8248-1325-3123-2424)
  static const String _kCredit70 = '8248-1325-3123-2424-credits-70';
  static const String _kCredit150 = '8248-1325-3123-2424-credits-150';
  static const String _kCredit400 = '8248-1325-3123-2424-credits-400';
  static const String _kCredit900 = '8248-1325-3123-2424-credits-900';
  static const String _kCredit2000 = '8248-1325-3123-2424-credits-2000';
  static const String _kPremiumWeekly = '8248-1325-3123-2424-premium-weekly';
  static const String _kPremiumMonthly = '8248-1325-3123-2424-premium-monthly';
  static const String _kPremium3Months = '8248-1325-3123-2424-premium-3months';
  static const String _kPremium6Months = '8248-1325-3123-2424-premium-6months';
  static const String _kPremiumYearly = '8248-1325-3123-2424-premium-yearly';
  static const String _kPremiumLifetime = '8248-1325-3123-2424-premium-lifetime';

  static const Set<String> _kIds = <String>{
    _kCredit70,
    _kCredit150,
    _kCredit400,
    _kCredit900,
    _kCredit2000,
    _kPremiumWeekly,
    _kPremiumMonthly,
    _kPremium3Months,
    _kPremium6Months,
    _kPremiumYearly,
    _kPremiumLifetime,
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  // Getters for UI
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  String? get queryProductError => _queryProductError;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;

  // Stream controller for purchase updates
  final StreamController<PurchaseDetails> _purchaseController = 
      StreamController<PurchaseDetails>.broadcast();
  
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  Future<void> initialize() async {
    print('🔧 BillingService: Initializing...');
    
    final bool available = await _inAppPurchase.isAvailable();
    print('🔧 BillingService: In-app purchase available: $available');
    
    if (!available) {
      _isAvailable = false;
      _loading = false;
      print('❌ BillingService: In-app purchase not available');
      return;
    }

    // iOS delegate setup can be added later if needed
    // For now, we'll focus on Android implementation

    print('🔧 BillingService: Querying product details for IDs: $_kIds');
    final ProductDetailsResponse productResponse = 
        await _inAppPurchase.queryProductDetails(_kIds);

    if (productResponse.notFoundIDs.isNotEmpty) {
      print('❌ BillingService: Product IDs not found: ${productResponse.notFoundIDs}');
      print('🔍 BillingService: This means these products need to be created in Google Play Console');
    }

    print('✅ BillingService: Found ${productResponse.productDetails.length} products');
    for (final product in productResponse.productDetails) {
      print('📦 BillingService: Available product: ${product.id} - ${product.title} - ${product.price}');
    }
    _products = productResponse.productDetails;
    _queryProductError = productResponse.error?.message;
    _isAvailable = available;
    _loading = false;

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          _verifyPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
      _purchases.add(purchaseDetails);
      _purchaseController.add(purchaseDetails);
    }
  }

  void _onPurchaseStreamDone() {
    _subscription.cancel();
  }

  void _onPurchaseStreamError(dynamic error) {
    print('Purchase stream error: $error');
  }

  void _handleError(IAPError error) {
    print('Purchase error: ${error.message}');
    print('Error code: ${error.code}');
    print('Error details: ${error.details}');
    
    // Provide more specific error information
    switch (error.code) {
      case 'BILLING_RESPONSE_RESULT_DEVELOPER_ERROR':
        print('Developer Error: Check Google Play Console configuration');
        print('- Verify app is published to internal testing');
        print('- Verify product IDs are active');
        print('- Verify test account is added');
        break;
      case 'BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED':
        print('Item not owned: User tried to consume an item they don\'t own');
        break;
      case 'BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE':
        print('Item unavailable: Product not available for purchase');
        break;
      case 'BILLING_RESPONSE_RESULT_USER_CANCELED':
        print('User canceled: Purchase was canceled by user');
        break;
      default:
        print('Unknown billing error: ${error.code}');
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final apiService = ApiService();
      
      // Get platform
      final String platform = Platform.isIOS ? 'ios' : 'android';
      
      // Get purchase token (Android) or transaction ID (iOS)
      String purchaseToken = '';
      if (Platform.isAndroid) {
        final GooglePlayPurchaseDetails googlePlayPurchaseDetails = 
            purchaseDetails as GooglePlayPurchaseDetails;
        purchaseToken = googlePlayPurchaseDetails.billingClientPurchase.purchaseToken;
      } else if (Platform.isIOS) {
        final AppStorePurchaseDetails appStorePurchaseDetails = 
            purchaseDetails as AppStorePurchaseDetails;
        purchaseToken = appStorePurchaseDetails.skPaymentTransaction.transactionIdentifier ?? '';
      }

      // Determine purchase type
      final String purchaseType = purchaseDetails.productID.startsWith('8248-1325-3123-2424-premium-')
          ? 'subscription'
          : 'consumable';

      // Verify with backend
      await apiService.verifyPurchase(
        platform: platform,
        productId: purchaseDetails.productID,
        purchaseToken: purchaseToken,
        purchaseType: purchaseType,
        orderId: purchaseDetails.purchaseID ?? '',
      );

      print('Purchase verified successfully: ${purchaseDetails.productID}');
    } catch (e) {
      print('Failed to verify purchase: $e');
      // You might want to show an error message to the user here
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    if (product.id == _kPremiumWeekly ||
        product.id == _kPremiumMonthly ||
        product.id == _kPremiumYearly ||
        product.id == _kPremiumLifetime) {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription.cancel();
    _purchaseController.close();
  }
}

// iOS delegate implementation can be added later when needed
