// Path: lib/features/paywall/paywall_screen.dart
// Description: Premium Pro paywall with Free vs Pro comparison.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/subscription/subscription_manager.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await SubscriptionManager.init();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _buyById(String id) async {
    await AnalyticsService.logPurchaseTap(id);
    final p = SubscriptionManager.productById(id);
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store product is not ready yet. Check product setup.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await SubscriptionManager.buy(p);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _busy = false);

    final pro = await SubscriptionManager.isPro();
    if (pro && mounted) context.pop();
  }

  Future<void> _restore() async {
    final t = AppLocalizations.of(context);

    await AnalyticsService.logRestoreTap();
    setState(() => _busy = true);
    try {
      await SubscriptionManager.restorePurchases();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _busy = false);

    final pro = await SubscriptionManager.isPro();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pro ? t.proRestored : t.restoreDone)),
    );

    if (pro) context.pop();
  }

  String _priceFor(String id, String fallback) {
    final product = SubscriptionManager.productById(id);
    return product?.price ?? fallback;
  }

  String _subscriptionLegalText(AppLocalizations t) {
    if (Platform.isIOS) return t.subLegalApple;
    if (Platform.isAndroid) return t.subLegalGoogle;
    return t.subLegal;
  }

  Future<void> _manageSubscription() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse(
            'https://play.google.com/store/account/subscriptions?package=com.liisgo.showmyname',
          );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open subscription settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final monthlyPrice = _priceFor(
      SubscriptionManager.monthlyProductId,
      SubscriptionManager.monthlyFallbackPrice,
    );
    final yearlyPrice = _priceFor(
      SubscriptionManager.yearlyProductId,
      SubscriptionManager.yearlyFallbackPrice,
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.goPro)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11131C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accent.withOpacity(0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.24),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ShowMyName Pro',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cleaner signs, premium effects, multiple logos, and no ads.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlanButton(
                    title: 'Yearly Pro',
                    price: yearlyPrice,
                    detail: 'Best value',
                    badge: 'SAVE',
                    filled: true,
                    busy: _busy,
                    onTap: () => _buyById(SubscriptionManager.yearlyProductId),
                  ),
                  const SizedBox(height: 10),
                  _PlanButton(
                    title: 'Monthly Pro',
                    price: monthlyPrice,
                    detail: 'Flexible monthly access',
                    filled: false,
                    busy: _busy,
                    onTap: () => _buyById(SubscriptionManager.monthlyProductId),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _CompareHeader(),
                          Divider(height: 22),
                          _CompareRow(
                            feature: 'Airport / Pickup readable sign',
                            free: true,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'ColorWave effects',
                            free: true,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'Ads removed',
                            free: false,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'Concert LED + premium effects',
                            free: false,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'Logo fullscreen',
                            free: false,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'Handwriting mode',
                            free: false,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'Logo rotation and effects',
                            free: false,
                            pro: true,
                          ),
                          _CompareRow(
                            feature: 'Premium themes',
                            free: false,
                            pro: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy ? null : _restore,
                    child: Text(t.restorePurchases),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _manageSubscription,
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(t.managePlan),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/terms'),
                          icon: const Icon(Icons.description_outlined),
                          label: Text(t.termsShort),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subscriptionLegalText(t),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white60, height: 1.3),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  final String title;
  final String price;
  final String detail;
  final String? badge;
  final bool filled;
  final bool busy;
  final VoidCallback onTap;

  const _PlanButton({
    required this.title,
    required this.price,
    required this.detail,
    required this.filled,
    required this.busy,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            price,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 66),
      child: filled
          ? FilledButton(
              onPressed: busy ? null : onTap,
              child: content,
            )
          : OutlinedButton(
              onPressed: busy ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withOpacity(0.7)),
              ),
              child: content,
            ),
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          flex: 5,
          child: Text(
            'Compare plans',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(child: Center(child: Text('Free'))),
        Expanded(child: Center(child: Text('Pro'))),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String feature;
  final bool free;
  final bool pro;

  const _CompareRow({
    required this.feature,
    required this.free,
    required this.pro,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(feature, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(child: _PlanMark(enabled: free)),
          Expanded(child: _PlanMark(enabled: pro)),
        ],
      ),
    );
  }
}

class _PlanMark extends StatelessWidget {
  final bool enabled;

  const _PlanMark({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        enabled ? Icons.check_circle : Icons.remove_circle_outline,
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withOpacity(0.26),
      ),
    );
  }
}
