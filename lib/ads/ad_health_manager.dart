import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdHealthDecision {
  const AdHealthDecision({
    required this.allowed,
    required this.reason,
    this.wait,
  });

  final bool allowed;
  final String reason;
  final Duration? wait;
}

class AdHealthManager {
  AdHealthManager._();

  static final AdHealthManager instance = AdHealthManager._();

  static const rewardedHandwriting = 'rewarded_handwriting';
  static const homeBanner = 'home_banner';

  static const _minRequestSpacing = Duration(seconds: 35);
  static const _debugMinRequestSpacing = Duration(seconds: 4);
  static const _baseRetryDelay = Duration(minutes: 2);
  static const _debugBaseRetryDelay = Duration(seconds: 8);
  static const _maxRetryDelay = Duration(minutes: 30);
  static const _debugMaxRetryDelay = Duration(minutes: 2);

  final Map<String, bool> _inFlight = <String, bool>{};
  final Map<String, DateTime> _lastRequestAt = <String, DateTime>{};
  final Map<String, DateTime> _retryAfter = <String, DateTime>{};
  final Map<String, int> _failureStreak = <String, int>{};
  final Random _random = Random();

  Duration get _spacing =>
      kDebugMode ? _debugMinRequestSpacing : _minRequestSpacing;
  Duration get _baseRetry =>
      kDebugMode ? _debugBaseRetryDelay : _baseRetryDelay;
  Duration get _maxRetry => kDebugMode ? _debugMaxRetryDelay : _maxRetryDelay;

  AdHealthDecision canRequest(String slot, {bool force = false}) {
    if (_inFlight[slot] == true) {
      return const AdHealthDecision(
        allowed: false,
        reason: 'request already in flight',
      );
    }

    if (force) {
      return const AdHealthDecision(allowed: true, reason: 'forced request');
    }

    final now = DateTime.now();
    final retry = _retryAfter[slot];
    if (retry != null && now.isBefore(retry)) {
      return AdHealthDecision(
        allowed: false,
        reason: 'retry cooldown active',
        wait: retry.difference(now),
      );
    }

    final last = _lastRequestAt[slot];
    if (last != null && now.difference(last) < _spacing) {
      return AdHealthDecision(
        allowed: false,
        reason: 'request spacing active',
        wait: _spacing - now.difference(last),
      );
    }

    return const AdHealthDecision(allowed: true, reason: 'ready');
  }

  void markRequestStarted(String slot) {
    _inFlight[slot] = true;
    _lastRequestAt[slot] = DateTime.now();
    _increment('$slot.requests');
  }

  void markLoaded(String slot) {
    _inFlight[slot] = false;
    _failureStreak[slot] = 0;
    _retryAfter.remove(slot);
    _increment('$slot.loaded');
  }

  void markFailed(String slot, LoadAdError error) {
    _inFlight[slot] = false;
    final streak = (_failureStreak[slot] ?? 0) + 1;
    _failureStreak[slot] = streak;
    _retryAfter[slot] = DateTime.now().add(_retryDelayFor(streak));
    _increment('$slot.failed');
    debugPrint(
      '[AdHealth] $slot failed code=${error.code} domain=${error.domain} '
      'streak=$streak retryAfter=${_retryAfter[slot]}',
    );
  }

  void markTimedOut(String slot) {
    _inFlight[slot] = false;
    final streak = (_failureStreak[slot] ?? 0) + 1;
    _failureStreak[slot] = streak;
    _retryAfter[slot] = DateTime.now().add(_retryDelayFor(streak));
    _increment('$slot.timed_out');
    debugPrint(
      '[AdHealth] $slot timed out streak=$streak retryAfter=${_retryAfter[slot]}',
    );
  }

  void markShowed(String slot) {
    _increment('$slot.showed');
  }

  void markRewarded(String slot) {
    _increment('$slot.rewarded');
  }

  void markDismissed(String slot) {
    _increment('$slot.dismissed');
  }

  Duration retryWait(String slot) {
    final retry = _retryAfter[slot];
    if (retry == null) return Duration.zero;
    final wait = retry.difference(DateTime.now());
    return wait.isNegative ? Duration.zero : wait;
  }

  Duration _retryDelayFor(int failureStreak) {
    final multiplier = pow(2, min(failureStreak - 1, 5)).toInt();
    final raw = _baseRetry * multiplier;
    final capped = raw > _maxRetry ? _maxRetry : raw;
    final jitterMs =
        (capped.inMilliseconds * 0.15 * _random.nextDouble()).round();
    return capped + Duration(milliseconds: jitterMs);
  }

  Future<void> _increment(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final dailyKey = 'ad_health.$day.$key';
    await prefs.setInt(dailyKey, (prefs.getInt(dailyKey) ?? 0) + 1);
  }
}
