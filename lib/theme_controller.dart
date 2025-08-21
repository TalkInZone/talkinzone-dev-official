// lib/theme_controller.dart
//
// Controller del tema (Light / Dark / System) con persistenza.
// - Singleton: ThemeController.instance
// - Caricamento iniziale: await ThemeController.instance.load()
// - Cambio tema: ThemeController.instance.setMode(ThemeMode.dark)
// - Ascolto cambiamenti: AnimatedBuilder(animation: ThemeController.instance, ...)
//
// Salvataggio su SharedPreferences: chiave "_app_theme_mode" (valori: system|light|dark)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  static const String _kPrefKey = '_app_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Carica il tema salvato (default: ThemeMode.system).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefKey) ?? 'system';
      _mode = _decode(raw);
    } catch (_) {
      _mode = ThemeMode.system;
    }
  }

  /// Imposta e persiste il tema, notificando i listener.
  Future<void> setMode(ThemeMode newMode) async {
    if (_mode == newMode) {
      return;
    }
    _mode = newMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, _encode(newMode));
    } catch (_) {
      // In caso di errore di persistenza, lasciamo comunque il tema attivo.
    }
  }

  // --- Helpers di serializzazione ---
  String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        return 'system';
    }
  }

  ThemeMode _decode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
