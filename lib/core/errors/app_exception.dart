/// Mis propios errores.
///
/// Cada paquete (SQLite, GPS, cámara) lanza sus errores raros y en inglés.
/// Yo los atrapo y los convierto en uno de estos, con un mensaje en español
/// que sí entiende el usuario. Así las pantallas solo tienen que mostrar
/// error.message y ya.
abstract class AppException implements Exception {
  // El texto que le enseño al usuario
  final String message;
  // El error original, por si necesito revisarlo
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message ${cause ?? ''}';
}

/// Cuando algo falla con la base de datos (guardar, leer, borrar)
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Cuando el usuario no dio permiso de cámara, micrófono o ubicación
class PermissionDeniedException extends AppException {
  /// true si lo negó "para siempre": ahí ya solo se puede activar
  /// desde Ajustes, por eso enseño un botón que lleva a Ajustes
  final bool permanentlyDenied;

  const PermissionDeniedException(
    super.message, {
    this.permanentlyDenied = false,
    super.cause,
  });
}

/// Cuando el sensor falla: GPS apagado, micrófono ocupado, etc.
class DeviceServiceException extends AppException {
  const DeviceServiceException(super.message, {super.cause});
}
