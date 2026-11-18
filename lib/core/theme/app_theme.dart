import 'package:flutter/material.dart';

/// Tema visual de la app (Material 3) con el verde de la barra.
class AppTheme {
  AppTheme._();

  static const Color verdeMid = Color(0xFF2F5D50);
  static const Color alerta = Color(0xFFC62828);
  static const Color ok = Color(0xFF2E7D32);

  static ThemeData get claro {
    final scheme = ColorScheme.fromSeed(seedColor: verdeMid);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }
}
