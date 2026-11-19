import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/insumo.dart';
import '../widgets/app_drawer.dart';
import '../widgets/estados_vista.dart';
import '../widgets/ui_feedback.dart';

/// Pantalla principal: el inventario dividido por nevera (en pestañas).
/// Cada insumo sale en una tarjeta crema con su cantidad y una barra.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  // Pido el repositorio al Injector (no sé que es SQLite)
  final _repo = Injector.instance.inventario;
  // Guardo el Future en una variable para que FutureBuilder no vuelva
  // a consultar la base cada vez que se redibuja la pantalla
  late Future<List<Insumo>> _insumosFuture;

  @override
  // Al abrir la pantalla empiezo a leer los insumos
  void initState() {
    super.initState();
    _insumosFuture = _repo.obtenerInsumos();
  }

  // Vuelvo a consultar la base y setState redibuja la pantalla
  void _recargar() {
    setState(() => _insumosFuture = _repo.obtenerInsumos());
  }

  // Abre el formulario. Si regresa true (sí guardó), recargo el inventario
  // porque las cantidades cambiaron
  Future<void> _nuevoRegistro() async {
    final guardado = await Navigator.pushNamed(context, Rutas.registroNuevo);
    if (guardado == true) _recargar();
  }

  /// Se abre al tocar una tarjeta. Sirve para el conteo físico: si cuentas
  /// los botes y no coincide, pones el número real.
  /// Si estás en modo admin, también sale para cambiar el mínimo.
  Future<void> _ajustarConteo(Insumo insumo) async {
    final esAdmin = Injector.instance.esAdmin;
    int cantidad = insumo.cantidad;
    int minimo = insumo.minimo;

    // showModalBottomSheet = la ventanita que sale desde abajo.
    // Regresa dos números juntos: (cantidad, mínimo)
    final resultado = await showModalBottomSheet<(int, int)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder me deja usar setState solo dentro de la ventanita (setSheet)
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(insumo.nombre, style: Theme.of(ctx).textTheme.titleLarge),
                Text('Conteo físico en ${insumo.ubicacion.etiqueta}'),
                const SizedBox(height: 16),
                _Contador(
                  valor: cantidad,
                  etiqueta: insumo.unidad,
                  alCambiar: (n) => setSheet(() => cantidad = n),
                ),
                // Esta parte solo aparece si está activo el modo admin
                if (esAdmin) ...[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings,
                          size: 18, color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 6),
                      const Text('Mínimo de producción (admin)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Contador(
                    valor: minimo,
                    etiqueta: 'mínimo',
                    grande: false,
                    alCambiar: (n) => setSheet(() => minimo = n),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, (cantidad, minimo)),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (resultado == null) return;
    final (nuevaCantidad, nuevoMinimo) = resultado;
    // Solo guardo lo que de verdad cambió
    final cambioCantidad = nuevaCantidad != insumo.cantidad;
    final cambioMinimo = nuevoMinimo != insumo.minimo;
    if (!cambioCantidad && !cambioMinimo) return;

    try {
      if (cambioCantidad) {
        await _repo.actualizarCantidad(insumo.id!, nuevaCantidad);
      }
      if (cambioMinimo) {
        await _repo.actualizarMinimo(insumo.id!, nuevoMinimo);
      }
      if (!mounted) return;
      UiFeedback.exito(context, '${insumo.nombre} actualizado');
      _recargar();
    } catch (e) {
      if (mounted) UiFeedback.error(context, e);
    }
  }

  // Botón + de arriba: abre el diálogo para dar de alta un insumo nuevo
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
    // DefaultTabController maneja las pestañas (una por nevera)
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
        // El menú lateral; le digo que estoy en inventario para marcarlo
        drawer: const AppDrawer(rutaActual: Rutas.inventario),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _nuevoRegistro,
          icon: const Icon(Icons.edit_note),
          label: const Text('Registrar'),
        ),
        // FutureBuilder: espera la respuesta de la base de datos y según el estado
        // enseña algo distinto: cargando, error o ya los datos
        body: FutureBuilder<List<Insumo>>(
          future: _insumosFuture,
          builder: (context, snapshot) {
            // Todavía no llega la respuesta: circulito de carga
            if (snapshot.connectionState != ConnectionState.done) {
              return const CargandoVista(mensaje: 'Cargando inventario…');
            }
            // Algo falló: mensaje y botón de reintentar
            if (snapshot.hasError) {
              return ErrorVista(error: snapshot.error, alReintentar: _recargar);
            }
            final insumos = snapshot.data ?? [];
            // Una lista por pestaña, cada una solo con los insumos de esa nevera
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

// La lista de una nevera
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
    // Cuento cuántos están abajo del mínimo para enseñar el aviso rojo
    final bajos = insumos.where((i) => i.bajoMinimo).length;

    // RefreshIndicator: si jalas la lista hacia abajo, se recarga
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

/// Tarjeta de cada insumo: nombre, cantidad grande y una barra
/// que se llena según cuánto hay (llena = el doble del mínimo).
class _TarjetaInsumo extends StatelessWidget {
  final Insumo insumo;
  final VoidCallback alTocar;

  const _TarjetaInsumo({required this.insumo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final bajo = insumo.bajoMinimo;
    final colorEstado = bajo ? AppTheme.alertaFuerte : AppTheme.dorado;

    // La barra se llena al 100% cuando hay el doble del mínimo.
    // Si hay más, el tope es la cantidad (para no pasar de 100%)
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
                // La barra se llena con animación de 0 hasta el valor real
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

/// Diálogo para agregar un insumo nuevo (nombre, nevera, unidad y mínimo)
class _NuevoInsumoDialog extends StatefulWidget {
  const _NuevoInsumoDialog();

  @override
  State<_NuevoInsumoDialog> createState() => _NuevoInsumoDialogState();
}

class _NuevoInsumoDialogState extends State<_NuevoInsumoDialog> {
  // La llave del Form, para validar todos los campos de un jalón
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
    // Si algún campo está mal (ej. nombre vacío), no deja guardar
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

/// Los botones - y + con el número en medio (lo uso para cantidad y mínimo)
class _Contador extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final bool grande;
  final ValueChanged<int> alCambiar;

  const _Contador({
    required this.valor,
    required this.etiqueta,
    required this.alCambiar,
    this.grande = true,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              iconSize: grande ? 32 : 24,
              onPressed: valor > 0 ? () => alCambiar(valor - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '$valor',
                textAlign: TextAlign.center,
                style: grande
                    ? tema.textTheme.displaySmall
                    : tema.textTheme.headlineMedium,
              ),
            ),
            IconButton.filledTonal(
              iconSize: grande ? 32 : 24,
              onPressed: () => alCambiar(valor + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Text(etiqueta),
      ],
    );
  }
}
