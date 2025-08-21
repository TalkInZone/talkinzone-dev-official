import 'package:flutter/material.dart';

/// Cambia questo seedColor per personalizzare il brand.
const _seed = Colors.teal;

/// Tema chiaro (Light)
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
  ),
  brightness: Brightness.light,
);

/// Tema scuro (Dark)
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  ),
  brightness: Brightness.dark,
);
