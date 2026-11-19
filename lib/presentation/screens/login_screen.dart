import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../widgets/ui_feedback.dart';

/// Pantalla de inicio de turno: el empleado escribe su nombre y pone su huella.
/// Es StatefulWidget porque cambia (el botón enseña que está cargando).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _di = Injector.instance;
  // El controller me deja leer lo que escribieron en el campo
  final _nombreCtrl = TextEditingController();
  bool _cargando = false;

  @override
  // initState se ejecuta una vez, al abrir la pantalla
  void initState() {
    super.initState();
    _cargarUltimoEmpleado();
  }

  // Pone el nombre del último que entró, para no escribirlo cada vez
  Future<void> _cargarUltimoEmpleado() async {
    try {
      final nombre = await _di.config.obtenerUltimoEmpleado();
      if (nombre != null && mounted) _nombreCtrl.text = nombre;
    } catch (_) {
      // Si falla no pasa nada, solo no se llena el nombre
    }
  }

  // Se llama al tocar "Iniciar turno con huella"
  Future<void> _entrar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      UiFeedback.exito(context, 'Escribe tu nombre para iniciar turno');
      return;
    }

    setState(() => _cargando = true);
    // Aquí sale la ventana de la huella / Face ID
    final resultado = await _di.auth.autenticar();
    // mounted = la pantalla sigue abierta (por si el usuario salió mientras esperaba)
    if (!mounted) return;
    setState(() => _cargando = false);

    // Según lo que pasó con la huella, hago una cosa u otra
    switch (resultado) {
      case ResultadoAuth.exito:
        await _iniciarTurno(nombre);
      case ResultadoAuth.cancelado:
        UiFeedback.exito(context, 'Autenticación cancelada');
      case ResultadoAuth.bloqueado:
        UiFeedback.exito(
            context, 'Demasiados intentos. Espera un momento e intenta otra vez.');
      case ResultadoAuth.noDisponible:
        await _sinBiometria(nombre);
      case ResultadoAuth.error:
        UiFeedback.exito(context, 'No se pudo verificar tu identidad');
    }
  }

  /// Si el celular no tiene huella ni PIN (pasa en el emulador), aviso
  /// que no es seguro y solo dejo entrar si confirma
  Future<void> _sinBiometria(String nombre) async {
    final continuar = await UiFeedback.confirmar(
      context,
      titulo: 'Sin bloqueo de pantalla',
      mensaje: 'Este celular no tiene huella ni PIN configurado, así que '
          'cualquiera podría abrir la app. ¿Entrar de todos modos?',
      textoAceptar: 'Entrar',
    );
    if (continuar) await _iniciarTurno(nombre);
  }

  // Guardo quién está en turno y paso al inventario
  Future<void> _iniciarTurno(String nombre) async {
    _di.empleado = nombre;
    try {
      await _di.config.guardarUltimoEmpleado(nombre);
    } catch (_) {}
    if (!mounted) return;
    // pushReplacementNamed QUITA el login de la pila. Así, si le das atrás
    // en el inventario, no regresa al login
    Navigator.pushReplacementNamed(context, Rutas.inventario);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Animación del logo: crece con un rebotito al abrir (elasticOut)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, escala, hijo) =>
                      Transform.scale(scale: escala, child: hijo),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: tema.colorScheme.primary,
                    child: Icon(Icons.local_cafe,
                        size: 52, color: tema.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Barra Mid Market', style: tema.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Inventario, bitácora y pendientes',
                  style: TextStyle(color: tema.colorScheme.outline),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: '¿Quién está en turno?',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _entrar(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _cargando ? null : _entrar,
                    icon: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: const Text('Iniciar turno con huella'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
