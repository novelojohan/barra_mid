import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/errors/app_exception.dart';

// De dónde viene la foto
enum OrigenFoto { camara, galeria }

/// Interfaz para las fotos de evidencia (cámara o galería)
abstract class MediaService {
  /// Regresa la ruta donde quedó guardada la foto, o null si el usuario canceló
  Future<String?> obtenerFoto(OrigenFoto origen);
  // Borra la foto del celular (cuando se borra el registro o se cancela el formulario)
  Future<void> eliminarFoto(String? ruta);
}

/// Saca la foto con el paquete image_picker (abre la cámara o la galería).
/// Después copio la foto a una carpeta de la app, porque si la dejo donde
/// la pone image_picker el celular la puede borrar, o si el usuario la borra
/// de su galería se perdería la evidencia.
class ImagePickerMediaService implements MediaService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> obtenerFoto(OrigenFoto origen) async {
    try {
      // Abre la cámara o la galería y espera a que el usuario tome/elija la foto
      final XFile? archivo = await _picker.pickImage(
        source: origen == OrigenFoto.camara
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 70, // La comprimo un poco para que no pese tanto
        maxWidth: 1600,
      );
      if (archivo == null) return null; // Le dio cancelar
      return await _guardarEnApp(archivo);
    } on PlatformException catch (e) {
      // Si el usuario no dio permiso de cámara o fotos, aviso con mi propio error
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

  // Copia la foto a la carpeta "evidencias" dentro de los documentos de la app
  Future<String> _guardarEnApp(XFile archivo) async {
    final docs = await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(docs.path, 'evidencias'));
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    final extension = p.extension(archivo.path).isEmpty
        ? '.jpg'
        : p.extension(archivo.path);
    // Le pongo un nombre único con la hora en milisegundos para que no se repita
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
      // Si no se pudo borrar no pasa nada grave, no detengo al usuario
    }
  }
}
