// Path: lib/ads/ad_banner_shell.dart
// Description:
// Wraps normal screens and shows ads only for Free users.

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/subscription/subscription_manager.dart';
import 'ad_banner.dart';

class AdBannerShell extends StatefulWidget {
  final Widget child;

  const AdBannerShell({
    super.key,
    required this.child,
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
    return Column(
      children: [
        Expanded(child: widget.child),
        if (!_isPro)
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
