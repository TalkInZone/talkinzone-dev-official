// lib/app_theme.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, grey }

class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  static const _prefsKeyTheme = 'app_theme';
  static const _prefsKeyLanguageCode = 'language_code';
  static const _prefsKeyCountryCode = 'country_code';
  
  AppTheme _theme = AppTheme.light;
  Locale _locale = const Locale('en'); // Default to English

  AppTheme get theme => _theme;
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final rawTheme = prefs.getString(_prefsKeyTheme);
    switch (rawTheme) {
      case 'dark':
        _theme = AppTheme.dark;
        break;
      case 'grey':
        _theme = AppTheme.grey;
        break;
      case 'light':
      default:
        _theme = AppTheme.light;
    }
    
    // Load language
    final languageCode = prefs.getString(_prefsKeyLanguageCode);
    final countryCode = prefs.getString(_prefsKeyCountryCode);
    
    if (languageCode != null) {
      _locale = Locale(languageCode, countryCode);
    } else {
      _locale = const Locale('en'); // Default to English
    }
    
    notifyListeners();
  }

  Future<void> setTheme(AppTheme t) async {
    _theme = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyTheme, t.name);
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLanguageCode, newLocale.languageCode);
    if (newLocale.countryCode != null) {
      await prefs.setString(_prefsKeyCountryCode, newLocale.countryCode!);
    } else {
      await prefs.remove(_prefsKeyCountryCode);
    }
  }
}

class AppThemes {
  // Tema chiaro standard (seed blu)
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // Tema scuro standard (seed blu)
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // Tema "grey" (tutto neutro, accent grigio) — disponibile in variante chiara e scura
  static final ThemeData greyLight = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF3F4F6),
      surfaceContainerHighest: const Color(0xFFE7E9EC),
    ),
  );

  static final ThemeData greyDark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF121315),
      surfaceContainerHighest: const Color(0xFF1C1E21),
    ),
  );
}