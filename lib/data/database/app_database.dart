import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';

/// Esta clase abre la base de datos SQLite y crea las tablas la primera vez.
/// Solo hace eso (una sola responsabilidad). Las consultas (guardar, leer)
/// están en los repositorios.
class AppDatabase {
  // El archivo de la base se guarda dentro del celular, en la carpeta de la app
  static const _nombreArchivo = 'barra_mid.db';
  static const _version = 2; // La subí a 2 cuando agregué el Oreo

  // Aquí guardo la conexión para no abrir la base cada vez
  Future<Database>? _db;

  /// Si ya está abierta la reutilizo, si no, la abro.
  /// ??= significa "asígnale esto solo si está vacío" 
  Future<Database> get database => _db ??= _abrir();

  Future<Database> _abrir() async {
    try {
      // Le pregunto al celular en qué carpeta guarda las bases de datos
      final carpeta = await getDatabasesPath();
      return await openDatabase(
        p.join(carpeta, _nombreArchivo),
        version: _version,
        // onCreate se ejecuta solo la primera vez que se instala la app
        onCreate: _crearTablas,
        // onUpgrade se ejecuta si la app ya estaba instalada con una versión vieja
        onUpgrade: _actualizar,
      );
    } catch (e) {
      _db = null; // Lo limpio para que se pueda volver a intentar
      // Mando mi propio error con un mensaje en español
      throw StorageException('No se pudo abrir la base de datos', cause: e);
    }
  }

  // Aquí creo las 4 tablas. Uso un batch (un paquete de instrucciones)
  // para mandarlas todas juntas, es más rápido
  Future<void> _crearTablas(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      // Tabla de insumos: lo que hay en cada nevera
      CREATE TABLE insumos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        ubicacion TEXT NOT NULL,
        unidad TEXT NOT NULL,
        cantidad INTEGER NOT NULL DEFAULT 0,
        minimo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    batch.execute('''
      // Tabla de la bitácora. items_json guarda la lista de insumos como texto JSON
      CREATE TABLE registros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        items_json TEXT NOT NULL,
        nota TEXT,
        foto_path TEXT,
        latitud REAL,
        longitud REAL,
        en_tienda INTEGER,
        empleado TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');

    batch.execute('''
      // Tabla de pendientes. Las columnas de evidencia se llenan al completarlo
      CREATE TABLE pendientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        area TEXT NOT NULL,
        creado_por TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        fecha_completado TEXT,
        completado_por TEXT,
        evidencia_path TEXT,
        nota_evidencia TEXT,
        latitud REAL,
        longitud REAL,
        en_tienda INTEGER
      )
    ''');

    batch.execute('''
      // Tabla de configuración: pares clave-valor (último empleado, tienda, PIN)
      CREATE TABLE config(
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    _insertarDatosIniciales(batch);
    await batch.commit(noResult: true);
  }

  /// Migración: si alguien ya tenía la app instalada (versión 1), aquí le
  /// agrego el Oreo SIN borrar lo que ya tenía guardado
  Future<void> _actualizar(Database db, int anterior, int nueva) async {
    if (anterior < 2) {
      final existe = await db.query('insumos',
          where: 'nombre = ?', whereArgs: ['Oreo'], limit: 1);
      if (existe.isEmpty) {
        await db.insert('insumos', {
          'nombre': 'Oreo',
          'ubicacion': 'barra',
          'unidad': 'botes',
          'cantidad': 1,
          'minimo': 1,
        });
      }
    }
  }

  /// Datos iniciales: los insumos y pendientes reales de la barra,
  /// para que la app no empiece vacía
  void _insertarDatosIniciales(Batch batch) {
    const insumos = [
      // Nevera grande: producción
      ['Plátano', 'nevera_grande', 'botes', 5, 3],
      ['Manzana', 'nevera_grande', 'botes', 4, 2],
      ['Piña', 'nevera_grande', 'botes', 5, 2],
      ['Espinaca', 'nevera_grande', 'botes', 3, 2],
      ['Frutos rojos', 'nevera_grande', 'bolsas', 2, 2],
      ['Blueberries', 'nevera_grande', 'bolsas', 2, 2],
      ['Helado', 'nevera_grande', 'botes', 3, 2],
      ['Hielo', 'nevera_grande', 'bolsas', 2, 2],
      // Nevera chica: preparados de medio litro listos para servir
      ['Green Goodness', 'nevera_chica', 'botes', 4, 3],
      ['Blondish', 'nevera_chica', 'botes', 4, 3],
      ['Skinny Beet and Berries', 'nevera_chica', 'bolsas', 3, 3],
      // Barra: secos
      ['Avena', 'barra', 'botes', 1, 1],
      ['Cocoa', 'barra', 'botes', 1, 1],
      ['Choco Abuelita', 'barra', 'botes', 1, 1],
      ['Dátiles', 'barra', 'botes', 1, 1],
      ['Oreo', 'barra', 'botes', 1, 1],
    ];

    // Recorro la lista y meto cada insumo a la tabla
    for (final i in insumos) {
      batch.insert('insumos', {
        'nombre': i[0],
        'ubicacion': i[1],
        'unidad': i[2],
        'cantidad': i[3],
        'minimo': i[4],
      });
    }

    final ahora = DateTime.now().toIso8601String();
    const pendientes = [
      ['Limpieza de la Breville', 'Breville', 'Limpiar grupo, portafiltros y vaporizador.'],
      ['Limpieza de la Franke', 'Franke', 'Ciclo de limpieza y limpiar charola.'],
      ['Rotación de producción', 'Nevera grande', 'Dejar el producto antiguo encima del nuevo.'],
      ['Limpieza de nevera chica', 'Nevera chica', 'Sacar botes, limpiar repisas y acomodar por fecha.'],
    ];

    for (final pe in pendientes) {
      batch.insert('pendientes', {
        'titulo': pe[0],
        'area': pe[1],
        'descripcion': pe[2],
        'creado_por': 'Sistema',
        'fecha_creacion': ahora,
      });
    }
  }
}
