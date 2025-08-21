// lib/app_theme.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, grey }

class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  static const _prefsKey = 'app_theme';
  AppTheme _theme = AppTheme.light;

  AppTheme get theme => _theme;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    switch (raw) {
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
    notifyListeners();
  }

  Future<void> setTheme(AppTheme t) async {
    _theme = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, t.name);
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
