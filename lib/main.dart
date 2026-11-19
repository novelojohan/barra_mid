import 'package:flutter/material.dart';

import 'app.dart';

/// Aquí arranca la app.
///
/// Separé el código en carpetas (capas) para que cada parte haga una sola cosa:
///   core/          -> cosas generales: rutas, tema, errores y el injector
///   domain/        -> los modelos (Insumo, Registro, Pendiente) y las interfaces
///   data/          -> todo lo de SQLite (la base de datos)
///   services/      -> lo que usa el hardware: huella, cámara, micrófono y GPS
///   presentation/  -> las pantallas y los widgets que ve el usuario
void main() {
  // Esto prepara Flutter antes de usar plugins (SQLite, cámara, etc.)
  WidgetsFlutterBinding.ensureInitialized();
  // Aquí se dibuja la app por primera vez
  runApp(const BarraMidApp());
}
