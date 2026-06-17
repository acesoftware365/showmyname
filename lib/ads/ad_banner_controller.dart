import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerController extends ChangeNotifier {
  AdBannerController._();

  static final AdBannerController instance = AdBannerController._();

  static const Duration _minRequestInterval = Duration(seconds: 30);
  static const Duration _failureCooldown = Duration(seconds: 45);

  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  int? _lastWidth;
  Orientation? _lastOrientation;
  DateTime? _lastRequestAt;
  DateTime? _retryAfter;

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

    final now = DateTime.now();
    if (_retryAfter != null && now.isBefore(_retryAfter!)) {
      _log(
        'request skipped: cooldown active for ${_retryAfter!.difference(now).inSeconds}s',
      );
      return;
    }
    if (_lastRequestAt != null &&
        now.difference(_lastRequestAt!) < _minRequestInterval) {
      _log(
        'request skipped: min interval active for ${_minRequestInterval.inSeconds - now.difference(_lastRequestAt!).inSeconds}s',
      );
      return;
    }

    _loading = true;
    _loaded = false;
    _ad?.dispose();
    _ad = null;
    _lastRequestAt = now;
    notifyListeners();

    final adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
    if (adSize == null) {
      _loading = false;
      _log('request aborted: no adaptive size for width=$width orientation=$orientation');
      notifyListeners();
      return;
    }

    _log('loading banner width=$width orientation=$orientation size=${adSize.width}x${adSize.height}');

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
          _retryAfter = null;
          _log('banner loaded width=$width orientation=$orientation');
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _ad = null;
          _loaded = false;
          _loading = false;
          _retryAfter = DateTime.now().add(_failureCooldown);
          _log(
            'banner failed code=${err.code} message="${err.message}" cooldown=${_failureCooldown.inSeconds}s',
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
