import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/display/widgets/handwriting_sign.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/l10n/app_localizations.dart';

void main() {
  testWidgets('Handwriting uses the organized side panel on wide layouts',
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

    await tester.tap(find.byKey(const ValueKey('mode-handwriting')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
        find.byKey(const ValueKey('wide-handwriting-panel')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('show-sign')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('wide-handwriting-canvas')),
      findsOneWidget,
    );
    expect(find.byType(HandwritingSign), findsOneWidget);
    expect(find.byKey(const ValueKey('handwriting-undo')), findsOneWidget);
    expect(find.byKey(const ValueKey('handwriting-redo')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('handwriting-background-color')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('add-handwriting-layer')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('wide-handwriting-canvas')),
      const Offset(48, 32),
    );
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('handwriting-undo')),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('share-created-image')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('handwriting-undo')));
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('handwriting-redo')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('add-handwriting-layer')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-handwriting-layer')));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('add-handwriting-layer')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
