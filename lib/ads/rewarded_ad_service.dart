import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_health_manager.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();
  static const _slot = AdHealthManager.rewardedHandwriting;
  static const _maxCacheAge = Duration(minutes: 50);
  static const String _androidReleaseUnitId = String.fromEnvironment(
    'SHOWMYNAME_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-8588489900323524/8044514697',
  );
  static const String _iosReleaseUnitId = String.fromEnvironment(
    'SHOWMYNAME_REWARDED_IOS',
    defaultValue: 'ca-app-pub-8588489900323524/9277705315',
  );

  static String get unitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    }

    if (Platform.isAndroid) {
      return _androidReleaseUnitId;
    }
    if (Platform.isIOS) {
      return _iosReleaseUnitId;
    }
    return '';
  }

  RewardedAd? _cachedAd;
  DateTime? _loadedAt;
  Completer<void>? _loadCompleter;
  bool _showing = false;

  bool get isReady {
    final loadedAt = _loadedAt;
    if (_cachedAd == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _maxCacheAge;
  }

  Future<void> preload({bool force = false}) async {
    if (unitId.isEmpty) return;
    if (isReady) return;

    if (_cachedAd != null) {
      _cachedAd?.dispose();
      _cachedAd = null;
      _loadedAt = null;
    }

    final pending = _loadCompleter;
    if (pending != null) return pending.future;

    final health = AdHealthManager.instance;
    final decision = health.canRequest(_slot, force: force);
    if (!decision.allowed) {
      debugPrint(
        '[RewardedAd] preload skipped: ${decision.reason}'
        '${decision.wait == null ? '' : ' wait=${decision.wait!.inSeconds}s'}',
      );
      return;
    }

    final completer = Completer<void>();
    _loadCompleter = completer;
    health.markRequestStarted(_slot);

    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _cachedAd?.dispose();
            _cachedAd = ad;
            _loadedAt = DateTime.now();
            _loadCompleter = null;
            health.markLoaded(_slot);
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            _cachedAd = null;
            _loadedAt = null;
            _loadCompleter = null;
            health.markFailed(_slot, error);
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (error) {
      _cachedAd = null;
      _loadedAt = null;
      _loadCompleter = null;
      health.markTimedOut(_slot);
      debugPrint('[RewardedAd] preload error: $error');
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _loadCompleter = null;
        health.markTimedOut(_slot);
      },
    );
  }

  Future<bool> showOnce() async {
    if (unitId.isEmpty) return false;
    if (_showing) return false;

    if (!isReady) {
      await preload(force: true);
    }

    final ad = _cachedAd;
    if (ad == null) {
      unawaited(preload());
      return false;
    }

    _cachedAd = null;
    _loadedAt = null;
    _showing = true;

    final completer = Completer<bool>();
    var rewarded = false;
    final health = AdHealthManager.instance;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        health.markShowed(_slot);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        health.markDismissed(_slot);
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) {
        rewarded = true;
        health.markRewarded(_slot);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _showing = false;
        unawaited(preload());
        return false;
      },
    );
  }
}
