import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showmyname/app/app_controller.dart';

void main() {
  test('loads the saved visual theme and applies its card treatment', () async {
    SharedPreferences.setMockInitialValues({
      'app_visual_theme_style_v1': 'glassmorphism',
    });
    final controller = AppController();

    await controller.load();

    expect(controller.visualThemeStyle, VisualThemeStyle.glassmorphism);
    final theme = controller.buildTheme();
    expect(theme.cardTheme.color, const Color(0x661E2154));
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
    expect(theme.canvasColor, const Color(0xFF161827));
  });

  test('saves each visual theme selection', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();

    await controller.setVisualThemeStyle(VisualThemeStyle.skeuomorphism);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('app_visual_theme_style_v1'),
      'skeuomorphism',
    );
  });
}
