// Path: lib/services/subscription/subscription_manager.dart
// Description:
// - Handles Pro status with real In-App Purchases (iOS/Android).
// - Keeps your Preview Override (free/pro) for testing UI.
// - Persists "real Pro" state locally (until you later add server verification).
//
// IMPORTANT:
// - Set your product IDs in _kProductIds (must match App Store Connect + Play Console).

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlanPreviewOverride { none, free, pro }

class SubscriptionManager {
  static const String monthlyProductId = 'showmyname_pro_monthly';
  static const String yearlyProductId = 'showmyname_pro_yearly';
  static const String monthlyFallbackPrice = r'$0.99 / month';
  static const String yearlyFallbackPrice = r'$9.99 / year';

  // Real pro flag (store-driven; persisted locally)
  static const String _kIsProReal = 'is_pro_real_v1';
  static const String _kIsProLegacy = 'is_pro';
  static const String _kPreviewOverride = 'plan_preview_override_v1';

  // ✅ TODO: Put your real product IDs here
  // Example:
  // - "showmyname_pro_monthly"
  // - "showmyname_pro_yearly"
  static const Set<String> _kProductIds = {
    monthlyProductId,
    yearlyProductId,
  };

  // Public reactive flag (so Ads/UI can react)
  static final StreamController<bool> _proStream =
      StreamController<bool>.broadcast();
  static Stream<bool> get proStream => _proStream.stream;

  static bool _initialized = false;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  static List<ProductDetails> _products = [];
  static List<ProductDetails> get products => List.unmodifiable(_products);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Push current known state first
    _proStream.add(await isPro());

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    // Load products
    final response =
        await InAppPurchase.instance.queryProductDetails(_kProductIds);
    _products = response.productDetails;

    // Listen for purchase updates
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) async {
        await _handlePurchaseUpdates(purchases);
      },
      onError: (_) {},
    );
  }

  static Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
  }

  /// Returns current plan status.
  /// If the testing override is set, it wins.
  static Future<bool> isPro() async {
    final prefs = await SharedPreferences.getInstance();

    final override = prefs.getString(_kPreviewOverride);
    if (override == 'pro') return true;
    if (override == 'free') return false;

    final real = prefs.getBool(_kIsProReal);
    if (real != null) return real;

    return prefs.getBool(_kIsProLegacy) ?? false;
  }

  /// Sets the "real" Pro state (used internally).
  static Future<void> _setProReal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsProReal, value);
    await prefs.setBool(_kIsProLegacy, value);
    _proStream.add(value);
  }

  /// MVP compatibility (kept): manual set.
  /// You can still call this in debug if you want.
  static Future<void> setPro(bool value) async {
    await _setProReal(value);
  }

  /// Clears the override so the app follows the real plan again.
  static Future<void> clearPreviewOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPreviewOverride);
    _proStream.add(await isPro());
  }

  static Future<PlanPreviewOverride> getPreviewOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kPreviewOverride);
    if (v == 'free') return PlanPreviewOverride.free;
    if (v == 'pro') return PlanPreviewOverride.pro;
    return PlanPreviewOverride.none;
  }

  static Future<void> setPreviewOverride(PlanPreviewOverride value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value) {
      case PlanPreviewOverride.none:
        await prefs.remove(_kPreviewOverride);
        break;
      case PlanPreviewOverride.free:
        await prefs.setString(_kPreviewOverride, 'free');
        break;
      case PlanPreviewOverride.pro:
        await prefs.setString(_kPreviewOverride, 'pro');
        break;
    }
    _proStream.add(await isPro());
  }

  static ProductDetails? productById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> buy(ProductDetails product) async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    final param = PurchaseParam(productDetails: product);

    // Subscriptions use buyNonConsumable as well in this plugin (store handles recurring).
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  static Future<void> restorePurchases() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    await InAppPurchase.instance.restorePurchases();
    // Final state will be set when purchaseStream sends updates
  }

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    bool foundActivePro = false;

    for (final p in purchases) {
      // If purchased/restored and matches our IDs -> Pro
      final isOurProduct = _kProductIds.contains(p.productID);

      if ((p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) &&
          isOurProduct) {
        foundActivePro = true;

        // Complete purchase if needed
        if (p.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(p);
        }
      }

      // Pending purchases: do nothing (UI can show loading)
      // Error/canceled: do nothing
    }

    // If we see any active purchase for our products -> set Pro true.
    // NOTE: This is local trust. Later you can add server receipt validation.
    if (foundActivePro) {
      await _setProReal(true);
    } else {
      // Do NOT auto-turn off Pro here — store may not send all history every time.
      // We'll keep current saved state.
      _proStream.add(await isPro());
    }
  }
}
