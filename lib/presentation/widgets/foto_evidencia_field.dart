import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../services/media_service.dart';
import 'foto_archivo.dart';
import 'ui_feedback.dart';

/// Campo para la foto de evidencia: enseña la foto y los botones
/// Cámara y Galería. Lo uso en el formulario de registro y en el de pendientes.
class FotoEvidenciaField extends StatefulWidget {
  final String? ruta;
  final ValueChanged<String?> alCambiar;
  final String etiqueta;
  final bool obligatoria;

  const FotoEvidenciaField({
    super.key,
    required this.ruta,
    required this.alCambiar,
    this.etiqueta = 'Foto',
    this.obligatoria = false,
  });

  @override
  State<FotoEvidenciaField> createState() => _FotoEvidenciaFieldState();
}

class _FotoEvidenciaFieldState extends State<FotoEvidenciaField> {
  final MediaService _media = Injector.instance.media;
  bool _cargando = false;

  // Abre la cámara o la galería según el botón que tocó
  Future<void> _elegir(OrigenFoto origen) async {
    setState(() => _cargando = true);
    try {
      final nueva = await _media.obtenerFoto(origen);
      if (nueva != null) {
        // Si ya había otra foto, la borro para no dejar basura en el celular
        await _media.eliminarFoto(widget.ruta);
        // Le aviso al formulario cuál es la nueva foto
        widget.alCambiar(nueva);
      }
    } catch (e) {
      // Si negó el permiso de cámara, por ejemplo, enseño el mensaje
      if (mounted) UiFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _quitar() async {
    await _media.eliminarFoto(widget.ruta);
    widget.alCambiar(null);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.obligatoria ? '${widget.etiqueta} *' : widget.etiqueta,
          style: tema.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        // Cambia con animación entre "sin foto" y la foto
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: widget.ruta == null
              ? Container(
                  key: const ValueKey('vacio'),
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tema.colorScheme.outlineVariant),
                  ),
                  child: Center(
                    child: Text(
                      'Toma una foto o elige una de la galería',
                      style: TextStyle(color: tema.colorScheme.outline),
                    ),
                  ),
                )
              : Stack(
                  key: ValueKey(widget.ruta),
                  children: [
                    FotoArchivo(
                      ruta: widget.ruta,
                      height: 220,
                      width: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        tooltip: 'Quitar foto',
                        onPressed: _quitar,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
        ),
        if (_cargando) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cargando ? null : () => _elegir(OrigenFoto.camara),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cargando ? null : () => _elegir(OrigenFoto.galeria),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
