// Path: lib/features/settings/settings_screen.dart
// Description:
// Settings screen for ShowMyName (FREE).
// - No Free/Pro plan card
// - No Paywall access
// - Ads handled globally

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ✅ Needed for RenderBox (popover anchor on iPad)
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../services/subscription/subscription_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = false;
  String _languageValue = 'system';
  AppThemeStyle _themeValue = AppThemeStyle.purple;
  PlanPreviewOverride _planPreview = PlanPreviewOverride.none;
  bool _isPro = false;

  // ✅ Share anchor for iPad (popover)
  final GlobalKey _shareKey = GlobalKey();

  static const String _appleUrl =
      'https://apps.apple.com/us/app/showmyname-display/id6758596742';
  static const String _googleUrl =
      'https://play.google.com/store/apps/details?id=com.liisgo.showmyname&utm_source=na_Med';
  static const String _liisgoWebsite = 'https://liisgo.com';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final controller = AppScope.of(context);
    final locale = controller.locale;
    final lang = locale?.languageCode ?? 'system';
    final preview = await SubscriptionManager.getPreviewOverride();
    final isPro = await SubscriptionManager.isPro();

    if (!mounted) return;
    setState(() {
      _languageValue = lang;
      _themeValue = controller.themeStyle;
      _planPreview = preview;
      _isPro = isPro;
      _loading = false;
    });
  }

  Future<void> _onLanguageChanged(String value) async {
    final controller = AppScope.of(context);
    setState(() => _languageValue = value);

    if (value == 'system') {
      await controller.setLocale(null);
    } else {
      await controller.setLocale(Locale(value));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).languageChanged)),
    );
  }

  Future<void> _onThemeChanged(AppThemeStyle value) async {
    final controller = AppScope.of(context);
    setState(() => _themeValue = value);
    await controller.setThemeStyle(value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme saved.')),
    );
  }

  Future<void> _onPlanPreviewChanged(PlanPreviewOverride value) async {
    setState(() => _planPreview = value);
    await SubscriptionManager.setPreviewOverride(value);
    final isPro = await SubscriptionManager.isPro();
    if (!mounted) return;
    setState(() => _isPro = isPro);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value == PlanPreviewOverride.pro
              ? 'Previewing Pro version.'
              : value == PlanPreviewOverride.free
                  ? 'Previewing Free version.'
                  : 'Using real purchase status.',
        ),
      ),
    );
  }

  String _themeLabel(AppThemeStyle style) {
    return switch (style) {
      AppThemeStyle.purple => 'Purple Neon',
      AppThemeStyle.blue => 'Electric Blue',
      AppThemeStyle.pink => 'Hot Pink',
      AppThemeStyle.green => 'Lime Glow',
    };
  }

  Color _themeColor(AppThemeStyle style) {
    return switch (style) {
      AppThemeStyle.purple => const Color(0xFF8B5CF6),
      AppThemeStyle.blue => const Color(0xFF2563EB),
      AppThemeStyle.pink => const Color(0xFFEC4899),
      AppThemeStyle.green => const Color(0xFF22C55E),
    };
  }

  // ✅ FIX iPad: anchor the share sheet to the share button (popover)
  Future<void> _shareApp() async {
    const msg = '✨ ShowMyName ✨\n\n'
        'Turn your phone into a digital sign.\n'
        'Perfect for events, airports, and concerts.\n\n'
        'Convierte tu teléfono en un letrero digital.\n'
        'Ideal para eventos, aeropuertos y conciertos.\n\n'
        'Download / Descárgala:\n'
        'iOS: $_appleUrl\n'
        'Android: $_googleUrl\n\n\n'
        'Website: $_liisgoWebsite';

    // Prefer the exact button context (best for iPad popover).
    final anchorContext = _shareKey.currentContext ?? context;
    final box = anchorContext.findRenderObject() as RenderBox?;

    if (box == null) {
      await Share.share(msg);
      return;
    }

    await Share.share(
      msg,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Widget _buildVersionSubtitle(AppLocalizations t) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        if (!snap.hasData) return Text(t.versionUnknown);

        final info = snap.data!;
        final v = info.version.trim();
        final b = info.buildNumber.trim();

        return Text(b.isEmpty ? '${t.version}: $v' : '${t.version}: $v+$b');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
        actions: [
          IconButton(
            key: _shareKey, // ✅ anchor for iPad popover
            tooltip: t.shareApp,
            icon: const Icon(Icons.ios_share),
            onPressed: _shareApp,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          // Language
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.language,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _languageValue,
                    items: [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(t.languageSystemDefault),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(t.languageEnglish),
                      ),
                      DropdownMenuItem(
                        value: 'es',
                        child: Text(t.languageSpanish),
                      ),
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(t.languageFrench),
                      ),
                      DropdownMenuItem(
                        value: 'de',
                        child: Text(t.languageGerman),
                      ),
                      DropdownMenuItem(
                        value: 'pt',
                        child: Text(t.languagePortuguese),
                      ),
                      DropdownMenuItem(
                        value: 'hi',
                        child: Text(t.languageHindi),
                      ),
                      DropdownMenuItem(
                        value: 'ja',
                        child: Text(t.languageJapanese),
                      ),
                      DropdownMenuItem(
                        value: 'ru',
                        child: Text(t.languageRussian),
                      ),
                      DropdownMenuItem(
                        value: 'zh',
                        child: Text(t.languageChinese),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(t.languageArabic),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) _onLanguageChanged(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.languageHint,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Theme
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AppThemeStyle>(
                    value: _themeValue,
                    items: AppThemeStyle.values.map((style) {
                      return DropdownMenuItem(
                        value: style,
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _themeColor(style),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _themeColor(style).withOpacity(0.45),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(_themeLabel(style)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _onThemeChanged(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Changes the accent color across buttons, controls, and the ShowMyName logo.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isPro
                                  ? 'Pro preview active: no ads, premium features.'
                                  : 'Free preview active: ads visible, basic features.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () => context.push('/paywall'),
                        child: const Text('View Pro'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<PlanPreviewOverride>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: PlanPreviewOverride.free,
                        label: Text('Free'),
                      ),
                      ButtonSegment(
                        value: PlanPreviewOverride.pro,
                        label: Text('Pro'),
                      ),
                      ButtonSegment(
                        value: PlanPreviewOverride.none,
                        label: Text('Real'),
                      ),
                    ],
                    selected: {_planPreview},
                    onSelectionChanged: (selected) {
                      _onPlanPreviewChanged(selected.first);
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Use Free and Pro here to preview how the app looks before store purchases are live.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Privacy & About
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(t.privacyPolicy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(t.about),
                  subtitle: _buildVersionSubtitle(t),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              t.companyFooter,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
