// Path: lib/ads/ad_banner_shell.dart
// Description:
// Wraps any screen and shows a banner at the bottom (FREE app).
// For now: ALWAYS shows the banner (no Pro logic).

import 'package:flutter/material.dart';
import 'ad_banner.dart';

class AdBannerShell extends StatelessWidget {
  final Widget child;

  const AdBannerShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: AdBanner()),
          ),
        ),
      ],
    );
  }
}