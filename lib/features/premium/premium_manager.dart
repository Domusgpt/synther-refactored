import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import '../../core/firebase_manager.dart';

/// Comprehensive premium subscription and IAP management
class PremiumManager {
  static final PremiumManager _instance = PremiumManager._internal();
  factory PremiumManager() => _instance;
  PremiumManager._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  
  // Subscription tracking
  bool _isIAPAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Product IDs - these should match your app store configurations
  static const String plusYearlyId = 'synther_plus_yearly';
  static const String proYearlyId = 'synther_pro_yearly';
  static const String studioYearlyId = 'synther_studio_yearly';
  static const String plusMonthlyId = 'synther_plus_monthly';
  static const String proMonthlyId = 'synther_pro_monthly';
  
  // Consumable products
  static const String presetPackId = 'preset_pack_electronic';
  static const String premiumPresetPackId = 'preset_pack_premium';
  
  /// All product IDs for store configuration
  static const Set<String> productIds = {
    plusYearlyId,
    proYearlyId,
    studioYearlyId,
    plusMonthlyId,
    proMonthlyId,
    presetPackId,
    premiumPresetPackId,
  };

  /// Initialize IAP system
  Future<void> initialize() async {
    try {
      _isIAPAvailable = await _iap.isAvailable();
      
      if (!_isIAPAvailable) {
        print('IAP not available on this device');
        return;
      }

      // Listen for purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('Purchase stream error: $error'),
      );

      // Load products from store
      await _loadProducts();
      
      // Restore previous purchases
      await restorePurchases();
      
      print('Premium Manager initialized successfully');
      
      await FirebaseManager().logEvent('iap_initialized', parameters: {
        'iap_available': _isIAPAvailable,
        'products_loaded': _products.length,
      });
    } catch (e) {
      print('Premium Manager initialization error: $e');
      _isIAPAvailable = false;
    }
  }

  /// Load products from app stores
  Future<void> _loadProducts() async {
    if (!_isIAPAvailable) return;

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      
      if (response.error != null) {
        print('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      
      print('Loaded ${_products.length} products:');
      for (final product in _products) {
        print('- ${product.id}: ${product.title} (${product.price})');
      }
      
      await FirebaseManager().logEvent('products_loaded', parameters: {
        'product_count': _products.length,
        'missing_products': response.notFoundIDs.length,
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  /// Process individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    print('Processing purchase: ${purchase.productID} - ${purchase.status}');
    
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _completePurchase(purchase);
        break;
        
      case PurchaseStatus.error:
        await _handlePurchaseError(purchase);
        break;
        
      case PurchaseStatus.pending:
        await _handlePendingPurchase(purchase);
        break;
        
      case PurchaseStatus.canceled:
        await _handleCanceledPurchase(purchase);
        break;
    }

    // Acknowledge purchase if needed
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Complete successful purchase
  Future<void> _completePurchase(PurchaseDetails purchase) async {
    try {
      // Verify purchase server-side (important for security)
      final isValid = await _verifyPurchase(purchase);
      
      if (!isValid) {
        print('Purchase verification failed: ${purchase.productID}');
        return;
      }

      // Grant premium access based on product
      await _grantPremiumAccess(purchase);
      
      // Update UI and user preferences
      await _updatePremiumStatus(purchase);
      
      await FirebaseManager().logEvent('purchase_completed', parameters: {
        'product_id': purchase.productID,
        'transaction_date': purchase.transactionDate,
        'is_restored': purchase.status == PurchaseStatus.restored,
      });
      
      print('Purchase completed successfully: ${purchase.productID}');
    } catch (e) {
      print('Error completing purchase: $e');
    }
  }

  /// Verify purchase with backend
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      // In production, send receipt to your backend for verification
      // For now, we'll do basic client-side validation
      
      if (purchase.verificationData.source == 'app_store') {
        // iOS receipt verification
        return purchase.verificationData.serverVerificationData.isNotEmpty;
      } else if (purchase.verificationData.source == 'google_play') {
        // Google Play verification
        return purchase.verificationData.serverVerificationData.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      print('Purchase verification error: $e');
      return false;
    }
  }

  /// Grant premium access based on purchased product
  Future<void> _grantPremiumAccess(PurchaseDetails purchase) async {
    PremiumTier tier;
    DateTime? expiration;
    
    switch (purchase.productID) {
      case plusYearlyId:
        tier = PremiumTier.plus;
        expiration = DateTime.now().add(const Duration(days: 365));
        break;
        
      case plusMonthlyId:
        tier = PremiumTier.plus;
        expiration = DateTime.now().add(const Duration(days: 30));
        break;
        
      case proYearlyId:
        tier = PremiumTier.pro;
        expiration = DateTime.now().add(const Duration(days: 365));
        break;
        
      case proMonthlyId:
        tier = PremiumTier.pro;
        expiration = DateTime.now().add(const Duration(days: 30));
        break;
        
      case studioYearlyId:
        tier = PremiumTier.studio;
        expiration = DateTime.now().add(const Duration(days: 365));
        break;
        
      case presetPackId:
      case premiumPresetPackId:
        // Handle consumable products
        await _grantConsumableProduct(purchase);
        return;
        
      default:
        print('Unknown product ID: ${purchase.productID}');
        return;
    }
    
    // Update Firebase with premium status
    await FirebaseManager().updatePremiumStatus(tier, expiration: expiration);
  }

  /// Grant consumable product (preset packs)
  Future<void> _grantConsumableProduct(PurchaseDetails purchase) async {
    // Grant access to specific preset pack
    // This would typically unlock content in your app
    
    await FirebaseManager().logEvent('consumable_purchased', parameters: {
      'product_id': purchase.productID,
    });
    
    print('Consumable product granted: ${purchase.productID}');
  }

  /// Update premium status in app
  Future<void> _updatePremiumStatus(PurchaseDetails purchase) async {
    // Disable ads if premium purchased
    if (_isPremiumProduct(purchase.productID)) {
      // This would typically update app state and disable ads
      print('Premium access granted - ads disabled');
    }
  }

  /// Check if product grants premium access
  bool _isPremiumProduct(String productId) {
    return [
      plusYearlyId,
      plusMonthlyId,
      proYearlyId,
      proMonthlyId,
      studioYearlyId,
    ].contains(productId);
  }

  /// Handle purchase error
  Future<void> _handlePurchaseError(PurchaseDetails purchase) async {
    final error = purchase.error;
    print('Purchase error: ${error?.code} - ${error?.message}');
    
    await FirebaseManager().logEvent('purchase_error', parameters: {
      'product_id': purchase.productID,
      'error_code': error?.code ?? 'unknown',
      'error_message': error?.message ?? 'Unknown error',
    });
  }

  /// Handle pending purchase (waiting for user action)
  Future<void> _handlePendingPurchase(PurchaseDetails purchase) async {
    print('Purchase pending: ${purchase.productID}');
    
    await FirebaseManager().logEvent('purchase_pending', parameters: {
      'product_id': purchase.productID,
    });
  }

  /// Handle canceled purchase
  Future<void> _handleCanceledPurchase(PurchaseDetails purchase) async {
    print('Purchase canceled: ${purchase.productID}');
    
    await FirebaseManager().logEvent('purchase_canceled', parameters: {
      'product_id': purchase.productID,
    });
  }

  /// Purchase specific product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isIAPAvailable) {
      print('IAP not available');
      return false;
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      await FirebaseManager().logEvent('purchase_initiated', parameters: {
        'product_id': productId,
        'price': product.price,
      });
      
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        await FirebaseManager().logEvent('purchase_failed', parameters: {
          'product_id': productId,
          'reason': 'buy_non_consumable_failed',
        });
      }
      
      return success;
    } catch (e) {
      print('Purchase error: $e');
      
      await FirebaseManager().logEvent('purchase_failed', parameters: {
        'product_id': productId,
        'error': e.toString(),
      });
      
      return false;
    }
  }

  /// Purchase consumable product (preset packs)
  Future<bool> purchaseConsumable(String productId) async {
    if (!_isIAPAvailable) return false;

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      await FirebaseManager().logEvent('consumable_purchase_initiated', parameters: {
        'product_id': productId,
        'price': product.price,
      });
      
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Consumable purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isIAPAvailable) return;

    try {
      await FirebaseManager().logEvent('restore_purchases_initiated');
      
      await _iap.restorePurchases();
      
      print('Purchases restored successfully');
    } catch (e) {
      print('Restore purchases error: $e');
      
      await FirebaseManager().logEvent('restore_purchases_failed', parameters: {
        'error': e.toString(),
      });
    }
  }

  /// Get product details for display
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get all subscription products for UI
  List<ProductDetails> getSubscriptionProducts() {
    return _products.where((p) => [
      plusYearlyId,
      plusMonthlyId,
      proYearlyId,
      proMonthlyId,
      studioYearlyId,
    ].contains(p.id)).toList();
  }

  /// Get consumable products
  List<ProductDetails> getConsumableProducts() {
    return _products.where((p) => [
      presetPackId,
      premiumPresetPackId,
    ].contains(p.id)).toList();
  }

  /// Check if specific premium tier is active
  bool hasPremiumTier(PremiumTier tier) {
    final firebaseManager = FirebaseManager();
    return firebaseManager.premiumTier.index >= tier.index;
  }

  /// Get premium status for UI
  Map<String, dynamic> getPremiumStatus() {
    final firebaseManager = FirebaseManager();
    return {
      'isPremium': firebaseManager.isPremium,
      'tier': firebaseManager.premiumTier.displayName,
      'expiration': firebaseManager.premiumExpiration,
      'daysRemaining': firebaseManager.premiumExpiration?.difference(DateTime.now()).inDays,
    };
  }

  /// Show upgrade dialog for specific feature
  Future<void> showUpgradeDialog(String feature, PremiumTier requiredTier) async {
    await FirebaseManager().logUpgradeClick(feature, requiredTier);
    
    // This would show a custom dialog with upgrade options
    // Implementation depends on your UI framework
    print('Showing upgrade dialog for feature: $feature (requires: ${requiredTier.displayName})');
  }

  /// Get pricing information for display
  Map<String, String> getPricing() {
    final pricing = <String, String>{};
    
    for (final product in _products) {
      pricing[product.id] = product.price;
    }
    
    return pricing;
  }

  /// Get promotional pricing (if available)
  Map<String, dynamic> getPromotionalPricing() {
    final promos = <String, dynamic>{};
    
    for (final product in _products) {
      // Check for promotional pricing on iOS
      if (Platform.isIOS && product.skProduct != null) {
        // Add promotional pricing logic here
      }
      
      // Check for promotional pricing on Android
      if (Platform.isAndroid && product.skuDetail != null) {
        // Add promotional pricing logic here
      }
    }
    
    return promos;
  }

  /// Check purchase eligibility (for A/B testing)
  bool isPurchaseEligible(String productId) {
    // Add business logic for purchase eligibility
    // E.g., first-time users, returning users, etc.
    return true;
  }

  /// Get recommended tier based on usage
  PremiumTier getRecommendedTier() {
    // Analyze user behavior to recommend appropriate tier
    // For now, default to Pro
    return PremiumTier.pro;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
  }

  /// Check if IAP is available
  bool get isAvailable => _isIAPAvailable;
  
  /// Get loaded products
  List<ProductDetails> get products => List.unmodifiable(_products);
}

