import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../domain/models/insumo.dart';
import '../../domain/models/registro.dart';
import '../widgets/dictado_text_field.dart';
import '../widgets/estados_vista.dart';
import '../widgets/foto_evidencia_field.dart';
import '../widgets/ubicacion_helper.dart';
import '../widgets/ui_feedback.dart';

/// Formulario para un registro nuevo de la bitácora.
/// Aquí se usan los 3 gadgets: cámara/galería (foto), micrófono (nota
/// dictada) y GPS (se toma solo al guardar).
class RegistroFormScreen extends StatefulWidget {
  const RegistroFormScreen({super.key});

  @override
  State<RegistroFormScreen> createState() => _RegistroFormScreenState();
}

class _RegistroFormScreenState extends State<RegistroFormScreen> {
  final _di = Injector.instance;
  // Controller de la nota (ahí también escribe el dictado)
  final _notaCtrl = TextEditingController();
  late final Future<List<Insumo>> _insumosFuture;

  // Por defecto empieza en Producción / relleno
  TipoRegistro _tipo = TipoRegistro.produccion;

  /// Map para guardar cuántos botes eligió de cada insumo.
  /// La llave es el id del insumo y el valor la cantidad
  final Map<int, int> _cantidades = {};
  String? _fotoPath;
  bool _guardando = false;
  // Para saber si se guardó; si no, al salir borro la foto
  bool _guardado = false;

  @override
  void initState() {
    super.initState();
    _insumosFuture = _di.inventario.obtenerInsumos();
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    // Si se salió sin guardar, borro la foto para no dejar basura en el celular
    if (!_guardado) _di.media.eliminarFoto(_fotoPath);
    super.dispose();
  }

  /// Según el tipo, enseño solo los insumos que tienen sentido:
  /// producción = nevera grande y secos, mixes = nevera chica, salida y merma = todos
  List<Insumo> _filtrar(List<Insumo> insumos) => switch (_tipo) {
        TipoRegistro.produccion => insumos
            .where((i) => i.ubicacion != UbicacionInsumo.neveraChica)
            .toList(),
        TipoRegistro.preparados => insumos
            .where((i) => i.ubicacion == UbicacionInsumo.neveraChica)
            .toList(),
        _ => insumos,
      };

  // Se llama al tocar "Guardar registro"
  Future<void> _guardar(List<Insumo> insumos) async {
    // Armo la lista solo con los insumos que tienen cantidad mayor a 0
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
    // La foto es obligatoria: sin foto no deja guardar (igual que en WhatsApp siempre se mandaba)
    if (_fotoPath == null) {
      UiFeedback.exito(context, 'Toma la foto de evidencia para poder guardar');
      return;
    }

    // Pongo el botón en "Guardando..." para que no le den doble clic
    setState(() => _guardando = true);

    // Tomo el GPS justo al guardar. Si falla, el helper le pregunta qué hacer
    final ubicacion = await obtenerUbicacionParaGuardar(context);
    if (ubicacion.cancelado) {
      if (mounted) setState(() => _guardando = false);
      return;
    }

    try {
      // Creo el Registro y lo guardo (esto también actualiza el inventario)
      await _di.registros.guardarRegistro(Registro(
        tipo: _tipo,
        items: items,
        nota: _notaCtrl.text.trim(),
        fotoPath: _fotoPath!,
        ubicacion: ubicacion.captura?.punto,
        enTienda: ubicacion.captura?.enTienda,
        empleado: _di.empleado,
        fecha: DateTime.now(),
      ));
      _guardado = true;
      if (!mounted) return;
      UiFeedback.exito(context, 'Registro guardado');
      // Regreso a la pantalla anterior avisando (true) que sí se guardó
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
      // FutureBuilder: espera la respuesta de la base de datos y según el estado
      // enseña algo distinto: cargando, error o ya los datos
      body: FutureBuilder<List<Insumo>>(
        future: _insumosFuture,
        builder: (context, snapshot) {
          // Todavía no llega la respuesta: circulito de carga
          if (snapshot.connectionState != ConnectionState.done) {
            return const CargandoVista();
          }
          // Algo falló: mensaje y botón de reintentar
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
                        // Los botoncitos para elegir el tipo de registro
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
                          // Un renglón con - y + por cada insumo
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
                    etiqueta: 'Foto de evidencia',
                    obligatoria: true,
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

/// Renglón de un insumo con botones - y + para elegir cuántos
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
