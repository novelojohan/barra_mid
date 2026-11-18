/// Lugar físico donde se guarda un insumo dentro de la barra.
enum UbicacionInsumo {
  neveraGrande('nevera_grande', 'Nevera grande'),
  neveraChica('nevera_chica', 'Nevera chica'),
  barra('barra', 'Barra / secos');

  const UbicacionInsumo(this.clave, this.etiqueta);

  /// Valor que se guarda en SQLite.
  final String clave;

  /// Texto que ve el usuario.
  final String etiqueta;

  static UbicacionInsumo desdeClave(String clave) => values.firstWhere(
        (u) => u.clave == clave,
        orElse: () => UbicacionInsumo.barra,
      );
}

/// Un insumo del inventario: bote de plátano, bolsa de hielo,
/// bote preparado de Green Goodness, etc.
class Insumo {
  final int? id;
  final String nombre;
  final UbicacionInsumo ubicacion;

  /// "botes" o "bolsas".
  final String unidad;
  final int cantidad;

  /// Si la cantidad baja de este número se marca en rojo.
  final int minimo;

  const Insumo({
    this.id,
    required this.nombre,
    required this.ubicacion,
    required this.unidad,
    required this.cantidad,
    required this.minimo,
  });

  /// true cuando hay que avisar que ya se está acabando.
  bool get bajoMinimo => cantidad < minimo;

  Insumo copyWith({int? id, int? cantidad, int? minimo}) => Insumo(
        id: id ?? this.id,
        nombre: nombre,
        ubicacion: ubicacion,
        unidad: unidad,
        cantidad: cantidad ?? this.cantidad,
        minimo: minimo ?? this.minimo,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'ubicacion': ubicacion.clave,
        'unidad': unidad,
        'cantidad': cantidad,
        'minimo': minimo,
      };

  factory Insumo.fromMap(Map<String, Object?> map) => Insumo(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        ubicacion: UbicacionInsumo.desdeClave(map['ubicacion'] as String),
        unidad: map['unidad'] as String,
        cantidad: map['cantidad'] as int,
        minimo: map['minimo'] as int,
      );
}