/// Premium tier benefits configuration
class PremiumBenefits {
  static Map<PremiumTier, List<String>> get benefits => {
    PremiumTier.free: [
      '50 built-in presets',
      'Basic synthesis engine',
      'Save up to 10 custom presets',
      'Standard audio quality',
    ],
    PremiumTier.plus: [
      '200+ premium presets',
      'Advanced synthesis modes',
      'Unlimited custom presets',
      'Cloud backup & sync',
      'No advertisements',
      'High-quality audio export',
    ],
    PremiumTier.pro: [
      'All Plus features',
      '500+ professional presets',
      'MIDI file export',
      'Multi-track recording',
      'Advanced audio effects',
      'Collaboration features',
      'Priority customer support',
    ],
    PremiumTier.studio: [
      'All Pro features',
      'Commercial usage license',
      'Exclusive studio presets',
      'Priority feature requests',
      'Direct developer contact',
      'Early access to beta features',
    ],
  };

  static List<String> getBenefits(PremiumTier tier) {
    return benefits[tier] ?? [];
  }

  static String getUpgradeMessage(String feature, PremiumTier requiredTier) {
    switch (feature) {
      case 'unlimited_presets':
        return 'Upgrade to ${requiredTier.displayName} to save unlimited presets and access your sounds across all devices.';
      case 'midi_export':
        return 'Export your compositions as MIDI files with ${requiredTier.displayName}. Perfect for use in professional DAWs.';
      case 'cloud_sync':
        return 'Keep your presets synced across all devices with ${requiredTier.displayName} cloud backup.';
      case 'advanced_synthesis':
        return 'Unlock advanced synthesis modes and professional-grade sound design with ${requiredTier.displayName}.';
      default:
        return 'Upgrade to ${requiredTier.displayName} to unlock this feature and many more professional tools.';
    }
  }
}