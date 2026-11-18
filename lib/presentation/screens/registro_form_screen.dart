import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../domain/models/insumo.dart';
import '../../domain/models/registro.dart';
import '../widgets/dictado_text_field.dart';
import '../widgets/estados_vista.dart';
import '../widgets/foto_evidencia_field.dart';
import '../widgets/ubicacion_helper.dart';
import '../widgets/ui_feedback.dart';

/// Formulario para crear un registro de la bitácora.
/// Usa los 3 gadgets: cámara/galería, micrófono (dictado) y GPS.
class RegistroFormScreen extends StatefulWidget {
  const RegistroFormScreen({super.key});

  @override
  State<RegistroFormScreen> createState() => _RegistroFormScreenState();
}

class _RegistroFormScreenState extends State<RegistroFormScreen> {
  final _di = Injector.instance;
  final _notaCtrl = TextEditingController();
  late final Future<List<Insumo>> _insumosFuture;

  TipoRegistro _tipo = TipoRegistro.produccion;

  /// insumoId -> cantidad elegida
  final Map<int, int> _cantidades = {};
  String? _fotoPath;
  bool _guardando = false;
  bool _guardado = false;

  @override
  void initState() {
    super.initState();
    _insumosFuture = _di.inventario.obtenerInsumos();
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    // Si salió sin guardar, borramos la foto para no dejar basura
    if (!_guardado) _di.media.eliminarFoto(_fotoPath);
    super.dispose();
  }

  /// Producción muestra nevera grande y secos; preparados solo la
  /// nevera chica; salida y merma muestran todo.
  List<Insumo> _filtrar(List<Insumo> insumos) => switch (_tipo) {
        TipoRegistro.produccion => insumos
            .where((i) => i.ubicacion != UbicacionInsumo.neveraChica)
            .toList(),
        TipoRegistro.preparados => insumos
            .where((i) => i.ubicacion == UbicacionInsumo.neveraChica)
            .toList(),
        _ => insumos,
      };

  Future<void> _guardar(List<Insumo> insumos) async {
    final items = [
      for (final insumo in _filtrar(insumos))
        if ((_cantidades[insumo.id] ?? 0) > 0)
          RegistroItem(
            insumoId: insumo.id!,
            nombre: insumo.nombre,
            unidad: insumo.unidad,
            cantidad: _cantidades[insumo.id]!,
          ),
    ];

    if (items.isEmpty) {
      UiFeedback.exito(context, 'Marca al menos un insumo con cantidad');
      return;
    }

    setState(() => _guardando = true);

    // GPS al momento de guardar
    final ubicacion = await obtenerUbicacionParaGuardar(context);
    if (ubicacion.cancelado) {
      if (mounted) setState(() => _guardando = false);
      return;
    }

    try {
      await _di.registros.guardarRegistro(Registro(
        tipo: _tipo,
        items: items,
        nota: _notaCtrl.text.trim(),
        fotoPath: _fotoPath,
        ubicacion: ubicacion.captura?.punto,
        enTienda: ubicacion.captura?.enTienda,
        empleado: _di.empleado,
        fecha: DateTime.now(),
      ));
      _guardado = true;
      if (!mounted) return;
      UiFeedback.exito(context, 'Registro guardado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        UiFeedback.error(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo registro')),
      body: FutureBuilder<List<Insumo>>(
        future: _insumosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CargandoVista();
          }
          if (snapshot.hasError) {
            return ErrorVista(
              error: snapshot.error,
              alReintentar: () => Navigator.pop(context),
            );
          }
          final insumos = snapshot.data ?? [];
          final visibles = _filtrar(insumos);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text('¿Qué hiciste?',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in TipoRegistro.values)
                        ChoiceChip(
                          label: Text(t.etiqueta),
                          selected: _tipo == t,
                          onSelected: (_) => setState(() => _tipo = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Cantidades',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Card(
                    child: Column(
                      children: [
                        for (final insumo in visibles)
                          _ContadorInsumo(
                            insumo: insumo,
                            cantidad: _cantidades[insumo.id] ?? 0,
                            alCambiar: (n) =>
                                setState(() => _cantidades[insumo.id!] = n),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FotoEvidenciaField(
                    etiqueta: 'Foto (evidencia)',
                    ruta: _fotoPath,
                    alCambiar: (ruta) => setState(() => _fotoPath = ruta),
                  ),
                  const SizedBox(height: 20),
                  DictadoTextField(
                    controller: _notaCtrl,
                    etiqueta: 'Nota',
                    hint: 'Ej. Hay 5 en la nevera grande y 2 en barra',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.my_location,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                            'Al guardar se registra tu ubicación GPS.'),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: _guardando ? null : () => _guardar(insumos),
                    icon: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_guardando ? 'Guardando…' : 'Guardar registro'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fila con botones - y + para elegir cuántos botes/bolsas.
class _ContadorInsumo extends StatelessWidget {
  final Insumo insumo;
  final int cantidad;
  final ValueChanged<int> alCambiar;

  const _ContadorInsumo({
    required this.insumo,
    required this.cantidad,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(insumo.nombre),
      subtitle: Text('${insumo.ubicacion.etiqueta} · hay ${insumo.cantidad} ${insumo.unidad}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: cantidad > 0 ? () => alCambiar(cantidad - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () => alCambiar(cantidad + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
