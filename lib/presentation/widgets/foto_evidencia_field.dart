import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../services/media_service.dart';
import 'foto_archivo.dart';
import 'ui_feedback.dart';

/// Campo de formulario para tomar o elegir la foto de evidencia.
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

  Future<void> _elegir(OrigenFoto origen) async {
    setState(() => _cargando = true);
    try {
      final nueva = await _media.obtenerFoto(origen);
      if (nueva != null) {
        // Si ya había una foto sin guardar, se borra para no dejar basura
        await _media.eliminarFoto(widget.ruta);
        widget.alCambiar(nueva);
      }
    } catch (e) {
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
