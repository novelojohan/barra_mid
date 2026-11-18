import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/models/pendiente.dart';
import '../widgets/app_drawer.dart';
import '../widgets/estados_vista.dart';
import '../widgets/foto_archivo.dart';
import '../widgets/ubicacion_mapa.dart';

/// Pendientes de la barra divididos en "Por hacer" y "Hechos".
class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  final _repo = Injector.instance.pendientes;
  late Future<List<Pendiente>> _pendientesFuture;

  @override
  void initState() {
    super.initState();
    _pendientesFuture = _repo.obtenerPendientes();
  }

  void _recargar() {
    setState(() => _pendientesFuture = _repo.obtenerPendientes());
  }

  Future<void> _abrir(String ruta, {Object? argumento}) async {
    final cambio = await Navigator.pushNamed(context, ruta, arguments: argumento);
    if (cambio == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pendientes'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Por hacer'), Tab(text: 'Hechos')],
          ),
        ),
        drawer: const AppDrawer(rutaActual: Rutas.pendientes),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrir(Rutas.pendienteNuevo),
          icon: const Icon(Icons.add_task),
          label: const Text('Nuevo pendiente'),
        ),
        body: FutureBuilder<List<Pendiente>>(
          future: _pendientesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CargandoVista(mensaje: 'Cargando pendientes…');
            }
            if (snapshot.hasError) {
              return ErrorVista(error: snapshot.error, alReintentar: _recargar);
            }
            final todos = snapshot.data ?? [];
            final porHacer = todos.where((p) => !p.hecho).toList();
            final hechos = todos.where((p) => p.hecho).toList();

            return TabBarView(
              children: [
                _lista(
                  porHacer,
                  vacio: '¡Todo al día! No hay pendientes.',
                  icono: Icons.task_alt,
                ),
                _lista(
                  hechos,
                  vacio: 'Todavía no hay pendientes terminados.',
                  icono: Icons.photo_camera_outlined,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _lista(List<Pendiente> lista,
      {required String vacio, required IconData icono}) {
    if (lista.isEmpty) return VacioVista(icono: icono, mensaje: vacio);
    return RefreshIndicator(
      onRefresh: () async => _recargar(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: lista.length,
        itemBuilder: (context, i) {
          final p = lista[i];
          return AparicionAnimada(
            indice: i,
            child: p.hecho
                ? _TarjetaHecho(
                    pendiente: p,
                    alTocar: () => _abrir(Rutas.pendienteDetalle, argumento: p),
                  )
                : _TarjetaPorHacer(
                    pendiente: p,
                    alTocar: () => _abrir(Rutas.pendienteDetalle, argumento: p),
                    alCompletar: () =>
                        _abrir(Rutas.pendienteCompletar, argumento: p),
                  ),
          );
        },
      ),
    );
  }
}

IconData iconoArea(String area) => switch (area) {
      'Breville' || 'Franke' => Icons.coffee_maker_outlined,
      'Nevera grande' || 'Nevera chica' => Icons.kitchen_outlined,
      'Barra' => Icons.storefront_outlined,
      _ => Icons.cleaning_services_outlined,
    };

class _TarjetaPorHacer extends StatelessWidget {
  final Pendiente pendiente;
  final VoidCallback alTocar;
  final VoidCallback alCompletar;

  const _TarjetaPorHacer({
    required this.pendiente,
    required this.alTocar,
    required this.alCompletar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: alTocar,
        leading: CircleAvatar(child: Icon(iconoArea(pendiente.area))),
        title: Text(pendiente.titulo),
        subtitle: Text('${pendiente.area} · por ${pendiente.creadoPor}'),
        trailing: FilledButton.tonalIcon(
          onPressed: alCompletar,
          icon: const Icon(Icons.photo_camera, size: 18),
          label: const Text('Hecho'),
        ),
      ),
    );
  }
}

class _TarjetaHecho extends StatelessWidget {
  final Pendiente pendiente;
  final VoidCallback alTocar;
  const _TarjetaHecho({required this.pendiente, required this.alTocar});

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
              Hero(
                tag: 'pendiente-${pendiente.id}',
                child: FotoArchivo(
                  ruta: pendiente.evidenciaPath,
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pendiente.titulo, style: tema.textTheme.titleMedium),
                    Text(
                      '${pendiente.completadoPor} · ${DateFormatter.fechaCorta(pendiente.fechaCompletado!)}',
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              EtiquetaTienda(enTienda: pendiente.enTienda, soloIcono: true),
            ],
          ),
        ),
      ),
    );
  }
}
