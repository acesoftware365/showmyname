import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Future<String> _versionLine() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      if (version.isEmpty) return 'Last updated: June 17, 2026';
      return 'Last updated: June 17, 2026\nApp version: $version${build.isEmpty ? '' : '+$build'}';
    } catch (_) {
      return 'Last updated: June 17, 2026';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _versionLine(),
          builder: (context, snapshot) {
            final version = snapshot.data ?? 'Last updated: June 17, 2026';
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  version,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                const Text(
                  'By using ShowMyName, you agree to these Terms & Conditions. If you do not agree, please do not use the app.',
                  style: TextStyle(fontSize: 16, height: 1.45),
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'Use of the app',
                  body:
                      'ShowMyName lets you turn your device into a fullscreen sign for pickup, events, color displays, and logo display. You are responsible for the messages, images, and logos you choose to display.',
                ),
                _Section(
                  title: 'User content',
                  body:
                      'Do not use the app to display content that is illegal, harmful, abusive, hateful, misleading, or that violates another person or company\'s rights. You must have permission to use any logo or image you upload.',
                ),
                _Section(
                  title: 'Paid features and subscriptions',
                  body:
                      'Some features may require a one-time purchase or subscription. Purchases are processed by Apple or Google. Prices, renewal terms, cancellation options, trials, and refunds are handled according to the applicable app store rules shown at purchase time.',
                ),
                _Section(
                  title: 'Local storage',
                  body:
                      'Messages and uploaded logos are stored locally on your device unless a future feature clearly says otherwise. Removing the app may remove locally stored app data.',
                ),
                _Section(
                  title: 'No guarantees',
                  body:
                      'The app is provided as is. We try to keep it useful and reliable, but we do not guarantee that it will always be available, error-free, or suitable for every event or situation.',
                ),
                _Section(
                  title: 'Limitation of liability',
                  body:
                      'To the maximum extent allowed by law, ShowMyName and Liisgo are not responsible for indirect, incidental, special, or consequential damages related to use of the app.',
                ),
                _Section(
                  title: 'Changes to these terms',
                  body:
                      'We may update these Terms from time to time. Continued use of the app after changes means you accept the updated Terms.',
                ),
                _Section(
                  title: 'Contact',
                  body: 'Questions? Contact us at sales@liisgo.com.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 15.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}
