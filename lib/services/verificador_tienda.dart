import '../domain/models/geo_punto.dart';
import '../domain/repositories/repositorios.dart';
import 'location_service.dart';

/// Resultado de capturar la ubicación al guardar.
class CapturaUbicacion {
  final GeoPunto punto;

  /// true = dentro de la tienda, false = fuera, null = tienda no configurada.
  final bool? enTienda;

  const CapturaUbicacion(this.punto, this.enTienda);
}

/// Toma el GPS actual y revisa si está dentro del radio de la tienda.
/// Sirve para comprobar que la evidencia se tomó en Mid Market.
class VerificadorTienda {
  static const double radioMetros = 150;

  final LocationService _ubicacion;
  final ConfigRepository _config;

  VerificadorTienda(this._ubicacion, this._config);

  Future<CapturaUbicacion> capturar() async {
    final punto = await _ubicacion.obtenerUbicacionActual();
    final tienda = await _config.obtenerUbicacionTienda();
    if (tienda == null) return CapturaUbicacion(punto, null);
    final distancia = _ubicacion.distanciaEnMetros(punto, tienda);
    return CapturaUbicacion(punto, distancia <= radioMetros);
  }
}
