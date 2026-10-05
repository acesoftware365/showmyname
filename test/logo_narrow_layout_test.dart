import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/l10n/app_localizations.dart';

void main() {
  testWidgets('Logo has a focused editor on narrow layouts', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(386, 590);
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

    final logoMode = find.byKey(const ValueKey('mode-logo'));
    await tester.ensureVisible(logoMode);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(logoMode);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('narrow-logo-preview')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('edit-logo')).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('wide-logo-panel')), findsNothing);
    expect(find.byKey(const ValueKey('logo-remove')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-logo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('narrow-logo-editor')), findsOneWidget);
    expect(find.byKey(const ValueKey('logo-upload')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('logo-upload-multiple')),
      findsOneWidget,
    );
    expect(find.text('Wipe'), findsNothing);

    tester.view.physicalSize = const Size(800, 500);
    tester.binding.handleMetricsChanged();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('narrow-logo-editor')), findsNothing);
    expect(find.byKey(const ValueKey('wide-logo-panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
