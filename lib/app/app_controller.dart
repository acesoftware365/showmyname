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

enum VisualThemeStyle {
  classic,
  glassmorphism,
  claymorphism,
  skeuomorphism,
}

class AppController extends ChangeNotifier {
  static const String _kThemeStyle = 'app_theme_style_v1';
  static const String _kVisualThemeStyle = 'app_visual_theme_style_v1';

  Locale? _locale;
  AppThemeStyle _themeStyle = AppThemeStyle.purple;
  VisualThemeStyle _visualThemeStyle = VisualThemeStyle.classic;

  Locale? get locale => _locale;
  AppThemeStyle get themeStyle => _themeStyle;
  VisualThemeStyle get visualThemeStyle => _visualThemeStyle;

  Future<void> load() async {
    _locale = await LanguageService.loadSavedLocale();
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_kThemeStyle);
    _themeStyle = AppThemeStyle.values.firstWhere(
      (style) => style.name == savedTheme,
      orElse: () => AppThemeStyle.purple,
    );
    final savedVisualTheme = prefs.getString(_kVisualThemeStyle);
    _visualThemeStyle = VisualThemeStyle.values.firstWhere(
      (style) => style.name == savedVisualTheme,
      orElse: () => VisualThemeStyle.classic,
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

  Future<void> setVisualThemeStyle(VisualThemeStyle style) async {
    _visualThemeStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVisualThemeStyle, style.name);
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

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final baseTheme = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D1018),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1018),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xEB11131C),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x14FFFFFF)),
        ),
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

    return switch (_visualThemeStyle) {
      VisualThemeStyle.classic => baseTheme,
      VisualThemeStyle.glassmorphism => baseTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: const Color(0xFF161827),
          colorScheme: colorScheme.copyWith(
            surfaceContainerHigh: const Color(0x4D1B1D4B),
            outlineVariant: const Color(0x99FFFFFF),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: const Color(0x661E2154),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: const BorderSide(color: Color(0xB3FFFFFF), width: 1.2),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0x472B2E68),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0x99FFFFFF)),
            ),
          ),
        ),
      VisualThemeStyle.claymorphism => baseTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: const Color(0xFF2C203E),
          colorScheme: colorScheme.copyWith(
            surfaceContainerHigh: const Color(0xFF463562),
            outlineVariant: const Color(0xFF75618D),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF3C2C55),
            elevation: 16,
            shadowColor: const Color(0xD6000000),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: const BorderSide(color: Color(0xFF60487C), width: 1.2),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF241A33),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFF745695)),
            ),
          ),
        ),
      VisualThemeStyle.skeuomorphism => baseTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: const Color(0xFF22242A),
          colorScheme: colorScheme.copyWith(
            surfaceContainerHigh: const Color(0xFF383B43),
            outlineVariant: const Color(0xFF8A8E98),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF343740),
            elevation: 16,
            shadowColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF969BA6), width: 1.4),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1B1D22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide:
                  const BorderSide(color: Color(0xFFA3A8B3), width: 1.2),
            ),
          ),
        ),
    };
  }

  Decoration buildBackgroundDecoration() {
    return switch (_visualThemeStyle) {
      VisualThemeStyle.classic => const BoxDecoration(color: Color(0xFF0D1018)),
      VisualThemeStyle.glassmorphism => const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07091C), Color(0xFF281653), Color(0xFF06394A)],
          ),
        ),
      VisualThemeStyle.claymorphism => const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF161020), Color(0xFF4B3566), Color(0xFF1A1230)],
          ),
        ),
      VisualThemeStyle.skeuomorphism => const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0C0F), Color(0xFF363942), Color(0xFF111216)],
          ),
        ),
    };
  }
}
