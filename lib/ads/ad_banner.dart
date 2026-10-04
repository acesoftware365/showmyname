import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/app_localizations.dart';
import 'ad_banner_controller.dart';

/// Keep an ad's space separate and stable while loading or resizing the window.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdBannerController.instance;
    final reservedHeight = Platform.isIOS ? 50.0 : 90.0;
    return SizedBox(
      height: reservedHeight,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth.floor();
        final requestWidth = Platform.isIOS ? 320 : width;
        final orientation = Platform.isIOS
            ? Orientation.portrait
            : MediaQuery.orientationOf(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || width < 320) return;
          controller.ensureLoaded(
              width: requestWidth, orientation: orientation);
        });
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final ad = controller.ad;
            if (!controller.isLoaded ||
                ad == null ||
                ad.size.width > width ||
                ad.size.height > reservedHeight) {
              return Center(
                child: Text(AppLocalizations.of(context).advertisement,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              );
            }
            return Center(
              child: SizedBox(
                height: ad.size.height.toDouble(),
                width: ad.size.width.toDouble(),
                child: AdWidget(ad: ad),
              ),
            );
          },
        );
      }),
    );
  }
}
