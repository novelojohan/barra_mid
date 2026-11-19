import 'geo_punto.dart';

/// Las áreas que se pueden escoger al crear un pendiente
const List<String> areasBarra = [
  'Breville',
  'Franke',
  'Nevera grande',
  'Nevera chica',
  'Barra',
  'Otro',
];

/// Un pendiente de la barra (limpiar la Breville, rotar producción, etc.).
/// Solo se marca como hecho subiendo una foto de evidencia.
class Pendiente {
  final int? id;
  final String titulo;
  final String descripcion;
  final String area;
  final String creadoPor;
  final DateTime fechaCreacion;

  // Estos datos se llenan hasta que alguien termina el pendiente.
  // Mientras no esté hecho, valen null
  final DateTime? fechaCompletado;
  final String? completadoPor;
  final String? evidenciaPath;
  final String? notaEvidencia;
  final GeoPunto? ubicacion;
  final bool? enTienda;

  const Pendiente({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.area,
    required this.creadoPor,
    required this.fechaCreacion,
    this.fechaCompletado,
    this.completadoPor,
    this.evidenciaPath,
    this.notaEvidencia,
    this.ubicacion,
    this.enTienda,
  });

  // Si ya tiene fecha de completado, quiere decir que ya se hizo
  bool get hecho => fechaCompletado != null;

  /// Regresa una copia del pendiente pero ya terminado, con la foto,
  /// quién lo hizo, la nota y la ubicación
  Pendiente completar({
    required String empleado,
    required String evidenciaPath,
    required String nota,
    GeoPunto? ubicacion,
    bool? enTienda,
  }) =>
      Pendiente(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        area: area,
        creadoPor: creadoPor,
        fechaCreacion: fechaCreacion,
        fechaCompletado: DateTime.now(),
        completadoPor: empleado,
        evidenciaPath: evidenciaPath,
        notaEvidencia: nota,
        ubicacion: ubicacion,
        enTienda: enTienda,
      );

  Pendiente copyWith({int? id}) => Pendiente(
        id: id ?? this.id,
        titulo: titulo,
        descripcion: descripcion,
        area: area,
        creadoPor: creadoPor,
        fechaCreacion: fechaCreacion,
        fechaCompletado: fechaCompletado,
        completadoPor: completadoPor,
        evidenciaPath: evidenciaPath,
        notaEvidencia: notaEvidencia,
        ubicacion: ubicacion,
        enTienda: enTienda,
      );

  // Para guardarlo en SQLite (cada llave es una columna)
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'area': area,
        'creado_por': creadoPor,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'fecha_completado': fechaCompletado?.toIso8601String(),
        'completado_por': completadoPor,
        'evidencia_path': evidenciaPath,
        'nota_evidencia': notaEvidencia,
        'latitud': ubicacion?.latitud,
        'longitud': ubicacion?.longitud,
        'en_tienda': enTienda == null ? null : (enTienda! ? 1 : 0),
      };

  // De una fila de SQLite al objeto Pendiente
  factory Pendiente.fromMap(Map<String, Object?> map) {
    final completado = map['fecha_completado'] as String?;
    final enTiendaDb = map['en_tienda'] as int?;
    return Pendiente(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      descripcion: (map['descripcion'] as String?) ?? '',
      area: map['area'] as String,
      creadoPor: map['creado_por'] as String,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      fechaCompletado: completado == null ? null : DateTime.parse(completado),
      completadoPor: map['completado_por'] as String?,
      evidenciaPath: map['evidencia_path'] as String?,
      notaEvidencia: map['nota_evidencia'] as String?,
      ubicacion: GeoPunto.desdeColumnas(map['latitud'], map['longitud']),
      enTienda: enTiendaDb == null ? null : enTiendaDb == 1,
    );
  }
}
