import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/features/home/home_screen.dart';
import 'package:showmyname/features/display/display_screen.dart';
import 'package:showmyname/features/display/widgets/effect_sign.dart';
import 'package:showmyname/l10n/app_localizations.dart';

void main() {
  for (final size in [const Size(386, 678), const Size(873, 678)]) {
    testWidgets('Preview uses final text layout at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'is_pro_real_v1': true});
      Widget app(Widget child) => MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            home: child,
          );
      await tester.pumpWidget(app(const Column(
          children: [Expanded(child: HomeScreen()), SizedBox(height: 78)])));
      await tester.pump();
      final preview = tester.widget<DisplayScreen>(find.byType(DisplayScreen));
      final engineSize = tester.getSize(find.byType(EffectSign));
      final textFinder = find.descendant(
          of: find.byType(EffectSign), matching: find.byType(Text));
      final previewText = tester.widget<Text>(textFinder);
      final previewTextSize = tester.getSize(textFinder);
      expect(engineSize, size);
      await tester.pumpWidget(app(DisplayScreen(config: preview.config)));
      await tester.pump();
      final finalFinder = find.descendant(
          of: find.byType(EffectSign), matching: find.byType(Text));
      final finalText = tester.widget<Text>(finalFinder);
      expect(tester.getSize(find.byType(EffectSign)), engineSize);
      expect(finalText.data, previewText.data);
      expect(finalText.style, previewText.style);
      expect(tester.getSize(finalFinder), previewTextSize);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 6));
    });
  }
}
