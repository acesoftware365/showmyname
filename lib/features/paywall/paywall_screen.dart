// Path: lib/features/paywall/paywall_screen.dart
// Description: Real Paywall screen using in_app_purchase products.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
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
    final p = SubscriptionManager.productById(id);
    if (p == null) return;

    setState(() => _busy = true);
    try {
      await SubscriptionManager.buy(p);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _busy = false);

    // If purchase succeeds, purchaseStream will update Pro.
    final pro = await SubscriptionManager.isPro();
    if (pro && mounted) context.pop();
  }

  Future<void> _restore() async {
    final t = AppLocalizations.of(context);

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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    const monthlyId = 'showmyname_pro_monthly';
    const yearlyId = 'showmyname_pro_yearly';

    final monthly = SubscriptionManager.productById(monthlyId);
    final yearly = SubscriptionManager.productById(yearlyId);

    return Scaffold(
      appBar: AppBar(title: Text(t.goPro)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.proUnlockTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              t.proUnlockBullets,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 20),

            // Yearly (highlight)
            _PriceButton(
              title: t.yearlyPlan,
              subtitle: yearly?.price ?? t.priceLoading,
              enabled: !_busy && yearly != null,
              filled: true,
              onTap: () => _buyById(yearlyId),
            ),
            const SizedBox(height: 10),

            // Monthly
            _PriceButton(
              title: t.monthlyPlan,
              subtitle: monthly?.price ?? t.priceLoading,
              enabled: !_busy && monthly != null,
              filled: false,
              onTap: () => _buyById(monthlyId),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: Text(t.restorePurchases),
            ),

            const Spacer(),

            // Simple legal text (minimal)
            Text(
              t.subLegal,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  const _PriceButton({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
      ],
    );

    return SizedBox(
      height: 56,
      child: filled
          ? FilledButton(onPressed: enabled ? onTap : null, child: child)
          : OutlinedButton(onPressed: enabled ? onTap : null, child: child),
    );
  }
}
