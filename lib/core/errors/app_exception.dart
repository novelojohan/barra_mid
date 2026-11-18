/// Excepciones propias de la app.
///
/// Tener nuestras propias excepciones permite que la capa de presentación
/// muestre mensajes claros al usuario sin depender de los errores internos
/// de cada paquete (sqflite, geolocator, image_picker, etc.).
abstract class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message ${cause ?? ''}';
}

/// Error al leer o escribir en la base de datos local (SQLite).
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// El usuario negó un permiso (cámara, micrófono, ubicación).
class PermissionDeniedException extends AppException {
  /// true cuando el permiso se negó "para siempre" y solo se puede
  /// activar desde los ajustes del sistema.
  final bool permanentlyDenied;

  const PermissionDeniedException(
    super.message, {
    this.permanentlyDenied = false,
    super.cause,
  });
}

/// Error con algún sensor o servicio del dispositivo (GPS apagado,
/// micrófono no disponible, cámara ocupada, etc.).
class DeviceServiceException extends AppException {
  const DeviceServiceException(super.message, {super.cause});
}
