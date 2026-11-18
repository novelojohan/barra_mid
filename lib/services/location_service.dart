import 'dart:async';

import 'package:geolocator/geolocator.dart' hide PermissionDeniedException;
import 'package:url_launcher/url_launcher.dart';

import '../core/errors/app_exception.dart';
import '../domain/models/geo_punto.dart';

/// Contrato de geolocalización.
abstract class LocationService {
  Future<GeoPunto> obtenerUbicacionActual();
  double distanciaEnMetros(GeoPunto a, GeoPunto b);
  Future<void> abrirAjustesApp();
}

/// GPS con geolocator. Revisa servicio y permisos antes de leer.
class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPunto> obtenerUbicacionActual() async {
    final gpsActivo = await Geolocator.isLocationServiceEnabled();
    if (!gpsActivo) {
      throw const DeviceServiceException(
        'El GPS está apagado. Actívalo para registrar dónde se hizo.',
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw const PermissionDeniedException(
        'Negaste el permiso de ubicación.',
      );
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'La ubicación está bloqueada para esta app. Actívala en Ajustes.',
        permanentlyDenied: true,
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPunto(pos.latitude, pos.longitude, precision: pos.accuracy);
    } on TimeoutException {
      // Si tarda mucho usamos la última ubicación conocida
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

/// Abre Google Maps (o el navegador) con las coordenadas guardadas.
abstract class MapsLauncher {
  Future<void> abrirEnGoogleMaps(GeoPunto punto);
}

class UrlMapsLauncher implements MapsLauncher {
  @override
  Future<void> abrirEnGoogleMaps(GeoPunto punto) async {
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
