import '../../core/errors/app_exception.dart';

/// Mixin reutilizable: envuelve cualquier operación de BD en try-catch
/// y convierte el error técnico en un [StorageException] con un mensaje
/// entendible. Así ningún error de SQLite "truena" la app.
mixin ManejoErroresDb {
  Future<T> ejecutarSeguro<T>(
    String mensajeError,
    Future<T> Function() operacion,
  ) async {
    try {
      return await operacion();
    } on AppException {
      rethrow; // Ya viene con un mensaje claro
    } catch (e) {
      throw StorageException(mensajeError, cause: e);
    }
  }
}
