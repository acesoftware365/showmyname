// Path: lib/features/settings/settings_screen.dart
// Description:
// Settings screen for ShowMyName (FREE).
// - No Free/Pro plan card
// - No Paywall access
// - Ads handled globally

import 'package:flutter/material.dart';
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
  VisualThemeStyle _visualThemeValue = VisualThemeStyle.classic;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final controller = AppScope.read(context);
    final locale = controller.locale;
    final lang = locale?.languageCode ?? 'system';
    final isPro = await SubscriptionManager.isPro();
    var theme = controller.themeStyle;
    var visualTheme = controller.visualThemeStyle;

    if (!isPro && _isPremiumColorTheme(theme)) {
      theme = AppThemeStyle.purple;
      await controller.setThemeStyle(theme);
    }
    if (!isPro && _isPremiumVisualTheme(visualTheme)) {
      visualTheme = VisualThemeStyle.classic;
      await controller.setVisualThemeStyle(visualTheme);
    }

    if (!mounted) return;
    setState(() {
      _languageValue = lang;
      _themeValue = theme;
      _visualThemeValue = visualTheme;
      _isPro = isPro;
      _loading = false;
    });
  }

  Future<void> _onLanguageChanged(String value) async {
    final controller = AppScope.read(context);
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
    if (_isPremiumColorTheme(value) && !_isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).themeProRequired)),
      );
      context.push('/paywall');
      return;
    }

    final controller = AppScope.read(context);
    setState(() => _themeValue = value);
    await controller.setThemeStyle(value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).themeSaved)),
    );
  }

  Future<void> _onVisualThemeChanged(VisualThemeStyle value) async {
    if (_isPremiumVisualTheme(value) && !_isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visual themes are included with Pro.')),
      );
      context.push('/paywall');
      return;
    }

    final controller = AppScope.read(context);
    setState(() => _visualThemeValue = value);
    await controller.setVisualThemeStyle(value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visual theme saved.')),
    );
  }

  String _themeLabel(AppThemeStyle style, AppLocalizations t) {
    return switch (style) {
      AppThemeStyle.purple => t.themePurpleNeon,
      AppThemeStyle.blue => t.themeElectricBlue,
      AppThemeStyle.pink => t.themeHotPink,
      AppThemeStyle.green => t.themeLimeGlow,
      AppThemeStyle.sunset => t.themeSunsetPop,
      AppThemeStyle.aqua => t.themeAquaVibe,
      AppThemeStyle.cherry => t.themeCherryBomb,
      AppThemeStyle.lemon => t.themeLemonFlash,
      AppThemeStyle.cyber => t.themeCyberLime,
    };
  }

  bool _isPremiumColorTheme(AppThemeStyle style) {
    return style != AppThemeStyle.purple && style != AppThemeStyle.blue;
  }

  bool _isPremiumVisualTheme(VisualThemeStyle style) {
    return style != VisualThemeStyle.classic;
  }

  Color _themeColor(AppThemeStyle style) {
    return switch (style) {
      AppThemeStyle.purple => const Color(0xFF8B5CF6),
      AppThemeStyle.blue => const Color(0xFF2563EB),
      AppThemeStyle.pink => const Color(0xFFEC4899),
      AppThemeStyle.green => const Color(0xFF22C55E),
      AppThemeStyle.sunset => const Color(0xFFFF5A5F),
      AppThemeStyle.aqua => const Color(0xFF00D4FF),
      AppThemeStyle.cherry => const Color(0xFFFF2D75),
      AppThemeStyle.lemon => const Color(0xFFFACC15),
      AppThemeStyle.cyber => const Color(0xFF39FF14),
    };
  }

  String _visualThemeLabel(VisualThemeStyle style) {
    return switch (style) {
      VisualThemeStyle.classic => 'Classic',
      VisualThemeStyle.glassmorphism => 'Glassmorphism',
      VisualThemeStyle.claymorphism => 'Claymorphism',
      VisualThemeStyle.skeuomorphism => 'Skeuomorphism',
    };
  }

  IconData _visualThemeIcon(VisualThemeStyle style) {
    return switch (style) {
      VisualThemeStyle.classic => Icons.palette_outlined,
      VisualThemeStyle.glassmorphism => Icons.layers_outlined,
      VisualThemeStyle.claymorphism => Icons.blur_on_outlined,
      VisualThemeStyle.skeuomorphism => Icons.dialpad_outlined,
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

          // Color theme
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AppThemeStyle>(
                    value: _themeValue,
                    items: AppThemeStyle.values.map((style) {
                      return DropdownMenuItem(
                        value: style,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Text(_themeLabel(style, t)),
                            if (_isPremiumColorTheme(style)) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _isPro ? Icons.workspace_premium : Icons.lock,
                                size: 16,
                                color: _isPro
                                    ? _themeColor(style)
                                    : Colors.white54,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _onThemeChanged(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Purple Neon and Electric Blue are free. Extra colors are included with Pro.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Visual theme
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visual theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<VisualThemeStyle>(
                    key: const ValueKey('visual-theme'),
                    value: _visualThemeValue,
                    items: VisualThemeStyle.values.map((style) {
                      return DropdownMenuItem(
                        value: style,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_visualThemeIcon(style), size: 19),
                            const SizedBox(width: 10),
                            Text(_visualThemeLabel(style)),
                            if (_isPremiumVisualTheme(style)) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _isPro ? Icons.workspace_premium : Icons.lock,
                                size: 16,
                                color: _isPro
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white54,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) _onVisualThemeChanged(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Classic is free. Visual themes are included with Pro.',
                    style: TextStyle(color: Colors.white70),
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
                  title: Text(t.termsConditions),
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
