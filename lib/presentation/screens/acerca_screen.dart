import 'package:flutter/material.dart';

/// Información de la app y el problema que resuelve.
class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.local_cafe, size: 64, color: tema.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Barra Mid', textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall),
          const Text('Versión 1.0.0', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text(
            'Antes, la producción (botes de plátano, piña, manzana...), los '
            'preparados de la nevera chica y las limpiezas de la Breville y la '
            'Franke se reportaban con fotos en WhatsApp. Los mensajes se '
            'pierden entre el chat y nadie sabe cuántos botes quedan.\n\n'
            'Barra Mid lleva el inventario por nevera, guarda cada movimiento '
            'con foto, nota dictada y ubicación, y tiene una lista de '
            'pendientes que solo se cierran con foto de evidencia.',
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Login con huella'),
          ),
          const ListTile(
            leading: Icon(Icons.photo_camera),
            title: Text('Evidencia con cámara o galería'),
          ),
          const ListTile(
            leading: Icon(Icons.mic),
            title: Text('Notas por dictado de voz'),
          ),
          const ListTile(
            leading: Icon(Icons.location_on),
            title: Text('GPS y mapa de cada registro'),
          ),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('Funciona sin internet (SQLite)'),
          ),
          const SizedBox(height: 16),
          Text(
            'Johan Ariel Novelo Martínez · Universidad Anáhuac Mayab',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
