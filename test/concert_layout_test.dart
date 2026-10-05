import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/l10n/app_localizations.dart';
import 'package:showmyname/models/sign_mode.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
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

    final eventMode = find.byKey(const ValueKey('mode-event'));
    await tester.ensureVisible(eventMode);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(eventMode);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('Concert uses the organized side panel on wide layouts',
      (tester) async {
    await pumpHome(tester, const Size(803, 678));

    expect(find.byKey(const ValueKey('wide-concert-panel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('wide-concert-preview')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('concert-editor-tabs')), findsOneWidget);
    expect(find.byKey(const ValueKey('concert-text-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('concert-effects-tab')));
    await tester.pump();

    expect(find.byKey(const ValueKey('concert-style')), findsOneWidget);
    expect(find.text('LED color'), findsOneWidget);

    final styleControl =
        tester.widget<DropdownButtonFormField<ConcertTextEffect>>(
      find.byKey(const ValueKey('concert-style')),
    );
    styleControl.onChanged!(ConcertTextEffect.simple);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('simple-concert-motion-direction')),
      findsOneWidget,
    );
    expect(find.text('LED color'), findsNothing);
    expect(
      find.byKey(const ValueKey('show-sign')).hitTestable(),
      findsOneWidget,
    );

    final showAction = tester.getRect(find.byKey(const ValueKey('show-sign')));
    final dock = tester.getRect(find.byKey(const ValueKey('mode-dock')));
    expect(showAction.bottom, lessThanOrEqualTo(dock.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Concert has a focused editor on narrow layouts', (tester) async {
    await pumpHome(tester, const Size(386, 590));

    expect(
      find.byKey(const ValueKey('narrow-concert-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-concert')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('wide-concert-panel')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('edit-concert')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('narrow-concert-editor')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('concert-editor-tabs')), findsOneWidget);
    expect(find.byKey(const ValueKey('concert-text-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('concert-effects-tab')));
    await tester.pump();

    expect(find.byKey(const ValueKey('concert-style')), findsOneWidget);
    expect(find.text('Preview & tune'), findsNothing);

    tester.view.physicalSize = const Size(800, 500);
    tester.binding.handleMetricsChanged();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('narrow-concert-editor')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('wide-concert-panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
