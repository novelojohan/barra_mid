import '../../core/errors/app_exception.dart';

/// Mixin = un pedazo de código que puedo "pegar" en varias clases.
/// Este envuelve cualquier consulta en un try-catch: si SQLite falla,
/// convierte el error en un StorageException con un mensaje claro.
/// Así ningún error de la base de datos cierra la app.
mixin ManejoErroresDb {
  // T es "cualquier tipo": sirve igual para consultas que regresan una lista,
  // un insumo o nada
  Future<T> ejecutarSeguro<T>(
    String mensajeError,
    Future<T> Function() operacion,
  ) async {
    try {
      // Intento hacer la consulta...
      return await operacion();
    // ...si ya es uno de mis errores, lo dejo pasar tal cual...
    } on AppException {
      rethrow; // Ya viene con un mensaje claro
    // ...y si es otro error, lo convierto en el mío con el mensaje que me pasaron
    } catch (e) {
      throw StorageException(mensajeError, cause: e);
    }
  }
}
