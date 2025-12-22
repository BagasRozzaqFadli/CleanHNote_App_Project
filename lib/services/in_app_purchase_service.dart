import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'database_service.dart';

/// In-App Purchase Service for Premium Upgrade
/// Ready for Google Play integration when Console is available
class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-App Purchase instance and state
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Product IDs - MUST match Google Play Console products
  static const String kProduct1Month = 'cleanhnote_premium_1m';
  static const String kProduct3Months = 'cleanhnote_premium_3m';
  static const String kProduct12Months = 'cleanhnote_premium_12m';

  // Callbacks for UI updates
  Function(bool)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function(bool)? onPurchasePending;

  /// Initialize IAP system
  Future<void> initialize() async {
    print('📦 Initializing IAP Service...');

    // Check if IAP is available on this device
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      print('❌ IAP not available on this device');
      return;
    }

    print('✅ IAP is available');

    // Setup purchase listener
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        print('🔚 Purchase stream closed');
        _subscription?.cancel();
      },
      onError: (error) {
        print('❌ Purchase stream error: $error');
        onPurchaseError?.call('Purchase error: $error');
      },
    );

    // Load products from Google Play
    await _loadProducts();
  }

  /// Load products from Google Play
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {
        kProduct1Month,
        kProduct3Months,
        kProduct12Months,
      };

      final ProductDetailsResponse response = await _iap.queryProductDetails(
        productIds,
      );

      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        print('❌ Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      print('✅ Loaded ${_products.length} products');

      for (var product in _products) {
        print('  - ${product.id}: ${product.price}');
      }
    } catch (e) {
      print('❌ Exception loading products: $e');
    }
  }

  /// Check if IAP is available
  bool get isAvailable => _isAvailable;

  /// Get product details by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Purchase a product
  Future<void> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('In-App Purchase tidak tersedia di perangkat ini');
      return;
    }

    if (_products.isEmpty) {
      onPurchaseError?.call('Produk belum dimuat. Silakan coba lagi.');
      await _loadProducts();
      return;
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      print('� Starting purchase for: ${product.title}');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Start purchase flow
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        onPurchaseError?.call('Gagal memulai proses pembayaran');
      } else {
        print('✅ Purchase flow started');
        onPurchasePending?.call(true);
      }
    } catch (e) {
      print('❌ Purchase error: $e');
      onPurchaseError?.call('Error: $e');
    }
  }

  /// Handle purchase updates from the stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('� Purchase update: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('⏳ Purchase pending...');
          onPurchasePending?.call(true);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          print('✅ Purchase successful!');
          _grantPremiumAccess(
            productId: purchaseDetails.productID,
            purchaseId: purchaseDetails.purchaseID ?? '',
          );
          break;

        case PurchaseStatus.error:
          print('❌ Purchase error: ${purchaseDetails.error}');
          onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Purchase failed',
          );
          break;

        case PurchaseStatus.canceled:
          print('🚫 Purchase canceled by user');
          onPurchaseError?.call('Pembayaran dibatalkan');
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Process successful purchase and grant premium
  Future<void> _grantPremiumAccess({
    required String productId,
    required String purchaseId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Determine duration based on product ID
      int durationMonths = 1;
      if (productId == kProduct3Months) {
        durationMonths = 3;
      } else if (productId == kProduct12Months) {
        durationMonths = 12;
      }

      // Calculate expiry date
      final now = DateTime.now();
      final expiryDate = DateTime(
        now.year,
        now.month + durationMonths,
        now.day,
        now.hour,
        now.minute,
      );

      // Update user in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'role': 'premium',
        'premiumExpiresAt': Timestamp.fromDate(expiryDate),
        'purchaseId': purchaseId,
        'productId': productId,
        'purchaseDate': FieldValue.serverTimestamp(),
      });

      print('✅ Premium granted until: $expiryDate');

      // Restore any hidden teams
      await DatabaseService().restoreTeamsOnUpgrade(user.uid);
      print('✅ Restored hidden teams');

      onPurchaseSuccess?.call(true);
    } catch (e) {
      print('❌ Error granting premium: $e');
      onPurchaseError?.call('Failed to activate premium: $e');
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('In-App Purchase tidak tersedia');
      return;
    }

    try {
      print('🔄 Restoring purchases...');
      await _iap.restorePurchases();
      print('✅ Restore request sent');
    } catch (e) {
      print('❌ Restore error: $e');
      onPurchaseError?.call('Gagal memulihkan pembelian: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    print('🔚 IAP Service disposed');
  }

  // ========================================
  // Helper Methods for Integration
  // ========================================

  /// Get duration in months from product ID
  static int getDurationFromProductId(String productId) {
    switch (productId) {
      case kProduct1Month:
        return 1;
      case kProduct3Months:
        return 3;
      case kProduct12Months:
        return 12;
      default:
        return 1;
    }
  }

  /// Get display name from product ID
  static String getProductDisplayName(String productId) {
    switch (productId) {
      case kProduct1Month:
        return '1 Month Premium';
      case kProduct3Months:
        return '3 Months Premium';
      case kProduct12Months:
        return '12 Months Premium';
      default:
        return 'Premium';
    }
  }

  /// Check current premium status
  Future<Map<String, dynamic>> checkPremiumStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'isPremium': false, 'error': 'Not logged in'};
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) {
        return {'isPremium': false, 'error': 'User data not found'};
      }

      final role = data['role'] ?? 'free';
      final premiumExpiresAt = data['premiumExpiresAt'] as Timestamp?;
      final isPremium =
          role == 'premium' &&
          (premiumExpiresAt == null ||
              premiumExpiresAt.toDate().isAfter(DateTime.now()));

      return {
        'isPremium': isPremium,
        'role': role,
        'expiresAt': premiumExpiresAt?.toDate(),
        'productId': data['productId'],
        'purchaseId': data['purchaseId'],
      };
    } catch (e) {
      print('❌ Error checking status: $e');
      return {'isPremium': false, 'error': e.toString()};
    }
  }
}

// ========================================
// INTEGRATION GUIDE (When Google Console Ready)
// ========================================
/*

STEP 1: Install Packages
------------------------
Add to pubspec.yaml:
  dependencies:
    in_app_purchase: ^3.2.0
    in_app_purchase_android: ^0.3.0+24

Run: flutter pub get


STEP 2: Update initialize() method
-----------------------------------
import 'package:in_app_purchase/in_app_purchase.dart';

Future<void> initialize() async {
  final iap = InAppPurchase.instance;
  final available = await iap.isAvailable();
  
  if (!available) return;
  
  // Setup purchase listener
  _subscription = iap.purchaseStream.listen(_onPurchaseUpdate);
  
  // Load products
  final response = await iap.queryProductDetails({
    kProduct1Month,
    kProduct3Months,
    kProduct12Months,
  });
  
  _products = response.productDetails;
}


STEP 3: Implement purchaseProduct()
-----------------------------------
Future<void> purchaseProduct(String productId) async {
  final product = _products.firstWhere((p) => p.id == productId);
  final param = PurchaseParam(productDetails: product);
  await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
}


STEP 4: Implement _onPurchaseUpdate()
-------------------------------------
void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
  for (final purchase in purchases) {
    if (purchase.status == PurchaseStatus.purchased) {
      _grantPremiumAccess(
        productId: purchase.productID,
        purchaseId: purchase.purchaseID ?? '',
      );
    }
    
    if (purchase.pendingCompletePurchase) {
      InAppPurchase.instance.completePurchase(purchase);
    }
  }
}

*/
