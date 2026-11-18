import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/insumo.dart';
import '../widgets/app_drawer.dart';
import '../widgets/estados_vista.dart';
import '../widgets/ui_feedback.dart';

/// Pantalla principal: inventario por nevera.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _repo = Injector.instance.inventario;
  late Future<List<Insumo>> _insumosFuture;

  @override
  void initState() {
    super.initState();
    _insumosFuture = _repo.obtenerInsumos();
  }

  void _recargar() {
    setState(() => _insumosFuture = _repo.obtenerInsumos());
  }

  Future<void> _nuevoRegistro() async {
    final guardado = await Navigator.pushNamed(context, Rutas.registroNuevo);
    if (guardado == true) _recargar();
  }

  /// Conteo físico: ajusta la cantidad exacta de un insumo.
  Future<void> _ajustarConteo(Insumo insumo) async {
    int cantidad = insumo.cantidad;
    final nuevaCantidad = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(insumo.nombre, style: Theme.of(ctx).textTheme.titleLarge),
              Text('Conteo físico en ${insumo.ubicacion.etiqueta}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 32,
                    onPressed: cantidad > 0
                        ? () => setSheet(() => cantidad--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '$cantidad',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.displaySmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    iconSize: 32,
                    onPressed: () => setSheet(() => cantidad++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Text(insumo.unidad),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, cantidad),
                  child: const Text('Guardar conteo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (nuevaCantidad == null || nuevaCantidad == insumo.cantidad) return;
    try {
      await _repo.actualizarCantidad(insumo.id!, nuevaCantidad);
      if (!mounted) return;
      UiFeedback.exito(context, 'Conteo de ${insumo.nombre} actualizado');
      _recargar();
    } catch (e) {
      if (mounted) UiFeedback.error(context, e);
    }
  }

  Future<void> _agregarInsumo() async {
    final nuevo = await showDialog<Insumo>(
      context: context,
      builder: (_) => const _NuevoInsumoDialog(),
    );
    if (nuevo == null) return;
    try {
      await _repo.agregarInsumo(nuevo);
      if (!mounted) return;
      UiFeedback.exito(context, '${nuevo.nombre} agregado');
      _recargar();
    } catch (e) {
      if (mounted) UiFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: UbicacionInsumo.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventario'),
          actions: [
            IconButton(
              tooltip: 'Agregar insumo',
              onPressed: _agregarInsumo,
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final u in UbicacionInsumo.values) Tab(text: u.etiqueta),
            ],
          ),
        ),
        drawer: const AppDrawer(rutaActual: Rutas.inventario),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _nuevoRegistro,
          icon: const Icon(Icons.edit_note),
          label: const Text('Registrar'),
        ),
        body: FutureBuilder<List<Insumo>>(
          future: _insumosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CargandoVista(mensaje: 'Cargando inventario…');
            }
            if (snapshot.hasError) {
              return ErrorVista(error: snapshot.error, alReintentar: _recargar);
            }
            final insumos = snapshot.data ?? [];
            return TabBarView(
              children: [
                for (final u in UbicacionInsumo.values)
                  _ListaInsumos(
                    insumos: insumos.where((i) => i.ubicacion == u).toList(),
                    alTocar: _ajustarConteo,
                    alRefrescar: () async => _recargar(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListaInsumos extends StatelessWidget {
  final List<Insumo> insumos;
  final ValueChanged<Insumo> alTocar;
  final Future<void> Function() alRefrescar;

  const _ListaInsumos({
    required this.insumos,
    required this.alTocar,
    required this.alRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    if (insumos.isEmpty) {
      return const VacioVista(
        icono: Icons.kitchen_outlined,
        mensaje: 'No hay insumos en esta nevera',
      );
    }
    final bajos = insumos.where((i) => i.bajoMinimo).length;

    return RefreshIndicator(
      onRefresh: alRefrescar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (bajos > 0)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(bajos == 1
                    ? '1 insumo por debajo del mínimo'
                    : '$bajos insumos por debajo del mínimo'),
                subtitle: const Text('Hay que producir o pedir requisición'),
              ),
            ),
          for (var i = 0; i < insumos.length; i++)
            AparicionAnimada(
              indice: i,
              child: _TarjetaInsumo(
                insumo: insumos[i],
                alTocar: () => alTocar(insumos[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta crema con la cantidad grande y una barra de stock
/// (la barra se llena respecto al doble del mínimo).
class _TarjetaInsumo extends StatelessWidget {
  final Insumo insumo;
  final VoidCallback alTocar;

  const _TarjetaInsumo({required this.insumo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final bajo = insumo.bajoMinimo;
    final colorEstado = bajo ? AppTheme.alertaFuerte : AppTheme.dorado;

    // Tope de la barra: el doble del mínimo (o la cantidad si es mayor)
    var tope = insumo.minimo * 2;
    if (insumo.cantidad > tope) tope = insumo.cantidad;
    if (tope == 0) tope = 1;
    final progreso = insumo.cantidad / tope;

    return Card(
      color: AppTheme.crema,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      insumo.nombre,
                      style: const TextStyle(
                        fontFamily: AppTheme.fuenteTitulos,
                        fontVariations: AppTheme.negrita,
                        fontSize: 19,
                        color: AppTheme.espresso,
                      ),
                    ),
                  ),
                  Text(
                    '${insumo.cantidad}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: bajo ? AppTheme.alertaFuerte : AppTheme.espresso,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    insumo.unidad,
                    style: const TextStyle(color: AppTheme.cafeMedio),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progreso > 1 ? 1.0 : progreso),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, valor, _) => LinearProgressIndicator(
                    value: valor,
                    minHeight: 8,
                    color: colorEstado,
                    backgroundColor: const Color(0xFFE2D5C1),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Mínimo ${insumo.minimo}',
                    style: const TextStyle(color: AppTheme.cafeMedio, fontSize: 13),
                  ),
                  const Spacer(),
                  if (bajo) ...[
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppTheme.alertaFuerte),
                    const SizedBox(width: 4),
                    const Text(
                      'Bajo',
                      style: TextStyle(
                        color: AppTheme.alertaFuerte,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo para dar de alta un insumo nuevo.
class _NuevoInsumoDialog extends StatefulWidget {
  const _NuevoInsumoDialog();

  @override
  State<_NuevoInsumoDialog> createState() => _NuevoInsumoDialogState();
}

class _NuevoInsumoDialogState extends State<_NuevoInsumoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _minimoCtrl = TextEditingController(text: '2');
  UbicacionInsumo _ubicacion = UbicacionInsumo.neveraGrande;
  String _unidad = 'botes';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _minimoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Insumo(
        nombre: _nombreCtrl.text.trim(),
        ubicacion: _ubicacion,
        unidad: _unidad,
        cantidad: 0,
        minimo: int.parse(_minimoCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo insumo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UbicacionInsumo>(
                initialValue: _ubicacion,
                decoration: const InputDecoration(labelText: 'Dónde se guarda'),
                items: [
                  for (final u in UbicacionInsumo.values)
                    DropdownMenuItem(value: u, child: Text(u.etiqueta)),
                ],
                onChanged: (v) => setState(() => _ubicacion = v ?? _ubicacion),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _unidad,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: const [
                  DropdownMenuItem(value: 'botes', child: Text('Botes')),
                  DropdownMenuItem(value: 'bolsas', child: Text('Bolsas')),
                ],
                onChanged: (v) => setState(() => _unidad = v ?? _unidad),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mínimo'),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Número inválido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Agregar')),
      ],
    );
  }
}
