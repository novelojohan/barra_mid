import 'package:flutter/material.dart';

/// Aquí está todo el diseño de la app, el estilo "Café premium":
/// fondo color espresso, tarjetas crema, detalles dorados y títulos
/// con una letra elegante (Playfair Display).
/// Lo puse todo en un solo lugar para que todas las pantallas se vean igual.
class AppTheme {
  AppTheme._();

  // Mis colores (en hexadecimal, el FF del inicio es que no es transparente)
  static const Color espresso = Color(0xFF17110E);
  static const Color superficie = Color(0xFF231A15);
  static const Color superficieAlta = Color(0xFF2E231C);
  static const Color crema = Color(0xFFF4ECDF);
  static const Color cremaTexto = Color(0xFFEDE3D3);
  static const Color dorado = Color(0xFFC9A45C);
  static const Color cafeMedio = Color(0xFF7A6455);
  static const Color textoSuave = Color(0xFFBFAF9C);

  /// Rojo clarito para avisos sobre fondo oscuro
  static const Color alerta = Color(0xFFEF9A9A);

  /// Rojo fuerte para avisos sobre las tarjetas crema (el clarito no se lee)
  static const Color alertaFuerte = Color(0xFFB3261E);
  static const Color ok = Color(0xFF8BC48A);

  // La letra de los títulos. Es una fuente "variable", o sea que el grosor
  // se elige con fontVariations (700 = negrita)
  static const String fuenteTitulos = 'Playfair';
  static const List<FontVariation> negrita = [FontVariation('wght', 700)];

  // Aquí armo el tema completo que uso en app.dart
  static ThemeData get oscuro {
    // ColorScheme son los colores que usan por defecto los widgets de Material
    // (botones, campos, menús). primary = dorado, surface = fondo de tarjetas, etc.
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

    // Parto de un tema normal de Material 3 con mis colores...
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    // Función chiquita para ponerle la letra Playfair a un estilo de texto
    TextStyle? serif(TextStyle? s) =>
        s?.copyWith(fontFamily: fuenteTitulos, fontVariations: negrita);

    // ...y le cambio solo lo que quiero personalizar
    return base.copyWith(
      scaffoldBackgroundColor: espresso,
      // Los títulos grandes usan la letra Playfair
      textTheme: base.textTheme.copyWith(
        headlineMedium: serif(base.textTheme.headlineMedium),
        headlineSmall: serif(base.textTheme.headlineSmall),
        titleLarge: serif(base.textTheme.titleLarge),
      ),
      // Barra de arriba: fondo oscuro y título en crema
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
      // Tarjetas con esquinas redondeadas y sin sombra
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3A2D24)),
        ),
      ),
      // Campos de texto con fondo y bordes redondeados
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: superficieAlta,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // El botón flotante (Registrar, Nuevo pendiente) en dorado
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: dorado,
        foregroundColor: espresso,
      ),
      // Pestañas: la seleccionada en dorado
      tabBarTheme: const TabBarThemeData(
        labelColor: dorado,
        unselectedLabelColor: textoSuave,
        indicatorColor: dorado,
        dividerColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: superficieAlta),
      // Los mensajitos de abajo (SnackBar) en color crema
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: crema,
        contentTextStyle: TextStyle(color: espresso),
        actionTextColor: espresso,
        behavior: SnackBarBehavior.floating,
      ),
      // El menú lateral (Drawer)
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: espresso,
        indicatorColor: Color(0xFF4A3B26),
      ),
    );
  }
}
