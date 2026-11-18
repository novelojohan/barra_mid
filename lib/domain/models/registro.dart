import 'dart:convert';

import 'geo_punto.dart';

/// Tipo de movimiento que se anota en la bitácora.
/// [signo] indica si suma (+1) o resta (-1) al inventario.
enum TipoRegistro {
  produccion('produccion', 'Producción / relleno', 1),
  preparados('preparados', 'Preparé mixes', 1),
  salida('salida', 'Uso / salida', -1),
  merma('merma', 'Merma', -1);

  const TipoRegistro(this.clave, this.etiqueta, this.signo);

  final String clave;
  final String etiqueta;
  final int signo;

  static TipoRegistro desdeClave(String clave) => values.firstWhere(
        (t) => t.clave == clave,
        orElse: () => TipoRegistro.produccion,
      );
}

/// Una línea del registro: "2 botes de Plátano".
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

  Map<String, dynamic> toJson() => {
        'insumo_id': insumoId,
        'nombre': nombre,
        'unidad': unidad,
        'cantidad': cantidad,
      };

  factory RegistroItem.fromJson(Map<String, dynamic> json) => RegistroItem(
        insumoId: json['insumo_id'] as int,
        nombre: json['nombre'] as String,
        unidad: json['unidad'] as String,
        cantidad: json['cantidad'] as int,
      );
}

/// Entrada de la bitácora de barra (el "diario" de la app).
/// Equivale a los mensajes que se mandaban por WhatsApp:
/// "Se hicieron 2 botes de plátano" + foto.
class Registro {
  final int? id;
  final TipoRegistro tipo;
  final List<RegistroItem> items;
  final String nota;
  final String? fotoPath;
  final GeoPunto? ubicacion;

  /// true = se registró dentro de la tienda, false = fuera,
  /// null = no se pudo verificar.
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

  /// Ej: "2 Plátano, 1 Piña"
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

  /// Mapa para SQLite. La lista de items se serializa como JSON
  /// en una sola columna (items_json).
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'tipo': tipo.clave,
        'items_json': jsonEncode(items.map((i) => i.toJson()).toList()),
        'nota': nota,
        'foto_path': fotoPath,
        'latitud': ubicacion?.latitud,
        'longitud': ubicacion?.longitud,
        'en_tienda': enTienda == null ? null : (enTienda! ? 1 : 0),
        'empleado': empleado,
        'fecha': fecha.toIso8601String(),
      };

  factory Registro.fromMap(Map<String, Object?> map) {
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
