import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injector.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/geo_punto.dart';
import 'ui_feedback.dart';

/// Mapa interactivo (OpenStreetMap) con el punto donde se registró
/// y botón para abrir Google Maps.
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
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 17,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.johan.barra_mid',
                ),
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

/// Chip que indica si la evidencia se tomó dentro de la tienda.
class EtiquetaTienda extends StatelessWidget {
  final bool? enTienda;

  /// En listas solo se muestra el ícono con un tooltip.
  final bool soloIcono;
  const EtiquetaTienda({super.key, required this.enTienda, this.soloIcono = false});

  @override
  Widget build(BuildContext context) {
    final (texto, icono, color) = switch (enTienda) {
      true => ('En tienda', Icons.verified, AppTheme.ok),
      false => ('Fuera de tienda', Icons.warning_amber, Colors.orange.shade800),
      null => ('Sin verificar', Icons.help_outline, Colors.grey.shade700),
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
