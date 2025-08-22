import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../services/api_service.dart';

class BillingService {
  static const bool _kAutoConsume = true;
  static const String _kCredit70 = 'credits_70';
  static const String _kCredit150 = 'credits_150';
  static const String _kCredit400 = 'credits_400';
  static const String _kCredit900 = 'credits_900';
  static const String _kCredit2000 = 'credits_2000';
  static const String _kPremiumMonthly = 'premium_monthly';
  static const String _kPremiumYearly = 'premium_yearly';

  static const Set<String> _kIds = <String>{
    _kCredit70,
    _kCredit150,
    _kCredit400,
    _kCredit900,
    _kCredit2000,
    _kPremiumMonthly,
    _kPremiumYearly,
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
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _isAvailable = false;
      _loading = false;
      return;
    }

    // iOS delegate setup can be added later if needed
    // For now, we'll focus on Android implementation

    final ProductDetailsResponse productResponse = 
        await _inAppPurchase.queryProductDetails(_kIds);

    if (productResponse.notFoundIDs.isNotEmpty) {
      print('Product IDs not found: ${productResponse.notFoundIDs}');
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
      final String purchaseType = _kIds.contains(purchaseDetails.productID) && 
          (purchaseDetails.productID == _kPremiumMonthly || 
           purchaseDetails.productID == _kPremiumYearly) 
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

    if (product.id == _kPremiumMonthly || product.id == _kPremiumYearly) {
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
