import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/errors/app_exception.dart';

/// Interfaz del dictado por voz (micrófono -> texto)
abstract class SpeechService {
  // true mientras el micrófono está grabando
  bool get escuchando;

  /// Una función que me avisa cuando el micrófono empieza o deja de escuchar
  /// (la uso para cambiar el color del botón)
  set alCambiarEstado(void Function(bool escuchando)? callback);

  // Empieza a escuchar. Cada vez que reconoce palabras llama a alResultado
  Future<void> escuchar(void Function(String texto, bool esFinal) alResultado);
  // Para de escuchar
  Future<void> detener();
}

/// Dictado con el paquete speech_to_text.
/// Graba con el micrófono y usa el reconocedor de voz del propio celular
/// (el de Google en Android y el de Apple en iPhone) para pasarlo a texto.
class SpeechToTextService implements SpeechService {
  final SpeechToText _speech = SpeechToText();
  // El micrófono se prepara una sola vez, aquí guardo si ya se hizo
  bool _inicializado = false;
  String? _idiomaEspanol;
  void Function(bool escuchando)? _alCambiarEstado;

  @override
  bool get escuchando => _speech.isListening;

  @override
  set alCambiarEstado(void Function(bool escuchando)? callback) =>
      _alCambiarEstado = callback;

  // Prepara el micrófono (la primera vez pide el permiso al usuario)
  Future<void> _inicializar() async {
    if (_inicializado) return;
    try {
      _inicializado = await _speech.initialize(
        // Me avisa cuando cambia el estado: 'listening' = está escuchando
        onStatus: (estado) =>
            _alCambiarEstado?.call(estado == 'listening'),
        onError: (SpeechRecognitionError error) =>
            _alCambiarEstado?.call(false),
      );
    } catch (e) {
      throw DeviceServiceException('El dictado no está disponible', cause: e);
    }

    // Si no se pudo preparar, reviso por qué: o no hay permiso
    // o el celular no tiene reconocimiento de voz
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

  /// Busca el idioma español de México; si no está, cualquier español
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
      // Si falla, se queda el idioma que tenga el celular
    }
    return null;
  }

  @override
  Future<void> escuchar(
    void Function(String texto, bool esFinal) alResultado,
  ) async {
    await _inicializar();
    try {
      // Empieza a escuchar:
      // - onResult se llama con el texto mientras hablas (finalResult = ya terminó la frase)
      // - listenFor: máximo 1 minuto
      // - pauseFor: si te quedas callado 4 segundos, se detiene solo
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
