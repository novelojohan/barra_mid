import '../../domain/models/geo_punto.dart';
import '../../domain/models/insumo.dart';
import '../../domain/models/pendiente.dart';
import '../../domain/models/registro.dart';
import '../../domain/repositories/repositorios.dart';
import '../database/app_database.dart';
import 'manejo_errores_db.dart';

/// Implementaciones con SQLite de los contratos del dominio.

class SqliteInventarioRepository
    with ManejoErroresDb
    implements InventarioRepository {
  final AppDatabase _appDb;
  SqliteInventarioRepository(this._appDb);

  @override
  Future<List<Insumo>> obtenerInsumos() =>
      ejecutarSeguro('No se pudo cargar el inventario', () async {
        final db = await _appDb.database;
        final filas = await db.query('insumos', orderBy: 'id ASC');
        return filas.map(Insumo.fromMap).toList();
      });

  @override
  Future<Insumo> agregarInsumo(Insumo insumo) =>
      ejecutarSeguro('No se pudo agregar el insumo', () async {
        final db = await _appDb.database;
        final id = await db.insert('insumos', insumo.toMap());
        return insumo.copyWith(id: id);
      });

  @override
  Future<void> actualizarCantidad(int insumoId, int cantidad) =>
      ejecutarSeguro('No se pudo actualizar la cantidad', () async {
        final db = await _appDb.database;
        await db.update(
          'insumos',
          {'cantidad': cantidad < 0 ? 0 : cantidad},
          where: 'id = ?',
          whereArgs: [insumoId],
        );
      });
}

class SqliteRegistroRepository
    with ManejoErroresDb
    implements RegistroRepository {
  final AppDatabase _appDb;
  SqliteRegistroRepository(this._appDb);

  @override
  Future<List<Registro>> obtenerRegistros() =>
      ejecutarSeguro('No se pudo cargar la bitácora', () async {
        final db = await _appDb.database;
        final filas = await db.query('registros', orderBy: 'fecha DESC');
        return filas.map(Registro.fromMap).toList();
      });

  @override
  Future<Registro> guardarRegistro(Registro registro) =>
      ejecutarSeguro('No se pudo guardar el registro', () async {
        final db = await _appDb.database;
        // Transacción: o se guarda todo (registro + inventario) o nada.
        return db.transaction((txn) async {
          final id = await txn.insert('registros', registro.toMap());
          for (final item in registro.items) {
            await txn.rawUpdate(
              'UPDATE insumos SET cantidad = MAX(0, cantidad + ?) WHERE id = ?',
              [item.cantidad * registro.tipo.signo, item.insumoId],
            );
          }
          return registro.copyWith(id: id);
        });
      });

  @override
  Future<void> eliminarRegistro(Registro registro) =>
      ejecutarSeguro('No se pudo eliminar el registro', () async {
        final db = await _appDb.database;
        await db.transaction((txn) async {
          await txn.delete('registros', where: 'id = ?', whereArgs: [registro.id]);
          // Se revierte el efecto en el inventario (signo contrario)
          for (final item in registro.items) {
            await txn.rawUpdate(
              'UPDATE insumos SET cantidad = MAX(0, cantidad - ?) WHERE id = ?',
              [item.cantidad * registro.tipo.signo, item.insumoId],
            );
          }
        });
      });
}

class SqlitePendienteRepository
    with ManejoErroresDb
    implements PendienteRepository {
  final AppDatabase _appDb;
  SqlitePendienteRepository(this._appDb);

  @override
  Future<List<Pendiente>> obtenerPendientes() =>
      ejecutarSeguro('No se pudieron cargar los pendientes', () async {
        final db = await _appDb.database;
        final filas = await db.query(
          'pendientes',
          orderBy: 'fecha_completado DESC, fecha_creacion DESC',
        );
        return filas.map(Pendiente.fromMap).toList();
      });

  @override
  Future<Pendiente> crearPendiente(Pendiente pendiente) =>
      ejecutarSeguro('No se pudo crear el pendiente', () async {
        final db = await _appDb.database;
        final id = await db.insert('pendientes', pendiente.toMap());
        return pendiente.copyWith(id: id);
      });

  @override
  Future<void> marcarComoHecho(Pendiente pendienteCompletado) =>
      ejecutarSeguro('No se pudo guardar la evidencia', () async {
        final db = await _appDb.database;
        await db.update(
          'pendientes',
          pendienteCompletado.toMap(),
          where: 'id = ?',
          whereArgs: [pendienteCompletado.id],
        );
      });

  @override
  Future<void> eliminarPendiente(int id) =>
      ejecutarSeguro('No se pudo eliminar el pendiente', () async {
        final db = await _appDb.database;
        await db.delete('pendientes', where: 'id = ?', whereArgs: [id]);
      });
}

class SqliteConfigRepository
    with ManejoErroresDb
    implements ConfigRepository {
  final AppDatabase _appDb;
  SqliteConfigRepository(this._appDb);

  static const _empleado = 'ultimo_empleado';
  static const _tiendaLat = 'tienda_lat';
  static const _tiendaLng = 'tienda_lng';
  static const _pinAdmin = 'pin_admin';

  Future<String?> _leer(String clave) async {
    final db = await _appDb.database;
    final filas = await db.query(
      'config',
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );
    return filas.isEmpty ? null : filas.first['valor'] as String;
  }

  Future<void> _guardar(String clave, String valor) async {
    final db = await _appDb.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO config(clave, valor) VALUES(?, ?)',
      [clave, valor],
    );
  }

  @override
  Future<String?> obtenerUltimoEmpleado() =>
      ejecutarSeguro('No se pudo leer la configuración', () => _leer(_empleado));

  @override
  Future<void> guardarUltimoEmpleado(String nombre) => ejecutarSeguro(
      'No se pudo guardar la configuración', () => _guardar(_empleado, nombre));

  @override
  Future<GeoPunto?> obtenerUbicacionTienda() =>
      ejecutarSeguro('No se pudo leer la ubicación de la tienda', () async {
        final lat = await _leer(_tiendaLat);
        final lng = await _leer(_tiendaLng);
        if (lat == null || lng == null) return null;
        return GeoPunto(double.parse(lat), double.parse(lng));
      });

  @override
  Future<void> guardarUbicacionTienda(GeoPunto punto) =>
      ejecutarSeguro('No se pudo guardar la ubicación de la tienda', () async {
        await _guardar(_tiendaLat, punto.latitud.toString());
        await _guardar(_tiendaLng, punto.longitud.toString());
      });

  @override
  Future<String?> obtenerPinAdmin() =>
      ejecutarSeguro('No se pudo leer el PIN', () => _leer(_pinAdmin));

  @override
  Future<void> guardarPinAdmin(String pin) =>
      ejecutarSeguro('No se pudo guardar el PIN', () => _guardar(_pinAdmin, pin));
}
