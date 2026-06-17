import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDecision {
  const UpdateDecision({
    required this.requiresUpdate,
    required this.storeUrl,
    this.latestVersion,
  });

  final bool requiresUpdate;
  final String storeUrl;
  final String? latestVersion;
}

class UpdateService {
  static const String _androidPackageId = 'com.liisgo.showmyname';
  static const String _iosAppId = '6758596742';
  static const String _iosLookupUrl =
      'https://itunes.apple.com/lookup?id=$_iosAppId';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_androidPackageId';
  static const String _appStoreUrl =
      'https://apps.apple.com/us/app/showmyname-display/id$_iosAppId';

  static Future<UpdateDecision> checkForRequiredUpdate() async {
    if (Platform.isAndroid) {
      return _checkAndroid();
    }
    if (Platform.isIOS) {
      return _checkIos();
    }
    return const UpdateDecision(requiresUpdate: false, storeUrl: '');
  }

  static Future<void> openStore() async {
    final url = Platform.isIOS ? _appStoreUrl : _playStoreUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<void> performAndroidImmediateUpdateIfAvailable() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      final immediateAllowed = info.immediateUpdateAllowed;
      final available = info.updateAvailability == UpdateAvailability.updateAvailable;

      if (available && immediateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (error) {
      debugPrint('[ForceUpdate] Android immediate update unavailable: $error');
    }
  }

  static Future<UpdateDecision> _checkAndroid() async {
    await performAndroidImmediateUpdateIfAvailable();
    return const UpdateDecision(
      requiresUpdate: false,
      storeUrl: _playStoreUrl,
    );
  }

  static Future<UpdateDecision> _checkIos() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      final response = await http.get(Uri.parse(_iosLookupUrl));
      if (response.statusCode != 200) {
        return const UpdateDecision(requiresUpdate: false, storeUrl: _appStoreUrl);
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = payload['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) {
        return const UpdateDecision(requiresUpdate: false, storeUrl: _appStoreUrl);
      }

      final storeVersion =
          (results.first as Map<String, dynamic>)['version']?.toString().trim();
      if (storeVersion == null || storeVersion.isEmpty) {
        return const UpdateDecision(requiresUpdate: false, storeUrl: _appStoreUrl);
      }

      final requiresUpdate = _compareVersions(currentVersion, storeVersion) < 0;
      return UpdateDecision(
        requiresUpdate: requiresUpdate,
        storeUrl: _appStoreUrl,
        latestVersion: storeVersion,
      );
    } catch (error) {
      debugPrint('[ForceUpdate] iOS update check failed: $error');
      return const UpdateDecision(requiresUpdate: false, storeUrl: _appStoreUrl);
    }
  }

  static int _compareVersions(String current, String target) {
    final currentParts = current.split('.').map(int.tryParse).toList();
    final targetParts = target.split('.').map(int.tryParse).toList();
    final maxLength =
        currentParts.length > targetParts.length ? currentParts.length : targetParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      final targetValue = i < targetParts.length ? (targetParts[i] ?? 0) : 0;
      if (currentValue < targetValue) return -1;
      if (currentValue > targetValue) return 1;
    }

    return 0;
  }
}
