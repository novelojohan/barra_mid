import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';

/// Pantallitas reutilizables para los 3 estados del FutureBuilder:
/// cargando, error y vacío. Así todas las pantallas se ven igual.
///
/// Esta es la de "cargando": el circulito que gira (CircularProgressIndicator).
class CargandoVista extends StatelessWidget {
  final String mensaje;
  const CargandoVista({super.key, this.mensaje = 'Cargando…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(mensaje),
        ],
      ),
    );
  }
}

/// Cuando algo falla: ícono, mensaje y botón de Reintentar (en lugar de la pantalla roja)
class ErrorVista extends StatelessWidget {
  final Object? error;
  final VoidCallback alReintentar;
  const ErrorVista({super.key, required this.error, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    // Si es uno de mis errores uso su mensaje, si no, uno general
    final mensaje = error is AppException
        ? (error as AppException).message
        : 'Algo salió mal al cargar la información.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuando una lista no tiene nada, ej. "Aún no hay registros"
class VacioVista extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  const VacioVista({super.key, required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Animación para las listas: cada tarjeta aparece y sube un poquito.
/// Las de abajo tardan un poco más, por eso se ve que van entrando en orden.
class AparicionAnimada extends StatelessWidget {
  final int indice;
  final Widget child;
  const AparicionAnimada({super.key, required this.indice, required this.child});

  @override
  Widget build(BuildContext context) {
    // Entre más abajo esté la tarjeta (indice), más tarda, hasta un máximo
    final duracion = 250 + (indice > 8 ? 8 : indice) * 60;
    // TweenAnimationBuilder anima un número de 0 a 1.
    // Con ese número cambio la opacidad (aparece) y la posición (sube)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duracion),
      curve: Curves.easeOutCubic,
      builder: (context, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - valor)),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}
