import 'dart:convert';

import 'geo_punto.dart';

/// Los tipos de movimiento que se pueden registrar en la bitácora.
/// signo dice si suma (+1) o resta (-1) al inventario:
/// producción y mixes suman botes, salida y merma los restan.
enum TipoRegistro {
  produccion('produccion', 'Producción / relleno', 1),
  preparados('preparados', 'Preparé mixes', 1),
  salida('salida', 'Uso / salida', -1),
  merma('merma', 'Merma', -1);

  const TipoRegistro(this.clave, this.etiqueta, this.signo);

  final String clave;
  final String etiqueta;
  final int signo;

  // Convierte el texto guardado en la base al tipo del enum
  static TipoRegistro desdeClave(String clave) => values.firstWhere(
        (t) => t.clave == clave,
        orElse: () => TipoRegistro.produccion,
      );
}

/// Una línea del registro, ej. "2 botes de Plátano".
/// Un registro puede tener varias líneas (ej. avena, cocoa y dátiles juntos)
class RegistroItem {
  final int insumoId;
  final String nombre;
  final String unidad;
  final int cantidad;

  const RegistroItem({
    required this.insumoId,
    required this.nombre,
    required this.unidad,
    required this.cantidad,
  });

  // Convierte la línea a JSON para guardarla en la base
  Map<String, dynamic> toJson() => {
        'insumo_id': insumoId,
        'nombre': nombre,
        'unidad': unidad,
        'cantidad': cantidad,
      };

  // Y de JSON de regreso al objeto
  factory RegistroItem.fromJson(Map<String, dynamic> json) => RegistroItem(
        insumoId: json['insumo_id'] as int,
        nombre: json['nombre'] as String,
        unidad: json['unidad'] as String,
        cantidad: json['cantidad'] as int,
      );
}

/// Un registro de la bitácora (el "diario" de la app).
/// Es lo mismo que antes se mandaba por WhatsApp:
/// "Se hicieron 2 botes de plátano" + la foto. Pero aquí además se
/// guarda quién, cuándo, dónde y se actualiza el inventario.
class Registro {
  final int? id;
  final TipoRegistro tipo;
  final List<RegistroItem> items;
  final String nota;
  final String? fotoPath;
  final GeoPunto? ubicacion;

  /// true = se hizo dentro de la tienda, false = fuera,
  /// null = no se pudo saber (no había GPS o no se configuró la tienda)
  final bool? enTienda;
  final String empleado;
  final DateTime fecha;

  const Registro({
    this.id,
    required this.tipo,
    required this.items,
    required this.nota,
    required this.empleado,
    required this.fecha,
    this.fotoPath,
    this.ubicacion,
    this.enTienda,
  });

  /// Resumen para la lista. Ej: "2 Plátano, 1 Piña"
  String get resumen =>
      items.map((i) => '${i.cantidad} ${i.nombre}').join(', ');

  Registro copyWith({int? id}) => Registro(
        id: id ?? this.id,
        tipo: tipo,
        items: items,
        nota: nota,
        empleado: empleado,
        fecha: fecha,
        fotoPath: fotoPath,
        ubicacion: ubicacion,
        enTienda: enTienda,
      );

  /// Convierte el registro a Map para guardarlo en SQLite.
  /// SQLite no puede guardar una lista directo, por eso la lista de items
  /// la convierto a JSON (un texto) y la guardo en una sola columna: items_json
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'tipo': tipo.clave,
        'items_json': jsonEncode(items.map((i) => i.toJson()).toList()),
        'nota': nota,
        'foto_path': fotoPath,
        'latitud': ubicacion?.latitud,
        'longitud': ubicacion?.longitud,
        // SQLite no tiene true/false, así que guardo 1 o 0
        'en_tienda': enTienda == null ? null : (enTienda! ? 1 : 0),
        'empleado': empleado,
        // La fecha se guarda como texto, ej. 2026-11-17T08:20:00
        'fecha': fecha.toIso8601String(),
      };

  // Lo contrario: de la fila de SQLite armo el Registro
  factory Registro.fromMap(Map<String, Object?> map) {
    // jsonDecode convierte el texto JSON otra vez en una lista
    final itemsJson = jsonDecode(map['items_json'] as String) as List<dynamic>;
    final enTiendaDb = map['en_tienda'] as int?;
    return Registro(
      id: map['id'] as int?,
      tipo: TipoRegistro.desdeClave(map['tipo'] as String),
      items: itemsJson
          .map((e) => RegistroItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nota: (map['nota'] as String?) ?? '',
      fotoPath: map['foto_path'] as String?,
      ubicacion: GeoPunto.desdeColumnas(map['latitud'], map['longitud']),
      enTienda: enTiendaDb == null ? null : enTiendaDb == 1,
      empleado: map['empleado'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }
}
