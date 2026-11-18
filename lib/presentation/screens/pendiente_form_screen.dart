import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../domain/models/pendiente.dart';
import '../widgets/dictado_text_field.dart';
import '../widgets/ui_feedback.dart';

/// Formulario para crear un pendiente nuevo.
class PendienteFormScreen extends StatefulWidget {
  const PendienteFormScreen({super.key});

  @override
  State<PendienteFormScreen> createState() => _PendienteFormScreenState();
}

class _PendienteFormScreenState extends State<PendienteFormScreen> {
  final _di = Injector.instance;
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String _area = areasBarra.first;
  bool _guardando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await _di.pendientes.crearPendiente(Pendiente(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        area: _area,
        creadoPor: _di.empleado,
        fechaCreacion: DateTime.now(),
      ));
      if (!mounted) return;
      UiFeedback.exito(context, 'Pendiente creado');
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
      appBar: AppBar(title: const Text('Nuevo pendiente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: '¿Qué hay que hacer?',
                hintText: 'Ej. Limpieza de la Breville',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe el pendiente' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _area,
              decoration: const InputDecoration(
                labelText: 'Área',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final a in areasBarra)
                  DropdownMenuItem(value: a, child: Text(a)),
              ],
              onChanged: (v) => setState(() => _area = v ?? _area),
            ),
            const SizedBox(height: 16),
            DictadoTextField(
              controller: _descripcionCtrl,
              etiqueta: 'Detalles (opcional)',
              hint: 'Puedes dictarlo con el micrófono',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.add_task),
              label: Text(_guardando ? 'Guardando…' : 'Crear pendiente'),
            ),
          ],
        ),
      ),
    );
  }
}
