import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/models/registro.dart';
import '../widgets/app_drawer.dart';
import '../widgets/estados_vista.dart';
import '../widgets/foto_archivo.dart';
import '../widgets/ubicacion_mapa.dart';

/// Lista de registros de la bitácora (vista de lista del "diario").
class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  final _repo = Injector.instance.registros;
  late Future<List<Registro>> _registrosFuture;

  @override
  void initState() {
    super.initState();
    _registrosFuture = _repo.obtenerRegistros();
  }

  void _recargar() {
    setState(() => _registrosFuture = _repo.obtenerRegistros());
  }

  Future<void> _abrir(String ruta, {Object? argumento}) async {
    final cambio = await Navigator.pushNamed(context, ruta, arguments: argumento);
    if (cambio == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora de barra')),
      drawer: const AppDrawer(rutaActual: Rutas.bitacora),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(Rutas.registroNuevo),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo registro'),
      ),
      body: FutureBuilder<List<Registro>>(
        future: _registrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CargandoVista(mensaje: 'Cargando bitácora…');
          }
          if (snapshot.hasError) {
            return ErrorVista(error: snapshot.error, alReintentar: _recargar);
          }
          final registros = snapshot.data ?? [];
          if (registros.isEmpty) {
            return const VacioVista(
              icono: Icons.menu_book_outlined,
              mensaje: 'Aún no hay registros.\nAnota tu primera producción.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: registros.length,
              itemBuilder: (context, i) => AparicionAnimada(
                indice: i,
                child: _TarjetaRegistro(
                  registro: registros[i],
                  alTocar: () => _abrir(Rutas.registroDetalle,
                      argumento: registros[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaRegistro extends StatelessWidget {
  final Registro registro;
  final VoidCallback alTocar;
  const _TarjetaRegistro({required this.registro, required this.alTocar});

  IconData get _icono => switch (registro.tipo) {
        TipoRegistro.produccion => Icons.blender_outlined,
        TipoRegistro.preparados => Icons.local_drink_outlined,
        TipoRegistro.salida => Icons.outbox_outlined,
        TipoRegistro.merma => Icons.delete_outline,
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Hero: la foto "vuela" hacia la pantalla de detalle
              Hero(
                tag: 'registro-${registro.id}',
                child: FotoArchivo(
                  ruta: registro.fotoPath,
                  width: 72,
                  height: 72,
                  iconoVacio: _icono,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(registro.tipo.etiqueta,
                        style: tema.textTheme.labelLarge
                            ?.copyWith(color: tema.colorScheme.primary)),
                    Text(
                      registro.resumen,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${registro.empleado} · ${DateFormatter.fechaCorta(registro.fecha)}',
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (registro.ubicacion != null)
                EtiquetaTienda(enTienda: registro.enTienda, soloIcono: true),
            ],
          ),
        ),
      ),
    );
  }
}
