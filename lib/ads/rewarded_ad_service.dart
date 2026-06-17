import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();
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

  Future<bool> showOnce() async {
    if (unitId.isEmpty) return false;

    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var rewarded = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(rewarded);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );

          ad.show(
            onUserEarnedReward: (_, __) {
              rewarded = true;
            },
          );
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () => false,
    );
  }
}
