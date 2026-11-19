import 'dart:async';

// hide: el paquete geolocator también tiene una clase PermissionDeniedException
// y chocaba con la mía, así que le digo que no importe la suya
import 'package:geolocator/geolocator.dart' hide PermissionDeniedException;
import 'package:url_launcher/url_launcher.dart';

import '../core/errors/app_exception.dart';
import '../domain/models/geo_punto.dart';

/// Interfaz del GPS
abstract class LocationService {
  Future<GeoPunto> obtenerUbicacionActual();
  // Distancia en metros entre dos puntos (la uso para saber si estás en la tienda)
  double distanciaEnMetros(GeoPunto a, GeoPunto b);
  // Abre los ajustes de la app para que el usuario active el permiso
  Future<void> abrirAjustesApp();
}

/// GPS con el paquete geolocator.
/// Antes de leer la ubicación reviso 2 cosas: que el GPS esté prendido
/// y que el usuario haya dado permiso. Si no, lanzo un error claro.
class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPunto> obtenerUbicacionActual() async {
    // 1) ¿El GPS del celular está prendido?
    final gpsActivo = await Geolocator.isLocationServiceEnabled();
    if (!gpsActivo) {
      throw const DeviceServiceException(
        'El GPS está apagado. Actívalo para registrar dónde se hizo.',
      );
    }

    // 2) ¿Hay permiso? Si todavía no lo ha dado, se lo pido
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw const PermissionDeniedException(
        'Negaste el permiso de ubicación.',
      );
    }
    // Lo negó para siempre: solo se puede activar desde Ajustes
    if (permiso == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'La ubicación está bloqueada para esta app. Actívala en Ajustes.',
        permanentlyDenied: true,
      );
    }

    try {
      // Pido la ubicación con precisión alta, pero máximo espero 15 segundos
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPunto(pos.latitude, pos.longitude, precision: pos.accuracy);
    } on TimeoutException {
      // Si tardó más de 15 s, uso la última ubicación que el celular tenía guardada
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) {
        return GeoPunto(ultima.latitude, ultima.longitude,
            precision: ultima.accuracy);
      }
      throw const DeviceServiceException(
        'El GPS tardó demasiado. Intenta cerca de una ventana o puerta.',
      );
    } catch (e) {
      throw DeviceServiceException('No se pudo leer el GPS', cause: e);
    }
  }

  @override
  double distanciaEnMetros(GeoPunto a, GeoPunto b) =>
      Geolocator.distanceBetween(a.latitud, a.longitud, b.latitud, b.longitud);

  @override
  Future<void> abrirAjustesApp() async {
    await Geolocator.openAppSettings();
  }
}

/// Interfaz para abrir las coordenadas en Google Maps
abstract class MapsLauncher {
  Future<void> abrirEnGoogleMaps(GeoPunto punto);
}

// Lo hago con url_launcher: abro un link de Google Maps con las coordenadas
class UrlMapsLauncher implements MapsLauncher {
  @override
  Future<void> abrirEnGoogleMaps(GeoPunto punto) async {
    // Si tiene la app de Google Maps se abre ahí, si no, en el navegador
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${punto.latitud},${punto.longitud}',
    );
    bool abierto = false;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      throw DeviceServiceException('No se pudo abrir Google Maps', cause: e);
    }
    if (!abierto) {
      throw const DeviceServiceException('No hay app para abrir el mapa');
    }
  }
}
