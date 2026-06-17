import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_health_manager.dart';

class AdBannerController extends ChangeNotifier {
  AdBannerController._();

  static final AdBannerController instance = AdBannerController._();
  static const String _slot = AdHealthManager.homeBanner;

  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  int? _lastWidth;
  Orientation? _lastOrientation;

  BannerAd? get ad => _ad;
  bool get isLoaded => _loaded && _ad != null;

  static String get unitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      }
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    if (Platform.isAndroid) {
      return 'ca-app-pub-8588489900323524/3483067829';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-8588489900323524/3690516616';
    }
    return '';
  }

  void _log(String message) {
    debugPrint('[AdBanner] $message');
  }

  Future<void> ensureLoaded({
    required int width,
    required Orientation orientation,
  }) async {
    if (unitId.isEmpty) return;
    if (_loading) return;
    if (width <= 0) return;
    if (_lastWidth == width && _lastOrientation == orientation && _ad != null) {
      return;
    }

    final health = AdHealthManager.instance;
    final decision = health.canRequest(_slot);
    if (!decision.allowed) {
      _log(
        'request skipped: ${decision.reason}'
        '${decision.wait == null ? '' : ' wait=${decision.wait!.inSeconds}s'}',
      );
      return;
    }

    _loading = true;
    _loaded = false;
    _ad?.dispose();
    _ad = null;
    notifyListeners();

    final adSize =
        await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
    if (adSize == null) {
      _loading = false;
      _log(
          'request aborted: no adaptive size for width=$width orientation=$orientation');
      notifyListeners();
      return;
    }

    health.markRequestStarted(_slot);
    _log(
        'loading banner width=$width orientation=$orientation size=${adSize.width}x${adSize.height}');

    final ad = BannerAd(
      adUnitId: unitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _ad = ad as BannerAd;
          _loaded = true;
          _loading = false;
          _lastWidth = width;
          _lastOrientation = orientation;
          health.markLoaded(_slot);
          _log('banner loaded width=$width orientation=$orientation');
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _ad = null;
          _loaded = false;
          _loading = false;
          health.markFailed(_slot, err);
          _log(
            'banner failed code=${err.code} message="${err.message}"',
          );
          notifyListeners();
        },
      ),
    );

    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }
}
