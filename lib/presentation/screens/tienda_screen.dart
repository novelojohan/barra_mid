import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../domain/models/geo_punto.dart';
import '../../services/verificador_tienda.dart';
import '../widgets/estados_vista.dart';
import '../widgets/ubicacion_mapa.dart';
import '../widgets/ui_feedback.dart';

/// Configura la ubicación de Mid Market. Con ella la app sabe si una
/// evidencia se tomó dentro de la tienda (radio de 150 m).
class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final _di = Injector.instance;
  late Future<GeoPunto?> _tiendaFuture;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tiendaFuture = _di.config.obtenerUbicacionTienda();
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _guardando = true);
    try {
      final punto = await _di.ubicacion.obtenerUbicacionActual();
      await _di.config.guardarUbicacionTienda(punto);
      if (!mounted) return;
      UiFeedback.exito(context, 'Ubicación de la tienda guardada');
      setState(() => _tiendaFuture = _di.config.obtenerUbicacionTienda());
    } catch (e) {
      if (mounted) UiFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación de la tienda')),
      body: FutureBuilder<GeoPunto?>(
        future: _tiendaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CargandoVista();
          }
          if (snapshot.hasError) {
            return ErrorVista(
              error: snapshot.error,
              alReintentar: () => setState(() =>
                  _tiendaFuture = _di.config.obtenerUbicacionTienda()),
            );
          }
          final tienda = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Párate dentro de Mid Market y guarda la ubicación. '
                'Después, cada registro y evidencia marcará si se hizo '
                'en tienda (a menos de ${VerificadorTienda.radioMetros.toStringAsFixed(0)} m).',
              ),
              const SizedBox(height: 16),
              if (tienda != null)
                UbicacionMapa(
                  key: ValueKey(tienda.texto), // Recrea el mapa si cambia
                  punto: tienda,
                  enTienda: true,
                  altura: 260,
                )
              else
                const VacioVista(
                  icono: Icons.store_mall_directory_outlined,
                  mensaje: 'Todavía no se guarda la ubicación de la tienda.',
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                onPressed: _guardando ? null : _usarUbicacionActual,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Usar mi ubicación actual'),
              ),
            ],
          );
        },
      ),
    );
  }
}
