import 'dart:io';

import 'package:flutter/material.dart';

/// Muestra una foto guardada en el celular.
/// Si la foto ya no existe, enseña un ícono en vez de que la app truene.
class FotoArchivo extends StatelessWidget {
  final String? ruta;
  final double? width;
  final double? height;
  final double radio;
  final IconData iconoVacio;

  const FotoArchivo({
    super.key,
    required this.ruta,
    this.width,
    this.height,
    this.radio = 12,
    this.iconoVacio = Icons.photo_outlined,
  });

  @override
  Widget build(BuildContext context) {
    // Lo que se ve cuando no hay foto
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(iconoVacio, color: Theme.of(context).colorScheme.outline),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: ruta == null
          ? placeholder
          // Image.file lee la foto desde la ruta del celular
          : Image.file(
              File(ruta!),
              width: width,
              height: height,
              fit: BoxFit.cover,
              // Si no la puede leer, enseña el placeholder
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}
