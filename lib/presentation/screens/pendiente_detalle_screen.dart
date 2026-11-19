import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/models/pendiente.dart';
import '../widgets/foto_archivo.dart';
import '../widgets/ubicacion_mapa.dart';
import '../widgets/ui_feedback.dart';

/// Detalle de un pendiente. Si ya está hecho enseña la evidencia
/// (foto, quién lo hizo, cuándo y el mapa). Si no, el botón para completarlo.
class PendienteDetalleScreen extends StatelessWidget {
  final Pendiente pendiente;
  const PendienteDetalleScreen({super.key, required this.pendiente});

  // Borrar el pendiente (solo admin), pidiendo confirmación
  Future<void> _eliminar(BuildContext context) async {
    final ok = await UiFeedback.confirmar(
      context,
      titulo: 'Eliminar pendiente',
      mensaje: '¿Seguro que quieres eliminar "${pendiente.titulo}"?',
      textoAceptar: 'Eliminar',
    );
    if (!ok || !context.mounted) return;
    try {
      await Injector.instance.pendientes.eliminarPendiente(pendiente.id!);
      await Injector.instance.media.eliminarFoto(pendiente.evidenciaPath);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) UiFeedback.error(context, e);
    }
  }

  Future<void> _completar(BuildContext context) async {
    // Abre la pantalla de evidencia. Cuando termina, cierro también este
    // detalle para regresar directo a la lista
    final hecho = await Navigator.pushNamed(
      context,
      Rutas.pendienteCompletar,
      arguments: pendiente,
    );
    if (hecho == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(pendiente.area),
        actions: [
          // El botón de borrar solo aparece en modo admin
          if (Injector.instance.esAdmin)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () => _eliminar(context),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Si ya está hecho, enseño la foto con Hero
          if (pendiente.hecho)
            Hero(
              tag: 'pendiente-${pendiente.id}',
              child: FotoArchivo(
                ruta: pendiente.evidenciaPath,
                height: 280,
                width: double.infinity,
              ),
            ),
          const SizedBox(height: 16),
          Text(pendiente.titulo, style: tema.textTheme.headlineSmall),
          if (pendiente.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(pendiente.descripcion),
          ],
          const SizedBox(height: 8),
          Text(
            'Creado por ${pendiente.creadoPor} el ${DateFormatter.fechaCorta(pendiente.fechaCreacion)}',
            style: TextStyle(color: tema.colorScheme.outline),
          ),
          const Divider(height: 32),
          if (!pendiente.hecho)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: () => _completar(context),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Subir evidencia y marcar hecho'),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.task_alt, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hecho por ${pendiente.completadoPor} · ${DateFormatter.fechaLarga(pendiente.fechaCompletado!)} a las ${DateFormatter.hora(pendiente.fechaCompletado!)}',
                  ),
                ),
              ],
            ),
            if ((pendiente.notaEvidencia ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('"${pendiente.notaEvidencia}"',
                  style: tema.textTheme.bodyLarge
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 20),
            Text('Dónde se tomó la evidencia', style: tema.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (pendiente.ubicacion != null)
              UbicacionMapa(
                punto: pendiente.ubicacion!,
                enTienda: pendiente.enTienda,
              )
            else
              const Text('La evidencia se guardó sin ubicación.'),
          ],
        ],
      ),
    );
  }
}
