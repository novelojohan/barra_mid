import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/errors/app_exception.dart';

/// Mensajes al usuario (SnackBars y diálogos) en un solo lugar.
class UiFeedback {
  UiFeedback._();

  static void exito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Muestra cualquier error de forma entendible. Si es un permiso negado
  /// para siempre, agrega un botón para ir a Ajustes.
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
