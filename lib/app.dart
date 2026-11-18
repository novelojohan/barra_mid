import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class BarraMidApp extends StatelessWidget {
  const BarraMidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barra Mid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      initialRoute: Rutas.login,
      onGenerateRoute: Rutas.generar,
    );
  }
}
