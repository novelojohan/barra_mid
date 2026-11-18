import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/injector.dart';
import 'ui_feedback.dart';

/// Modo administrador: solo con el PIN se pueden borrar registros y
/// pendientes. La primera vez se crea el PIN.
///
/// Regresa true si quedó activo el modo admin.
Future<bool> entrarModoAdmin(BuildContext context) async {
  final di = Injector.instance;
  String? pinGuardado;
  try {
    pinGuardado = await di.config.obtenerPinAdmin();
  } catch (e) {
    if (context.mounted) UiFeedback.error(context, e);
    return false;
  }
  if (!context.mounted) return false;

  final creando = pinGuardado == null;
  final pin = await showDialog<String>(
    context: context,
    builder: (_) => _PinDialog(creando: creando),
  );
  if (pin == null || !context.mounted) return false;

  if (creando) {
    try {
      await di.config.guardarPinAdmin(pin);
    } catch (e) {
      if (context.mounted) UiFeedback.error(context, e);
      return false;
    }
  } else if (pin != pinGuardado) {
    UiFeedback.exito(context, 'PIN incorrecto');
    return false;
  }

  di.esAdmin = true;
  if (context.mounted) UiFeedback.exito(context, 'Modo administrador activo');
  return true;
}

class _PinDialog extends StatefulWidget {
  final bool creando;
  const _PinDialog({required this.creando});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        counterText: '',
        prefixIcon: const Icon(Icons.pin_outlined),
      );

  void _aceptar() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _pinCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final soloNumeros = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      icon: const Icon(Icons.admin_panel_settings_outlined),
      title: Text(widget.creando ? 'Crear PIN de administrador' : 'Modo administrador'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.creando)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                    'Este PIN se pedirá para borrar registros y pendientes. '
                    'Compártelo solo con el encargado.'),
              ),
            TextFormField(
              controller: _pinCtrl,
              autofocus: true,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: soloNumeros,
              decoration: _decoracion('PIN (4 a 6 números)'),
              validator: (v) => (v == null || v.length < 4)
                  ? 'Mínimo 4 números'
                  : null,
              onFieldSubmitted: widget.creando ? null : (_) => _aceptar(),
            ),
            if (widget.creando) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmarCtrl,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: soloNumeros,
                decoration: _decoracion('Confirmar PIN'),
                validator: (v) =>
                    v != _pinCtrl.text ? 'Los PIN no coinciden' : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _aceptar, child: const Text('Entrar')),
      ],
    );
  }
}
