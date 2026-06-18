// Path: lib/services/analytics/analytics_service.dart
// Description: Safe Firebase Analytics wrapper for ShowMyName.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class AnalyticsService {
  static bool _enabled = false;

  static FirebaseAnalytics? get _analytics {
    if (!_enabled) return null;
    return FirebaseAnalytics.instance;
  }

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      _enabled = true;
    } catch (_) {
      _enabled = false;
    }
  }

  static Future<void> logAppOpen() => _safeLog(
        () => _analytics?.logAppOpen(),
      );

  static Future<void> logModeSelected(String mode, {required bool isPro}) {
    return _safeLog(
      () => _analytics?.logEvent(
        name: 'mode_selected',
        parameters: {'mode': mode, 'is_pro': isPro},
      ),
    );
  }

  static Future<void> logShowSign(String mode, String signType) {
    return _safeLog(
      () => _analytics?.logEvent(
        name: 'show_sign',
        parameters: {'mode': mode, 'sign_type': signType},
      ),
    );
  }

  static Future<void> logPaywallOpen({required String source}) {
    return _safeLog(
      () => _analytics?.logEvent(
        name: 'paywall_open',
        parameters: {'source': source},
      ),
    );
  }

  static Future<void> logPurchaseTap(String planId) {
    return _safeLog(
      () => _analytics?.logEvent(
        name: 'purchase_tap',
        parameters: {'plan_id': planId},
      ),
    );
  }

  static Future<void> logRestoreTap() {
    return _safeLog(
      () => _analytics?.logEvent(name: 'restore_purchase_tap'),
    );
  }

  static Future<void> logRewardChoice(String feature, String choice) {
    return _safeLog(
      () => _analytics?.logEvent(
        name: 'reward_unlock_choice',
        parameters: {'feature': feature, 'choice': choice},
      ),
    );
  }

  static Future<void> logRewardResult(String feature, {required bool unlocked}) {
    return _safeLog(
      () => _analytics?.logEvent(
        name: 'reward_unlock_result',
        parameters: {'feature': feature, 'unlocked': unlocked},
      ),
    );
  }

  static Future<void> _safeLog(Future<void>? Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
