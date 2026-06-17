// Path: lib/features/ads/ad_banner.dart
// Description: AdMob banner widget using TEST ad unit ids (Android/iOS).
// Shows a fixed-height banner and safely disposes the ad.

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_banner_controller.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdBannerController.instance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.floor();
        final orientation = MediaQuery.of(context).orientation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.ensureLoaded(width: width, orientation: orientation);
        });

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final ad = controller.ad;
            if (!controller.isLoaded || ad == null) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: ad.size.height.toDouble(),
              width: ad.size.width.toDouble(),
              child: AdWidget(ad: ad),
            );
          },
        );
      },
    );
  }
}
