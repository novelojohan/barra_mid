/// Un punto del mapa: latitud y longitud que saca el GPS
class GeoPunto {
  final double latitud;
  final double longitud;

  /// Qué tan exacto fue el GPS, en metros (ej. ±10 m)
  final double? precision;

  const GeoPunto(this.latitud, this.longitud, {this.precision});

  // Para convertirlo a JSON (texto) y de regreso
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

  /// Arma el punto con las columnas latitud y longitud de la base.
  /// Si alguna viene vacía (se guardó sin GPS) regresa null
  static GeoPunto? desdeColumnas(Object? lat, Object? lng) {
    if (lat == null || lng == null) return null;
    return GeoPunto((lat as num).toDouble(), (lng as num).toDouble());
  }

  // Las coordenadas como texto con 5 decimales para enseñarlas en pantalla
  String get texto =>
      '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';
}
