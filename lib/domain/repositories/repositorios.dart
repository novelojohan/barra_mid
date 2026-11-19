// Interfaces de los repositorios (los "contratos").
//
// Una interfaz solo dice QUÉ se puede hacer (guardar, leer, borrar) pero no CÓMO.
// El CÓMO está en data/repositories/sqlite_repositorios.dart.
// Las pantallas solo conocen estas interfaces, nunca SQLite directo.
// Esto es la inversión de dependencias (la D de SOLID): si cambio SQLite
// por otra base de datos, las pantallas no se tocan.

import '../models/geo_punto.dart';
import '../models/insumo.dart';
import '../models/pendiente.dart';
import '../models/registro.dart';

// Todo lo del inventario (los insumos de las neveras)
abstract class InventarioRepository {
  // Future = la respuesta llega después (leer la base tarda un poquito)
  Future<List<Insumo>> obtenerInsumos();
  Future<Insumo> agregarInsumo(Insumo insumo);

  /// Cuando alguien cuenta los botes y pone el número exacto
  Future<void> actualizarCantidad(int insumoId, int cantidad);

  /// Cambiar el mínimo de un insumo (solo lo hace el admin)
  Future<void> actualizarMinimo(int insumoId, int minimo);
}

// Todo lo de la bitácora (los registros de producción, salida, etc.)
abstract class RegistroRepository {
  Future<List<Registro>> obtenerRegistros();

  /// Guarda el registro Y suma/resta las cantidades del inventario al mismo tiempo
  Future<Registro> guardarRegistro(Registro registro);

  /// Borra el registro y deshace lo que había sumado o restado al inventario
  Future<void> eliminarRegistro(Registro registro);
}

// Todo lo de los pendientes (limpiezas, rotación, etc.)
abstract class PendienteRepository {
  Future<List<Pendiente>> obtenerPendientes();
  Future<Pendiente> crearPendiente(Pendiente pendiente);
  Future<void> marcarComoHecho(Pendiente pendienteCompletado);
  Future<void> eliminarPendiente(int id);
}

// Configuraciones sueltas: último empleado, ubicación de la tienda y PIN
abstract class ConfigRepository {
  Future<String?> obtenerUltimoEmpleado();
  Future<void> guardarUltimoEmpleado(String nombre);
  Future<GeoPunto?> obtenerUbicacionTienda();
  Future<void> guardarUbicacionTienda(GeoPunto punto);

  /// El PIN del admin. Regresa null si todavía nadie lo ha creado
  Future<String?> obtenerPinAdmin();
  Future<void> guardarPinAdmin(String pin);
}
