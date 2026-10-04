// Path: lib/ads/ad_banner_shell.dart
// Description:
// Wraps normal screens and shows ads only for Free users.

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/subscription/subscription_manager.dart';
import 'ad_banner.dart';

class AdBannerShell extends StatefulWidget {
  final Widget child;
  final bool showBanner;

  const AdBannerShell({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  State<AdBannerShell> createState() => _AdBannerShellState();
}

class _AdBannerShellState extends State<AdBannerShell> {
  StreamSubscription<bool>? _proSub;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _proSub = SubscriptionManager.proStream.listen((isPro) {
      if (!mounted) return;
      setState(() => _isPro = isPro);
    });
  }

  Future<void> _loadPlan() async {
    final isPro = await SubscriptionManager.isPro();
    if (!mounted) return;
    setState(() => _isPro = isPro);
  }

  @override
  void dispose() {
    _proSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep every part of the home experience in the same safe frame. On Duo,
    // applying this only to the lower controls made their horizontal space
    // different from the preview and app bar.
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: widget.child),
          if (widget.showBanner && !_isPro)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: const SizedBox(
                      width: double.infinity,
                      child: AdBanner(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
