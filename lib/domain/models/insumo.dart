/// Dónde está guardado el insumo. Es un enum: una lista fija de opciones.
/// Cada opción tiene una clave (lo que guardo en la base) y una etiqueta (lo que ve el usuario)
enum UbicacionInsumo {
  neveraGrande('nevera_grande', 'Nevera grande'),
  neveraChica('nevera_chica', 'Nevera chica'),
  barra('barra', 'Barra / secos');

  const UbicacionInsumo(this.clave, this.etiqueta);

  /// Ej. 'nevera_grande' (así se guarda en SQLite)
  final String clave;

  /// Ej. 'Nevera grande' (así se ve en la pantalla)
  final String etiqueta;

  // Convierte el texto de la base de vuelta a la opción del enum
  static UbicacionInsumo desdeClave(String clave) => values.firstWhere(
        (u) => u.clave == clave,
        orElse: () => UbicacionInsumo.barra,
      );
}

/// Modelo de un insumo: un bote de plátano, una bolsa de hielo,
/// un bote de Green Goodness, etc.
/// Un modelo es solo una clase con los datos, como una "ficha".
class Insumo {
  // id lo pone SQLite solo (por eso es int? = puede ser null antes de guardar)
  final int? id;
  final String nombre;
  final UbicacionInsumo ubicacion;

  /// botes o bolsas
  final String unidad;
  final int cantidad;

  /// Si hay menos que esto, la tarjeta se pone en rojo
  final int minimo;

  const Insumo({
    this.id,
    required this.nombre,
    required this.ubicacion,
    required this.unidad,
    required this.cantidad,
    required this.minimo,
  });

  /// true si ya se está acabando (hay menos del mínimo)
  bool get bajoMinimo => cantidad < minimo;

  // copyWith crea una copia cambiando solo lo que le paso.
  // Los campos son final (no se pueden cambiar), por eso hago copias
  Insumo copyWith({int? id, int? cantidad, int? minimo}) => Insumo(
        id: id ?? this.id,
        nombre: nombre,
        ubicacion: ubicacion,
        unidad: unidad,
        cantidad: cantidad ?? this.cantidad,
        minimo: minimo ?? this.minimo,
      );

  // Convierte el insumo a un Map para guardarlo en SQLite (cada llave = una columna)
  Map<String, Object?> toMap() => {
        // Si todavía no tiene id no lo mando, SQLite lo genera
        if (id != null) 'id': id,
        'nombre': nombre,
        'ubicacion': ubicacion.clave,
        'unidad': unidad,
        'cantidad': cantidad,
        'minimo': minimo,
      };

  // Lo contrario: de una fila de SQLite armo el objeto Insumo
  factory Insumo.fromMap(Map<String, Object?> map) => Insumo(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        ubicacion: UbicacionInsumo.desdeClave(map['ubicacion'] as String),
        unidad: map['unidad'] as String,
        cantidad: map['cantidad'] as int,
        minimo: map['minimo'] as int,
      );
}
