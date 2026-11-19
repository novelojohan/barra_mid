import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

// Widget principal: aquí configuro el tema y las rutas de toda la app
class BarraMidApp extends StatelessWidget {
  const BarraMidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barra Mid',
      debugShowCheckedModeBanner: false,
      // El diseño "Café premium" (colores, letras) está en app_theme.dart
      theme: AppTheme.oscuro,
      // La app siempre empieza en el login
      initialRoute: Rutas.login,
      // Cada vez que navego a una ruta, esta función construye la pantalla
      onGenerateRoute: Rutas.generar,
    );
  }
}
