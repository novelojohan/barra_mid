// Contratos (interfaces) de acceso a datos.
//
// La capa de presentación SOLO conoce estas abstracciones, no SQLite.
// Así se cumple el principio de Inversión de Dependencias (la "D" de SOLID):
// si mañana cambiamos SQLite por Firebase, las pantallas no se tocan.

import '../models/geo_punto.dart';
import '../models/insumo.dart';
import '../models/pendiente.dart';
import '../models/registro.dart';

abstract class InventarioRepository {
  Future<List<Insumo>> obtenerInsumos();
  Future<Insumo> agregarInsumo(Insumo insumo);

  /// Ajuste por conteo físico: deja la cantidad exacta que se contó.
  Future<void> actualizarCantidad(int insumoId, int cantidad);
}

abstract class RegistroRepository {
  Future<List<Registro>> obtenerRegistros();

  /// Guarda el registro y actualiza el inventario en la misma transacción.
  Future<Registro> guardarRegistro(Registro registro);

  /// Borra el registro y revierte su efecto en el inventario.
  Future<void> eliminarRegistro(Registro registro);
}

abstract class PendienteRepository {
  Future<List<Pendiente>> obtenerPendientes();
  Future<Pendiente> crearPendiente(Pendiente pendiente);
  Future<void> marcarComoHecho(Pendiente pendienteCompletado);
  Future<void> eliminarPendiente(int id);
}

abstract class ConfigRepository {
  Future<String?> obtenerUltimoEmpleado();
  Future<void> guardarUltimoEmpleado(String nombre);
  Future<GeoPunto?> obtenerUbicacionTienda();
  Future<void> guardarUbicacionTienda(GeoPunto punto);
}
