import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../services/speech_service.dart';
import 'ui_feedback.dart';

/// Campo de texto con un botón de micrófono para dictar en vez de escribir.
/// Es StatefulWidget porque cambia: el botón se pone rojo mientras escucha.
class DictadoTextField extends StatefulWidget {
  final TextEditingController controller;
  final String etiqueta;
  final String? hint;
  final int maxLines;

  const DictadoTextField({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.hint,
    this.maxLines = 4,
  });

  @override
  State<DictadoTextField> createState() => _DictadoTextFieldState();
}

class _DictadoTextFieldState extends State<DictadoTextField> {
  // Pido el servicio de voz al Injector
  final SpeechService _voz = Injector.instance.voz;
  // true mientras está grabando (para cambiar el botón)
  bool _escuchando = false;

  /// Lo que ya estaba escrito antes de dictar. Así lo dictado se agrega
  /// al final y no borra lo que ya habías escrito
  String _textoBase = '';

  // Se llama al tocar el micrófono: si está escuchando lo para, si no, empieza
  Future<void> _alternarDictado() async {
    if (_escuchando) {
      await _voz.detener();
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    _textoBase = widget.controller.text.trim();
    // Cuando el micrófono deja de escuchar solo (te quedaste callado), actualizo el botón
    _voz.alCambiarEstado = (escuchando) {
      if (mounted) setState(() => _escuchando = escuchando);
    };

    try {
      // Cada vez que reconoce palabras, pongo el texto en el campo
      await _voz.escuchar((texto, esFinal) {
        final separador = _textoBase.isEmpty ? '' : ' ';
        widget.controller.text = '$_textoBase$separador$texto';
        // Muevo el cursor al final del texto
        widget.controller.selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
      });
      if (mounted) setState(() => _escuchando = true);
    } catch (e) {
      if (mounted) {
        setState(() => _escuchando = false);
        UiFeedback.error(context, e);
      }
    }
  }

  @override
  // Al salir de la pantalla apago el micrófono para que no se quede grabando
  void dispose() {
    if (_escuchando) _voz.detener();
    _voz.alCambiarEstado = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: widget.etiqueta,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(4),
              // AnimatedContainer: el círculo cambia de color suavecito (rojo = grabando)
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _escuchando
                      ? tema.colorScheme.error
                      : tema.colorScheme.primaryContainer,
                ),
                child: IconButton(
                  tooltip: _escuchando ? 'Detener dictado' : 'Dictar',
                  onPressed: _alternarDictado,
                  // AnimatedSwitcher: cambia el ícono de micrófono a "stop" con animación
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _escuchando ? Icons.stop : Icons.mic,
                      key: ValueKey(_escuchando),
                      color: _escuchando
                          ? tema.colorScheme.onError
                          : tema.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Aparece el texto "Escuchando..." solo mientras graba
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _escuchando
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq,
                          size: 18, color: tema.colorScheme.error),
                      const SizedBox(width: 6),
                      const Text('Escuchando… habla ahora'),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
