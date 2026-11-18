# Barra Mid 🥤

App móvil en Flutter para la **barra de Mid Market (Mérida)**. Lleva el inventario de producción, una bitácora de movimientos con evidencia y los pendientes de limpieza, cosas que antes se reportaban con fotos sueltas en WhatsApp.

**Autor:** Johan Ariel Novelo Martínez · Universidad Anáhuac Mayab · Parcial 2

## ¿Qué problema resuelve?

En la barra se producen botes de plátano, piña, manzana y espinaca (nevera grande). Con ellos se preparan los mixes de medio litro: Green Goodness, Blondish y Skinny Beet and Berries (nevera chica). Todo se reportaba por WhatsApp ("se hicieron 2 botes de plátano" + foto), y por eso:

- nadie sabía cuántos botes quedaban sin abrir la nevera,
- los reportes se perdían entre los mensajes del chat,
- no había forma de comprobar quién hizo la limpieza de la Breville o la Franke, ni cuándo.

## Funciones

| Requisito | Dónde está |
|---|---|
| Scaffold, AppBar y Drawer | Todas las pantallas; menú en `presentation/widgets/app_drawer.dart` |
| Named Routes + Navigator | `core/routes/app_routes.dart` (onGenerateRoute con transición fade/slide) |
| Lista → Detalle → Formulario | Bitácora: `bitacora_screen` → `registro_detalle_screen` → `registro_form_screen` |
| Hero | Foto de la lista al detalle (registros y pendientes hechos) |
| SQLite | `data/database/app_database.dart` (4 tablas y datos iniciales) |
| JSON | Los insumos de cada registro se guardan como JSON (`items_json`) |
| try-catch | Todos los repositorios (`ManejoErroresDb`) y servicios de hardware |
| FutureBuilder | Inventario, bitácora, pendientes, formulario y tienda |
| Cámara / Galería | `services/media_service.dart` + `foto_evidencia_field.dart` |
| Micrófono / dictado | `services/speech_service.dart` + `dictado_text_field.dart` |
| GPS + mapa | `services/location_service.dart` + `ubicacion_mapa.dart` (flutter_map + botón a Google Maps) |
| Login biométrico | `services/auth_service.dart` (huella, rostro o PIN) |
| Permisos negados | Mensajes claros con botón a Ajustes y opción de guardar sin ubicación |

Extras:
- **Foto obligatoria** en cada registro de la bitácora y al cerrar un pendiente.
- **Modo administrador** (PIN): solo el encargado puede borrar registros y pendientes.
- **Diseño Café premium**: fondo espresso, tarjetas crema con barra de stock y títulos en Playfair Display.
- La app guarda la ubicación de la tienda y marca cada evidencia como **En tienda** si se tomó a menos de 150 m.

## Arquitectura (por capas)

```
lib/
├── core/            # errores, rutas, tema, utilidades, inyección de dependencias
├── domain/          # modelos + contratos (interfaces) de repositorios
├── data/            # implementación SQLite de los repositorios
├── services/        # hardware: biometría, cámara, micrófono, GPS
└── presentation/    # pantallas y widgets
```

Las pantallas dependen de las **interfaces** (`RegistroRepository`, `MediaService`...) y no de SQLite ni de los paquetes. Eso cumple la inversión de dependencias de SOLID.

## Cómo correrlo (VS Code)

1. Abre la carpeta `barra_mid` en VS Code.
2. Genera las carpetas de plataforma que faltan. Este comando **no sobrescribe** los archivos que ya vienen (el `AndroidManifest.xml` con permisos y el `MainActivity.kt`):
   ```bash
   flutter create --org com.johan --project-name barra_mid --platforms android,ios .
   ```
3. Instala dependencias y corre:
   ```bash
   flutter pub get
   flutter run
   ```

> ⚠️ Usa exactamente `--org com.johan`, porque el `MainActivity.kt` ya está en `com/johan/barra_mid`. Si Android Studio crea otro `MainActivity` en otra ruta, borra el duplicado. Debe extender `FlutterFragmentActivity` para que funcione la huella.

### En emulador

- **Huella:** en el emulador ve a Settings → Security, pon un PIN y registra una huella. Si no tiene bloqueo, la app te pregunta si quieres entrar de todos modos.
- **GPS:** en los controles extendidos del emulador (⋯ → Location) fija un punto en Mérida.
- **Dictado:** necesita la app de Google instalada y micrófono habilitado en el emulador.

### En tu iPhone sin Mac

1. Sube el proyecto a un repositorio de GitHub (público, así las Actions de macOS son gratis).
2. En el repo entra a **Actions → Compilar iPhone (.ipa) → Run workflow**. Tarda unos 10–15 min.
3. Descarga el artefacto **BarraMid-ipa** (viene en .zip; adentro está `BarraMid.ipa`).
4. En Windows instala **iTunes desde apple.com** (no el de Microsoft Store) y **Sideloadly** (sideloadly.io).
5. Conecta el iPhone por cable, abre Sideloadly, escribe tu Apple ID, arrastra el `.ipa` y dale **Start**.
6. En el iPhone: Ajustes → General → VPN y gestión de dispositivos → confía en tu Apple ID. Si lo pide, activa Ajustes → Privacidad y seguridad → **Modo de desarrollador** y reinicia.

Con un Apple ID gratis la app dura **7 días**; después se vuelve a instalar igual (los datos se conservan si usas el mismo Apple ID).

### iOS con Mac (opcional)

Agrega en `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Para tomar fotos de evidencia</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para elegir fotos de evidencia</string>
<key>NSMicrophoneUsageDescription</key>
<string>Para dictar notas</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Para convertir tu voz a texto</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para registrar dónde se hizo cada movimiento</string>
<key>NSFaceIDUsageDescription</key>
<string>Para iniciar turno de forma segura</string>
```

## Pruebas

```bash
flutter test
```

Las pruebas verifican que los modelos se guardan y se leen igual de SQLite, incluyendo el JSON de los insumos.

## Paquetes

sqflite · path_provider · image_picker · speech_to_text · geolocator · flutter_map · latlong2 · url_launcher · local_auth
