import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/routes/app_routes.dart';
import 'modo_admin.dart';
import 'ui_feedback.dart';

/// Menú lateral principal.
///
/// Las secciones principales usan pushReplacementNamed para que la pila
/// de navegación no crezca cada vez que cambias de sección (así el botón
/// "atrás" no te regresa infinitamente).
class AppDrawer extends StatelessWidget {
  final String rutaActual;
  const AppDrawer({super.key, required this.rutaActual});

  void _irASeccion(BuildContext context, String ruta) {
    Navigator.pop(context); // Cierra el drawer
    if (ruta != rutaActual) {
      Navigator.pushReplacementNamed(context, ruta);
    }
  }

  void _abrir(BuildContext context, String ruta) {
    Navigator.pop(context);
    Navigator.pushNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final empleado = Injector.instance.empleado;
    final esAdmin = Injector.instance.esAdmin;

    return NavigationDrawer(
      selectedIndex: switch (rutaActual) {
        Rutas.inventario => 0,
        Rutas.bitacora => 1,
        Rutas.pendientes => 2,
        _ => null,
      },
      onDestinationSelected: (i) {
        const secciones = [Rutas.inventario, Rutas.bitacora, Rutas.pendientes];
        _irASeccion(context, secciones[i]);
      },
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tema.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_cafe, color: tema.colorScheme.onPrimary, size: 36),
              const SizedBox(height: 8),
              Text(
                'Barra Mid Market',
                style: tema.textTheme.titleLarge
                    ?.copyWith(color: tema.colorScheme.onPrimary),
              ),
              Text(
                empleado.isEmpty
                    ? 'Sin turno'
                    : 'En turno: $empleado${esAdmin ? '  ·  ADMIN' : ''}',
                style: TextStyle(color: tema.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.kitchen_outlined),
          selectedIcon: Icon(Icons.kitchen),
          label: Text('Inventario'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Bitácora'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: Text('Pendientes'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: const Icon(Icons.store_mall_directory_outlined),
          title: const Text('Ubicación de la tienda'),
          onTap: () => _abrir(context, Rutas.tienda),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: const Icon(Icons.info_outline),
          title: const Text('Acerca de'),
          onTap: () => _abrir(context, Rutas.acerca),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: Icon(
            esAdmin
                ? Icons.admin_panel_settings
                : Icons.admin_panel_settings_outlined,
            color: esAdmin ? tema.colorScheme.primary : null,
          ),
          title: Text(esAdmin ? 'Salir de modo admin' : 'Modo administrador'),
          onTap: () async {
            if (esAdmin) {
              Injector.instance.esAdmin = false;
              UiFeedback.exito(context, 'Saliste del modo administrador');
              Navigator.pop(context);
              return;
            }
            // El diálogo se abre encima del drawer; luego se cierra el drawer
            await entrarModoAdmin(context);
            if (context.mounted) Navigator.pop(context);
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar turno'),
          onTap: () {
            Injector.instance.empleado = '';
            Injector.instance.esAdmin = false;
            // Limpia toda la pila y regresa al login
            Navigator.pushNamedAndRemoveUntil(
                context, Rutas.login, (route) => false);
          },
        ),
      ],
    );
  }
}
