// Path: lib/features/privacy/privacy_screen.dart
// Description: Privacy Policy screen with localized support email button.
// - Subject changes by language
// - Body includes app info + platform + language
// - Tries to open mail app; if it fails (common on simulators), shows a SnackBar fallback.
// Update:
// - Adds AdBanner at the bottom (FREE only). Uses SubscriptionManager.isPro() with FutureBuilder.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/subscription/subscription_manager.dart';


class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String _supportEmail = 'sales@liisgo.com';

  Future<void> _contactSupport(BuildContext context) async {
    final t = AppLocalizations.of(context);

    // Build device/app info
    String appName = 'ShowMyName';
    String version = '';
    String build = '';
    try {
      final info = await PackageInfo.fromPlatform();
      appName = info.appName.isEmpty ? appName : info.appName;
      version = info.version;
      build = info.buildNumber;
    } catch (_) {}

    final platform = Platform.isIOS
        ? 'iOS'
        : Platform.isAndroid
        ? 'Android'
        : 'Unknown';

    final language = Localizations.localeOf(context).languageCode;

    final subject = t.supportSubject;
    final body = '''
App: $appName
Version: ${version.isEmpty ? "?" : version}${build.isEmpty ? "" : "+$build"}
Platform: $platform
Language: $language

${t.supportBodyIntro}
''';

    final uri = Uri.parse(
      'mailto:$_supportEmail'
          '?subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok && context.mounted) {
        _showEmailFallback(context, t);
      }
    } catch (_) {
      if (context.mounted) _showEmailFallback(context, t);
    }
  }

  void _showEmailFallback(BuildContext context, AppLocalizations t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t.contactSupport}: $_supportEmail'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.privacyTitle),
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: SubscriptionManager.isPro(),
          builder: (context, snap) {
            final isPro = snap.data ?? false;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  t.privacyBody,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () => _contactSupport(context),
                  icon: const Icon(Icons.email_outlined),
                  label: Text(t.contactSupport),
                ),

                const SizedBox(height: 20),

                // ✅ Banner only for FREE
               // if (!isPro) const AdBanner(),

                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Text(
                  t.companyFooter,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
