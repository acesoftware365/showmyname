import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/features/display/display_screen.dart';
import 'package:showmyname/l10n/app_localizations.dart';

void main() {
  for (final largeText in [false, true]) {
    testWidgets('Editor survives resizing and keyboard, large text=$largeText',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(960, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      SharedPreferences.setMockInitialValues({'is_pro_real_v1': true});
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
          child: child!,
        ),
        home: Column(children: [
          Expanded(
              child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => const HomeScreen()))),
          const SizedBox(height: 78, child: Center(child: Text('Test banner'))),
        ]),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      final field = find.byKey(const ValueKey('sign-text-field'));
      expect(find.byKey(const ValueKey('fixed-adjustments-panel')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('editor-done')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.enterText(field, 'María 👋\nBienvenida al aeropuerto');
      final controller = tester.widget<TextField>(field).controller!;
      controller.selection = const TextSelection.collapsed(offset: 6);
      tester.testTextInput.hide();
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      final italic = find.byIcon(Icons.format_italic);
      await tester.ensureVisible(italic);
      await tester.tap(italic);
      await tester.pump();
      final underline = find.byIcon(Icons.format_underlined);
      await tester.tap(underline);
      await tester.pump();
      final config =
          tester.widget<DisplayScreen>(find.byType(DisplayScreen)).config;
      expect(config.italic, isTrue);
      expect(config.underline, isTrue);
      for (final size in [
        const Size(386, 650),
        const Size(678, 466),
        const Size(960, 700)
      ]) {
        tester.view.physicalSize = size;
        tester.view.viewInsets =
            FakeViewPadding(bottom: size.height < 500 ? 180 : 260);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        if (size.width < 600) {
          tester.view.resetViewInsets();
          await tester.pump();
          final previewRect =
              tester.getRect(find.byKey(const ValueKey('sign-preview')));
          expect(find.byKey(const ValueKey('sign-mode-bar')), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('open-compact-editor')));
          await tester.pump();
          expect(find.byKey(const ValueKey('sign-mode-bar')), findsNothing);
          final panelRect = tester
              .getRect(find.byKey(const ValueKey('fixed-adjustments-panel')));
          expect(panelRect.height, greaterThan(previewRect.height));
          await tester.tap(find.byKey(const ValueKey('close-compact-editor')));
          await tester.pump();
          expect(find.byKey(const ValueKey('sign-mode-bar')), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('open-compact-editor')));
          await tester.pump();
        }
        expect(tester.widget<TextField>(field).controller, same(controller));
        expect(controller.text, 'María 👋\nBienvenida al aeropuerto');
        expect(controller.selection.baseOffset, 6);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetViewInsets();
      await tester.pump();
      await tester.tap(find.text('Apariencia'));
      await tester.pump();
      expect(find.byType(Switch), findsOneWidget);
      final arrow = find.byKey(const ValueKey('sign-icon-→'));
      await tester.ensureVisible(arrow);
      await tester.tap(arrow);
      await tester.pump();
      final iconConfig =
          tester.widget<DisplayScreen>(find.byType(DisplayScreen)).config;
      expect(iconConfig.showIcon, isTrue);
      expect(iconConfig.iconSymbol, '→');
      expect(find.text('→ María 👋\nBienvenida al aeropuerto'), findsOneWidget);
      expect(find.byKey(const ValueKey('sign-text-field')), findsNothing);
      await tester.tap(find.text('Texto'));
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text,
          'María 👋\nBienvenida al aeropuerto');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 6));
    });
  }
}
