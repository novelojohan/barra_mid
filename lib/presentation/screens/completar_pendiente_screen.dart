import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../domain/models/pendiente.dart';
import '../widgets/dictado_text_field.dart';
import '../widgets/foto_evidencia_field.dart';
import '../widgets/ubicacion_helper.dart';
import '../widgets/ui_feedback.dart';

/// Pantalla para terminar un pendiente: hay que subir la foto de evidencia
/// (lo que antes se mandaba por WhatsApp). También se puede dictar un comentario.
class CompletarPendienteScreen extends StatefulWidget {
  final Pendiente pendiente;
  const CompletarPendienteScreen({super.key, required this.pendiente});

  @override
  State<CompletarPendienteScreen> createState() =>
      _CompletarPendienteScreenState();
}

class _CompletarPendienteScreenState extends State<CompletarPendienteScreen> {
  final _di = Injector.instance;
  final _notaCtrl = TextEditingController();
  String? _fotoPath;
  bool _guardando = false;
  bool _guardado = false;

  @override
  void dispose() {
    _notaCtrl.dispose();
    // Si se salió sin guardar, borro la foto
    if (!_guardado) _di.media.eliminarFoto(_fotoPath);
    super.dispose();
  }

  Future<void> _guardar() async {
    // Sin foto no se puede marcar como hecho
    if (_fotoPath == null) {
      UiFeedback.exito(context, 'La foto de evidencia es obligatoria');
      return;
    }
    setState(() => _guardando = true);

    // Tomo el GPS para saber si la foto se tomó en la tienda
    final ubicacion = await obtenerUbicacionParaGuardar(context);
    if (ubicacion.cancelado) {
      if (mounted) setState(() => _guardando = false);
      return;
    }

    try {
      // Creo la copia del pendiente ya completado y la guardo
      await _di.pendientes.marcarComoHecho(widget.pendiente.completar(
        empleado: _di.empleado,
        evidenciaPath: _fotoPath!,
        nota: _notaCtrl.text.trim(),
        ubicacion: ubicacion.captura?.punto,
        enTienda: ubicacion.captura?.enTienda,
      ));
      _guardado = true;
      if (!mounted) return;
      UiFeedback.exito(context, '¡Pendiente terminado!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        UiFeedback.error(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Subir evidencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(widget.pendiente.titulo,
                  style: tema.textTheme.titleMedium),
              subtitle: Text(widget.pendiente.descripcion.isEmpty
                  ? widget.pendiente.area
                  : '${widget.pendiente.area} · ${widget.pendiente.descripcion}'),
            ),
          ),
          const SizedBox(height: 20),
          FotoEvidenciaField(
            etiqueta: 'Foto de evidencia',
            obligatoria: true,
            ruta: _fotoPath,
            alCambiar: (ruta) => setState(() => _fotoPath = ruta),
          ),
          const SizedBox(height: 20),
          DictadoTextField(
            controller: _notaCtrl,
            etiqueta: 'Comentario (opcional)',
            hint: 'Ej. Se realiza limpieza de la Breville :)',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt),
            label: Text(_guardando ? 'Guardando…' : 'Marcar como hecho'),
          ),
        ],
      ),
    );
  }
}
