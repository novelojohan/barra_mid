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

/// Rutas con nombre de toda la app (Named Routes).
class Rutas {
  Rutas._();

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

  /// Construye cada pantalla según el nombre de la ruta y le pone una
  /// transición suave (fade + slide).
  static Route<dynamic> generar(RouteSettings settings) {
    final Widget pantalla;
    switch (settings.name) {
      case login:
        pantalla = const LoginScreen();
      case inventario:
        pantalla = const InventarioScreen();
      case bitacora:
        pantalla = const BitacoraScreen();
      case registroNuevo:
        pantalla = const RegistroFormScreen();
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
      default:
        pantalla = const Scaffold(
          body: Center(child: Text('Pantalla no encontrada')),
        );
    }

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => pantalla,
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
