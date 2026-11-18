import 'dart:io';

import 'package:flutter/material.dart';

/// Muestra una foto guardada en el celular. Si no existe o se borró,
/// muestra un ícono en lugar de tronar.
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
          : Image.file(
              File(ruta!),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}
