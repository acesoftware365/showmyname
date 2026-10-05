import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/l10n/app_localizations.dart';

void main() {
  testWidgets('Logo uses an organized side panel on wide layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(803, 678);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'is_pro_real_v1': true,
      'plan_preview_override_v1': 'pro',
    });

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.byKey(const ValueKey('mode-logo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('wide-logo-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('logo-upload')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('logo-upload-multiple')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('logo-remove')), findsOneWidget);
    expect(find.byKey(const ValueKey('logo-details')), findsNothing);
    expect(find.byKey(const ValueKey('wide-logo-status')), findsNothing);
    expect(
      find.byKey(const ValueKey('show-sign')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.text('Fade'));
    await tester.pump();
    expect(find.text('Wipe'), findsOneWidget);

    final showAction = tester.getRect(find.byKey(const ValueKey('show-sign')));
    final dock = tester.getRect(find.byKey(const ValueKey('mode-dock')));
    expect(showAction.bottom, lessThanOrEqualTo(dock.top));
    expect(tester.takeException(), isNull);
  });
}
