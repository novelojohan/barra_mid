import 'package:flutter/material.dart';

import 'app.dart';

/// Punto de entrada.
///
/// Arquitectura por capas:
///   core/          -> utilidades, errores, rutas, tema, inyección
///   domain/        -> modelos y contratos (interfaces de repositorios)
///   data/          -> implementación con SQLite
///   services/      -> hardware: biometría, cámara, micrófono, GPS
///   presentation/  -> pantallas y widgets
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarraMidApp());
}
