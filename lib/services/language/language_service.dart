// Path: lib/services/language/language_service.dart
// Description: Persists the selected language (locale) using SharedPreferences.
// Supports: English (en) and Spanish (es).
// Provides: loadSavedLocale(), saveLocaleCode(), clearSavedLocale().

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static const String _kLocaleCode = 'app_locale_code_v1';

  static const supported = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
    Locale('hi'),
    Locale('ja'),
    Locale('ru'),
    Locale('zh'),
    Locale('ar'),
  ];

  static Future<Locale?> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleCode);
    if (code == null || code.isEmpty) return null;

    // Only allow supported locales
    for (final loc in supported) {
      if (loc.languageCode == code) return loc;
    }
    return null;
  }

  static Future<void> saveLocaleCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleCode, languageCode);
  }

  static Future<void> clearSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocaleCode);
  }
}
