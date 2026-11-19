import '../domain/models/geo_punto.dart';
import '../domain/repositories/repositorios.dart';
import 'location_service.dart';

/// Lo que regresa al tomar la ubicación: el punto y si estaba en la tienda
class CapturaUbicacion {
  final GeoPunto punto;

  /// true = dentro de la tienda, false = fuera, null = la tienda no está configurada
  final bool? enTienda;

  const CapturaUbicacion(this.punto, this.enTienda);
}

/// Revisa si estás dentro de la tienda.
/// Toma tu GPS, lo compara con la ubicación guardada de Mid Market y si
/// estás a menos de 150 metros dice que sí. Sirve para comprobar que la
/// foto de evidencia se tomó en el trabajo y no en otro lado.
class VerificadorTienda {
  // El radio en metros que cuenta como "dentro de la tienda"
  static const double radioMetros = 150;

  final LocationService _ubicacion;
  final ConfigRepository _config;

  // Recibe el GPS y la config desde el Injector (no los crea él)
  VerificadorTienda(this._ubicacion, this._config);

  Future<CapturaUbicacion> capturar() async {
    final punto = await _ubicacion.obtenerUbicacionActual();
    // Busco la ubicación guardada de la tienda
    final tienda = await _config.obtenerUbicacionTienda();
    // Si nadie la ha guardado, no puedo comparar
    if (tienda == null) return CapturaUbicacion(punto, null);
    // Calculo la distancia y veo si es menor al radio
    final distancia = _ubicacion.distanciaEnMetros(punto, tienda);
    return CapturaUbicacion(punto, distancia <= radioMetros);
  }
}
