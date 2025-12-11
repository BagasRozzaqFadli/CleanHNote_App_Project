import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Product IDs - MUST match Google Play Console products
  static const String kProduct1Month = 'cleanhnote_premium_1m';
  static const String kProduct3Months = 'cleanhnote_premium_3m';
  static const String kProduct12Months = 'cleanhnote_premium_12m';

  // Callbacks for UI updates
  Function(bool)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function(bool)? onPurchasePending;

  /// Initialize IAP system
  /// TODO: Add in_app_purchase package initialization when ready
  Future<void> initialize() async {
    print('📦 IAP Service initialized (waiting for Google Console setup)');

    // TODO: When Google Console is ready:
    // 1. Install packages:
    //    - in_app_purchase: ^3.2.0
    //    - in_app_purchase_android: ^0.3.0+24
    // 2. Initialize InAppPurchase instance
    // 3. Setup purchase stream listener
    // 4. Load products from Google Play
  }

  /// Check if IAP is available
  bool get isAvailable {
    // TODO: Return actual availability when package is installed
    return false; // Not yet available
  }

  /// Get product details by ID
  /// TODO: Return ProductDetails from Google Play
  dynamic getProduct(String productId) {
    print('🔍 Product requested: $productId');
    // TODO: When ready, return actual ProductDetails
    return null;
  }

  /// Purchase a product
  /// TODO: Trigger actual Google Play purchase flow
  Future<void> purchaseProduct(String productId) async {
    print('🛒 Purchase requested for: $productId');

    // For now, show message that Google Console is needed
    onPurchaseError?.call(
      'Payment system not yet configured. '
      'Google Play Console setup required.',
    );

    // TODO: When Google Console ready:
    // 1. Get ProductDetails from productId
    // 2. Create PurchaseParam
    // 3. Call InAppPurchase.buyNonConsumable()
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
  /// TODO: Implement when Google Play is configured
  Future<void> restorePurchases() async {
    print('🔄 Restore purchases requested');

    onPurchaseError?.call(
      'Restore not yet available. '
      'Google Play Console setup required.',
    );

    // TODO: When ready:
    // await InAppPurchase.instance.restorePurchases();
  }

  /// Dispose resources
  void dispose() {
    // TODO: Cancel purchase stream subscription when implemented
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
