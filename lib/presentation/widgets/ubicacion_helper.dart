import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/errors/app_exception.dart';
import '../../services/verificador_tienda.dart';

/// Resultado de pedir el GPS al momento de guardar.
class ResultadoUbicacion {
  final CapturaUbicacion? captura;
  final bool cancelado;
  const ResultadoUbicacion._(this.captura, this.cancelado);

  static const cancelar = ResultadoUbicacion._(null, true);
  static const sinUbicacion = ResultadoUbicacion._(null, false);
}

/// Captura el GPS al guardar. Si falla (GPS apagado o permiso negado)
/// le pregunta al usuario si quiere guardar sin ubicación, cancelar
/// o ir a ajustes. Así la app nunca se traba por el GPS.
Future<ResultadoUbicacion> obtenerUbicacionParaGuardar(
  BuildContext context,
) async {
  try {
    final captura = await Injector.instance.verificadorTienda.capturar();
    return ResultadoUbicacion._(captura, false);
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

    if (opcion == 'ajustes') {
      await Injector.instance.ubicacion.abrirAjustesApp();
      return ResultadoUbicacion.cancelar;
    }
    if (opcion == 'sin') return ResultadoUbicacion.sinUbicacion;
    return ResultadoUbicacion.cancelar;
  }
}
