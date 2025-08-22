// lib/i18n/app_locale.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();
  static final AppLocaleController instance = AppLocaleController._();

  Locale _locale = const Locale('en'); // default inglese
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'en';
    _locale = Locale(code);
  }

  Future<void> setLocale(Locale l) async {
    if (_locale == l) return;
    _locale = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', l.languageCode);
    notifyListeners();
  }
}
