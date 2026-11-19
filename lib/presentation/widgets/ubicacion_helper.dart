import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/errors/app_exception.dart';
import '../../services/verificador_tienda.dart';

/// Lo que regresa al pedir el GPS al guardar.
/// cancelado = el usuario decidió no guardar
class ResultadoUbicacion {
  final CapturaUbicacion? captura;
  final bool cancelado;
  const ResultadoUbicacion._(this.captura, this.cancelado);

  static const cancelar = ResultadoUbicacion._(null, true);
  static const sinUbicacion = ResultadoUbicacion._(null, false);
}

/// Toma el GPS al guardar. Si falla (GPS apagado o sin permiso), en vez
/// de tronar le pregunto al usuario: ir a Ajustes, cancelar o guardar sin
/// ubicación. Así el GPS nunca bloquea el trabajo.
Future<ResultadoUbicacion> obtenerUbicacionParaGuardar(
  BuildContext context,
) async {
  try {
    // Intento sacar la ubicación y ver si está en la tienda
    final captura = await Injector.instance.verificadorTienda.capturar();
    return ResultadoUbicacion._(captura, false);
  // Si falló, enseño un diálogo con opciones
  } on AppException catch (e) {
    if (!context.mounted) return ResultadoUbicacion.cancelar;
    final permanente = e is PermissionDeniedException && e.permanentlyDenied;

    final opcion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_off),
        title: const Text('No se pudo obtener la ubicación'),
        content: Text(e.message),
        actions: [
          if (permanente)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'ajustes'),
              child: const Text('Ajustes'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancelar'),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'sin'),
            child: const Text('Guardar sin ubicación'),
          ),
        ],
      ),
    );

    // Según el botón que tocó, regreso lo que corresponde
    if (opcion == 'ajustes') {
      await Injector.instance.ubicacion.abrirAjustesApp();
      return ResultadoUbicacion.cancelar;
    }
    if (opcion == 'sin') return ResultadoUbicacion.sinUbicacion;
    return ResultadoUbicacion.cancelar;
  }
}
