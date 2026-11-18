import 'package:flutter/material.dart';

/// Tema visual "Café premium": fondo espresso, tarjetas crema,
/// detalles dorados y títulos con tipografía serif (Playfair Display).
class AppTheme {
  AppTheme._();

  // Paleta
  static const Color espresso = Color(0xFF17110E);
  static const Color superficie = Color(0xFF231A15);
  static const Color superficieAlta = Color(0xFF2E231C);
  static const Color crema = Color(0xFFF4ECDF);
  static const Color cremaTexto = Color(0xFFEDE3D3);
  static const Color dorado = Color(0xFFC9A45C);
  static const Color cafeMedio = Color(0xFF7A6455);
  static const Color textoSuave = Color(0xFFBFAF9C);

  /// Rojo para fondo oscuro.
  static const Color alerta = Color(0xFFEF9A9A);

  /// Rojo para usar sobre las tarjetas crema.
  static const Color alertaFuerte = Color(0xFFB3261E);
  static const Color ok = Color(0xFF8BC48A);

  // Tipografía de títulos (variable font: el peso se da con fontVariations)
  static const String fuenteTitulos = 'Playfair';
  static const List<FontVariation> negrita = [FontVariation('wght', 700)];

  static ThemeData get oscuro {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: dorado,
      onPrimary: espresso,
      primaryContainer: Color(0xFF4A3B26),
      onPrimaryContainer: crema,
      secondary: Color(0xFFD8BE90),
      onSecondary: espresso,
      secondaryContainer: Color(0xFF3D3025),
      onSecondaryContainer: crema,
      error: alerta,
      onError: espresso,
      errorContainer: Color(0xFF5A2A26),
      onErrorContainer: crema,
      surface: superficie,
      onSurface: cremaTexto,
      onSurfaceVariant: textoSuave,
      surfaceContainerLowest: espresso,
      surfaceContainerLow: Color(0xFF1E1612),
      surfaceContainer: superficie,
      surfaceContainerHigh: superficieAlta,
      surfaceContainerHighest: Color(0xFF3A2D24),
      outline: Color(0xFF8C7A6A),
      outlineVariant: Color(0xFF4A3D34),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    TextStyle? serif(TextStyle? s) =>
        s?.copyWith(fontFamily: fuenteTitulos, fontVariations: negrita);

    return base.copyWith(
      scaffoldBackgroundColor: espresso,
      textTheme: base.textTheme.copyWith(
        headlineMedium: serif(base.textTheme.headlineMedium),
        headlineSmall: serif(base.textTheme.headlineSmall),
        titleLarge: serif(base.textTheme.titleLarge),
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: espresso,
        foregroundColor: crema,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fuenteTitulos,
          fontVariations: negrita,
          fontSize: 24,
          color: crema,
        ),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3A2D24)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: superficieAlta,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: dorado,
        foregroundColor: espresso,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: dorado,
        unselectedLabelColor: textoSuave,
        indicatorColor: dorado,
        dividerColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: superficieAlta),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: crema,
        contentTextStyle: TextStyle(color: espresso),
        actionTextColor: espresso,
        behavior: SnackBarBehavior.floating,
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: espresso,
        indicatorColor: Color(0xFF4A3B26),
      ),
    );
  }
}
