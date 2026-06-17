import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/update/update_service.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  UpdateDecision? _decision;
  bool _checking = true;
  bool _openingStore = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final decision = await UpdateService.checkForRequiredUpdate();
    if (!mounted) return;
    setState(() {
      _decision = decision;
      _checking = false;
    });
  }

  Future<void> _openStore() async {
    if (_openingStore) return;
    setState(() => _openingStore = true);
    await UpdateService.openStore();
    if (!mounted) return;
    setState(() => _openingStore = false);
  }

  @override
  Widget build(BuildContext context) {
    final decision = _decision;
    final requiresUpdate = decision?.requiresUpdate ?? false;

    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!requiresUpdate) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final latestVersion = decision?.latestVersion;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.system_update_alt, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'Update required',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Platform.isIOS
                            ? 'A newer version of ShowMyName is available. Please update to continue using the app.'
                            : 'An update is required to continue using ShowMyName.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (latestVersion != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Latest version: $latestVersion',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _openingStore ? null : _openStore,
                          child: Text(_openingStore ? 'Opening store...' : 'Update now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
