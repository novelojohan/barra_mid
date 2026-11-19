import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/errors/app_exception.dart';

/// Todos los mensajes al usuario en un solo lugar:
/// los avisos de abajo (SnackBar) y el diálogo de confirmar.
class UiFeedback {
  UiFeedback._();

  // Mensaje normal abajo de la pantalla
  static void exito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context)
      // Si había otro mensaje, lo quito para que no se encimen
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Mensaje de error en rojo. Si el problema es un permiso negado
  /// para siempre, le pongo un botón que lleva a Ajustes
  static void error(BuildContext context, Object error) {
    final mensaje = error is AppException
        ? error.message
        : 'Ocurrió un error inesperado. Intenta de nuevo.';
    final irAjustes =
        error is PermissionDeniedException && error.permanentlyDenied;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        action: irAjustes
            ? SnackBarAction(
                label: 'Ajustes',
                onPressed: () => Injector.instance.ubicacion.abrirAjustesApp(),
              )
            : null,
      ));
  }

  // Diálogo de "¿Seguro?" con Cancelar y Aceptar. Regresa true si aceptó
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoAceptar = 'Aceptar',
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(textoAceptar),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }
}
