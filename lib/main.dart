// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/app_controller.dart';
import 'app/app_scope.dart';
import 'app/routing/app_router.dart';
import 'features/update/force_update_gate.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final AppController _controller = AppController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            locale: _controller.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ✅ FIX AQUÍ:
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return ForceUpdateGate(child: child ?? const SizedBox.shrink());
            },
            theme: _controller.buildTheme(),
          );
        },
      ),
    );
  }
}
