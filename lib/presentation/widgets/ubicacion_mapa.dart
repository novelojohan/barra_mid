import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injector.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/geo_punto.dart';
import 'ui_feedback.dart';

/// Mapa interactivo con el punto donde se guardó el registro.
/// Uso flutter_map con los mapas de OpenStreetMap (son gratis y no piden API key).
/// Abajo pongo un botón que abre las mismas coordenadas en Google Maps.
class UbicacionMapa extends StatelessWidget {
  final GeoPunto punto;
  final bool? enTienda;
  final double altura;

  const UbicacionMapa({
    super.key,
    required this.punto,
    this.enTienda,
    this.altura = 200,
  });

  // Abre Google Maps; si falla, enseño el error
  Future<void> _abrirGoogleMaps(BuildContext context) async {
    try {
      await Injector.instance.mapas.abrirEnGoogleMaps(punto);
    } catch (e) {
      if (context.mounted) UiFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(punto.latitud, punto.longitud);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: altura,
            // El mapa: se puede mover y hacer zoom con los dedos
            child: FlutterMap(
              options: MapOptions(
                // Empieza centrado en el punto y con zoom de calle
                initialCenter: latLng,
                initialZoom: 17,
                interactionOptions: const InteractionOptions(
                  // Todos los gestos menos girar el mapa
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // Las imágenes del mapa (tiles) se descargan de OpenStreetMap
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.johan.barra_mid',
                ),
                // El pin rojo en el punto
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        size: 44,
                        color: AppTheme.alerta,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            EtiquetaTienda(enTienda: enTienda),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _abrirGoogleMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Google Maps'),
            ),
          ],
        ),
        Text(
          punto.precision == null
              ? punto.texto
              : '${punto.texto}  (±${punto.precision!.toStringAsFixed(0)} m)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Etiqueta que dice si la evidencia se tomó en la tienda, fuera o no se sabe
class EtiquetaTienda extends StatelessWidget {
  final bool? enTienda;

  /// En las listas solo enseño el ícono para que quepa
  final bool soloIcono;
  const EtiquetaTienda({super.key, required this.enTienda, this.soloIcono = false});

  @override
  Widget build(BuildContext context) {
    // Según el valor escojo texto, ícono y color (3 casos: true, false, null)
    final (texto, icono, color) = switch (enTienda) {
      true => ('En tienda', Icons.verified, AppTheme.ok),
      false => ('Fuera de tienda', Icons.warning_amber, Colors.orange.shade300),
      null => ('Sin verificar', Icons.help_outline, AppTheme.textoSuave),
    };
    if (soloIcono) {
      return Tooltip(message: texto, child: Icon(icono, size: 22, color: color));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
