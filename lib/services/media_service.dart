import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/errors/app_exception.dart';

enum OrigenFoto { camara, galeria }

/// Contrato para obtener fotos de evidencia.
abstract class MediaService {
  /// Regresa la ruta local de la foto guardada o null si el usuario canceló.
  Future<String?> obtenerFoto(OrigenFoto origen);
  Future<void> eliminarFoto(String? ruta);
}

/// Usa la cámara o galería con image_picker y copia la imagen a la
/// carpeta privada de la app para que no se pierda si se borra de la
/// galería o se limpia la caché.
class ImagePickerMediaService implements MediaService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> obtenerFoto(OrigenFoto origen) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: origen == OrigenFoto.camara
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 70, // Comprime para no llenar el celular
        maxWidth: 1600,
      );
      if (archivo == null) return null; // El usuario canceló
      return await _guardarEnApp(archivo);
    } on PlatformException catch (e) {
      // image_picker regresa "camera_access_denied" o "photo_access_denied"
      if (e.code.contains('access_denied')) {
        throw PermissionDeniedException(
          origen == OrigenFoto.camara
              ? 'Sin permiso de cámara no se puede tomar la evidencia.'
              : 'Sin permiso de fotos no se puede abrir la galería.',
          permanentlyDenied: true,
          cause: e,
        );
      }
      throw DeviceServiceException('No se pudo abrir la cámara', cause: e);
    } catch (e) {
      throw DeviceServiceException('No se pudo guardar la foto', cause: e);
    }
  }

  Future<String> _guardarEnApp(XFile archivo) async {
    final docs = await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(docs.path, 'evidencias'));
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    final extension = p.extension(archivo.path).isEmpty
        ? '.jpg'
        : p.extension(archivo.path);
    final destino = p.join(
      carpeta.path,
      'evid_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await archivo.saveTo(destino);
    return destino;
  }

  @override
  Future<void> eliminarFoto(String? ruta) async {
    if (ruta == null) return;
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    } catch (_) {
      // Si no se puede borrar la foto no detenemos al usuario.
    }
  }
}
