import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/l10n/app_localizations.dart';

void main() {
  for (final size in [
    const Size(386, 590),
    const Size(678, 466),
    const Size(803, 678),
    const Size(320, 568)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home actions fit $size at text scale $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({'is_pro_real_v1': false});
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Column(children: [
            Expanded(child: HomeScreen()),
            SizedBox(height: 78), // Reserve space for the free-plan banner.
          ]),
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 1));
        final dock = find.byKey(const ValueKey('mode-dock'));
        expect(dock, findsOneWidget);
        expect(
            tester.getSize(dock).width, greaterThanOrEqualTo(size.width - 28));
        expect(tester.getSize(dock).width, lessThanOrEqualTo(size.width - 24));
        expect(
          find.byKey(const ValueKey('animated-mode-dock')),
          size.width >= 600 ? findsNothing : findsOneWidget,
        );
        final action = find.byKey(const ValueKey('show-sign'));
        expect(action.hitTestable(), findsOneWidget);
        expect(
            tester.getRect(action).bottom, lessThanOrEqualTo(size.height - 78));
        expect(tester.takeException(), isNull);
        if (find.byType(CustomScrollView).evaluate().isNotEmpty) {
          await tester.drag(
              find.byType(CustomScrollView), const Offset(0, -500));
        }
        await tester.pump();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        final colorWave = find.byKey(const ValueKey('mode-colorWave'));
        await tester.ensureVisible(colorWave);
        await tester.tap(colorWave);
        await tester.pump();
        expect(find.text('Edit ColorWave Style'), findsNothing);
        expect(
          size.width >= 600
              ? find.byKey(const ValueKey('fixed-adjustments-panel'))
              : find.byKey(const ValueKey('open-compact-editor')),
          findsOneWidget,
        );
        if (size.width < 600) {
          await tester.tap(find.byKey(const ValueKey('open-compact-editor')));
          await tester.pump();
        }
        expect(
          find.byKey(const ValueKey('color-wave-text-formatting')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('color-wave-text-alignment')),
          findsOneWidget,
        );
        if (size.width < 600) {
          await tester.tap(find.byKey(const ValueKey('close-compact-editor')));
          await tester.pump();
        }

        final logo = find.byKey(const ValueKey('mode-logo'));
        await tester.ensureVisible(logo);
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('Logo'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Watch one ad to use this feature once.'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
