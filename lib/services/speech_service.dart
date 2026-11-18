import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/errors/app_exception.dart';

/// Contrato de dictado por voz.
abstract class SpeechService {
  bool get escuchando;

  /// Se llama cuando el micrófono empieza o deja de escuchar.
  set alCambiarEstado(void Function(bool escuchando)? callback);

  Future<void> escuchar(void Function(String texto, bool esFinal) alResultado);
  Future<void> detener();
}

/// Captura audio del micrófono y lo convierte a texto con el motor
/// de reconocimiento del sistema (Google en Android, Apple en iOS).
class SpeechToTextService implements SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _inicializado = false;
  String? _idiomaEspanol;
  void Function(bool escuchando)? _alCambiarEstado;

  @override
  bool get escuchando => _speech.isListening;

  @override
  set alCambiarEstado(void Function(bool escuchando)? callback) =>
      _alCambiarEstado = callback;

  Future<void> _inicializar() async {
    if (_inicializado) return;
    try {
      _inicializado = await _speech.initialize(
        onStatus: (estado) =>
            _alCambiarEstado?.call(estado == 'listening'),
        onError: (SpeechRecognitionError error) =>
            _alCambiarEstado?.call(false),
      );
    } catch (e) {
      throw DeviceServiceException('El dictado no está disponible', cause: e);
    }

    if (!_inicializado) {
      final tienePermiso = await _speech.hasPermission;
      if (!tienePermiso) {
        throw const PermissionDeniedException(
          'Sin permiso de micrófono no se puede dictar. Puedes escribir la nota.',
          permanentlyDenied: true,
        );
      }
      throw const DeviceServiceException(
        'Este celular no tiene reconocimiento de voz disponible.',
      );
    }
    _idiomaEspanol = await _buscarEspanol();
  }

  /// Busca español de México y si no existe cualquier español.
  Future<String?> _buscarEspanol() async {
    try {
      final idiomas = await _speech.locales();
      final ids = idiomas.map((l) => l.localeId).toList();
      for (final preferido in ['es_MX', 'es-MX']) {
        if (ids.contains(preferido)) return preferido;
      }
      for (final id in ids) {
        if (id.toLowerCase().startsWith('es')) return id;
      }
    } catch (_) {
      // Si falla usamos el idioma del sistema
    }
    return null;
  }

  @override
  Future<void> escuchar(
    void Function(String texto, bool esFinal) alResultado,
  ) async {
    await _inicializar();
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) =>
            alResultado(r.recognizedWords, r.finalResult),
        localeId: _idiomaEspanol,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      throw DeviceServiceException('No se pudo usar el micrófono', cause: e);
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }
}
