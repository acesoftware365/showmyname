// Path: lib/app/app_controller.dart
// Description: Global app state controller (ChangeNotifier).
// Holds and updates the current Locale. Notifies listeners so MaterialApp rebuilds.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language/language_service.dart';

enum AppThemeStyle {
  purple,
  blue,
  pink,
  green,
  sunset,
  aqua,
  cherry,
  lemon,
  cyber,
}

class AppController extends ChangeNotifier {
  static const String _kThemeStyle = 'app_theme_style_v1';

  Locale? _locale;
  AppThemeStyle _themeStyle = AppThemeStyle.purple;

  Locale? get locale => _locale;
  AppThemeStyle get themeStyle => _themeStyle;

  Future<void> load() async {
    _locale = await LanguageService.loadSavedLocale();
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_kThemeStyle);
    _themeStyle = AppThemeStyle.values.firstWhere(
      (style) => style.name == savedTheme,
      orElse: () => AppThemeStyle.purple,
    );
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;

    if (locale == null) {
      await LanguageService.clearSavedLocale();
    } else {
      await LanguageService.saveLocaleCode(locale.languageCode);
    }

    notifyListeners();
  }

  bool isSelected(String languageCode) {
    return _locale?.languageCode == languageCode;
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeStyle, style.name);
    notifyListeners();
  }

  ThemeData buildTheme() {
    final seed = switch (_themeStyle) {
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

    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: seed,
        thumbColor: Color.lerp(seed, Colors.white, 0.35),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return seed.withOpacity(0.72);
          }
          return null;
        }),
      ),
    );
  }
}
