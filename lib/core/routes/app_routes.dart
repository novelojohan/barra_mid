import 'package:flutter/material.dart';

import '../../domain/models/pendiente.dart';
import '../../domain/models/registro.dart';
import '../../presentation/screens/acerca_screen.dart';
import '../../presentation/screens/bitacora_screen.dart';
import '../../presentation/screens/completar_pendiente_screen.dart';
import '../../presentation/screens/inventario_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/pendiente_detalle_screen.dart';
import '../../presentation/screens/pendiente_form_screen.dart';
import '../../presentation/screens/pendientes_screen.dart';
import '../../presentation/screens/registro_detalle_screen.dart';
import '../../presentation/screens/registro_form_screen.dart';
import '../../presentation/screens/tienda_screen.dart';

/// Aquí están todas las rutas (pantallas) de la app con su nombre.
/// En vez de escribir la pantalla cada vez que navego, uso el nombre,
/// ej. Navigator.pushNamed(context, Rutas.bitacora)
class Rutas {
  Rutas._();

  // El nombre de cada pantalla
  static const login = '/';
  static const inventario = '/inventario';
  static const bitacora = '/bitacora';
  static const registroNuevo = '/bitacora/nuevo';
  static const registroDetalle = '/bitacora/detalle';
  static const pendientes = '/pendientes';
  static const pendienteNuevo = '/pendientes/nuevo';
  static const pendienteDetalle = '/pendientes/detalle';
  static const pendienteCompletar = '/pendientes/completar';
  static const tienda = '/tienda';
  static const acerca = '/acerca';

  /// Esta función se llama cada vez que navego a una ruta.
  /// Según el nombre, decide qué pantalla mostrar y le pone una animación
  /// de entrada (aparece y sube un poquito).
  static Route<dynamic> generar(RouteSettings settings) {
    final Widget pantalla;
    // Reviso el nombre de la ruta para saber qué pantalla crear
    switch (settings.name) {
      case login:
        pantalla = const LoginScreen();
      case inventario:
        pantalla = const InventarioScreen();
      case bitacora:
        pantalla = const BitacoraScreen();
      case registroNuevo:
        pantalla = const RegistroFormScreen();
      // Las pantallas de detalle necesitan saber QUÉ registro mostrar,
      // eso viene en settings.arguments (lo mando al hacer pushNamed)
      case registroDetalle:
        pantalla = RegistroDetalleScreen(registro: settings.arguments as Registro);
      case pendientes:
        pantalla = const PendientesScreen();
      case pendienteNuevo:
        pantalla = const PendienteFormScreen();
      case pendienteDetalle:
        pantalla =
            PendienteDetalleScreen(pendiente: settings.arguments as Pendiente);
      case pendienteCompletar:
        pantalla =
            CompletarPendienteScreen(pendiente: settings.arguments as Pendiente);
      case tienda:
        pantalla = const TiendaScreen();
      case acerca:
        pantalla = const AcercaScreen();
      // Por si alguien navega a una ruta que no existe
      default:
        pantalla = const Scaffold(
          body: Center(child: Text('Pantalla no encontrada')),
        );
    }

    // PageRouteBuilder me deja hacer mi propia animación de transición
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => pantalla,
      // animation va de 0 a 1 mientras dura la transición.
      // Con eso hago que la pantalla aparezca (Fade) y suba un poco (Slide)
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curva =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curva,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curva),
            child: child,
          ),
        );
      },
    );
  }
}
