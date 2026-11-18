/// Coordenadas GPS guardadas junto a un registro o una evidencia.
class GeoPunto {
  final double latitud;
  final double longitud;

  /// Precisión reportada por el GPS en metros (puede ser null).
  final double? precision;

  const GeoPunto(this.latitud, this.longitud, {this.precision});

  Map<String, dynamic> toJson() => {
        'latitud': latitud,
        'longitud': longitud,
        'precision': precision,
      };

  factory GeoPunto.fromJson(Map<String, dynamic> json) => GeoPunto(
        (json['latitud'] as num).toDouble(),
        (json['longitud'] as num).toDouble(),
        precision: (json['precision'] as num?)?.toDouble(),
      );

  /// Crea el punto a partir de columnas de la BD; si no hay datos regresa null.
  static GeoPunto? desdeColumnas(Object? lat, Object? lng) {
    if (lat == null || lng == null) return null;
    return GeoPunto((lat as num).toDouble(), (lng as num).toDouble());
  }

  String get texto =>
      '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';
}
