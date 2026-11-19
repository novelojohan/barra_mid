import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/models/registro.dart';
import '../widgets/foto_archivo.dart';
import '../widgets/ubicacion_mapa.dart';
import '../widgets/ui_feedback.dart';

/// Detalle de un registro: foto grande, insumos, nota, quién y cuándo, y el mapa.
/// Es StatelessWidget porque solo enseña datos, no cambia.
class RegistroDetalleScreen extends StatelessWidget {
  final Registro registro;
  const RegistroDetalleScreen({super.key, required this.registro});

  // Borrar (solo lo ve el admin). Primero pregunta si está seguro
  Future<void> _eliminar(BuildContext context) async {
    final confirmar = await UiFeedback.confirmar(
      context,
      titulo: 'Eliminar registro',
      mensaje: 'Se borrará el registro y se revertirán las cantidades '
          'en el inventario. ¿Continuar?',
      textoAceptar: 'Eliminar',
    );
    if (!confirmar || !context.mounted) return;

    try {
      // Borro el registro (esto regresa las cantidades del inventario) y luego la foto
      await Injector.instance.registros.eliminarRegistro(registro);
      await Injector.instance.media.eliminarFoto(registro.fotoPath);
      if (!context.mounted) return;
      Navigator.pop(context, true); // true = avisa a la lista que se recargue
    } catch (e) {
      if (context.mounted) UiFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final signo = registro.tipo.signo > 0 ? '+' : '−';

    return Scaffold(
      appBar: AppBar(
        title: Text(registro.tipo.etiqueta),
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
          if (registro.fotoPath != null)
            // El mismo tag que en la lista, así Flutter anima la foto entre pantallas
            Hero(
              tag: 'registro-${registro.id}',
              child: FotoArchivo(
                ruta: registro.fotoPath,
                height: 260,
                width: double.infinity,
              ),
            ),
          const SizedBox(height: 16),
          Text(DateFormatter.fechaLarga(registro.fecha),
              style: tema.textTheme.titleMedium),
          Text(
            'Registró ${registro.empleado} a las ${DateFormatter.hora(registro.fecha)}',
            style: TextStyle(color: tema.colorScheme.outline),
          ),
          const SizedBox(height: 20),
          Text('Insumos', style: tema.textTheme.titleSmall),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                for (final item in registro.items)
                  ListTile(
                    dense: true,
                    title: Text(item.nombre),
                    trailing: Text(
                      '$signo${item.cantidad} ${item.unidad}',
                      style: tema.textTheme.titleMedium,
                    ),
                  ),
              ],
            ),
          ),
          if (registro.nota.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Nota', style: tema.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(registro.nota, style: tema.textTheme.bodyLarge),
          ],
          const SizedBox(height: 20),
          Text('Ubicación', style: tema.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (registro.ubicacion != null)
            // Mapa con el punto donde se guardó y botón a Google Maps
            UbicacionMapa(
              punto: registro.ubicacion!,
              enTienda: registro.enTienda,
            )
          else
            const Text('Este registro se guardó sin ubicación.'),
        ],
      ),
    );
  }
}
