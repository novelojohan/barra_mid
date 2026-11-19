import '../../data/database/app_database.dart';
import '../../data/repositories/sqlite_repositorios.dart';
import '../../domain/repositories/repositorios.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/media_service.dart';
import '../../services/speech_service.dart';
import '../../services/verificador_tienda.dart';

/// El Injector es como la "caja" donde creo todos los repositorios y servicios.
///
/// Es el ÚNICO lugar donde digo "el repositorio es de SQLite" o "el GPS es
/// geolocator". Las pantallas solo piden, por ejemplo, Injector.instance.registros,
/// y no saben que por dentro es SQLite. Si mañana lo cambio a Firebase,
/// solo cambio esta clase y las pantallas ni se enteran (la D de SOLID).
class Injector {
  // Constructor privado: nadie más puede crear otro Injector
  Injector._();
  // La única copia que usa toda la app (singleton)
  static final Injector instance = Injector._();

  // late = se crea hasta la primera vez que se usa, no al abrir la app.
  // La base de datos es una sola y la comparten todos los repositorios
  late final AppDatabase _db = AppDatabase();

  // Repositorios: el tipo de la izquierda es la interfaz, el de la derecha la clase real
  late final InventarioRepository inventario = SqliteInventarioRepository(_db);
  late final RegistroRepository registros = SqliteRegistroRepository(_db);
  late final PendienteRepository pendientes = SqlitePendienteRepository(_db);
  late final ConfigRepository config = SqliteConfigRepository(_db);

  // Servicios que usan el hardware del celular
  late final AuthService auth = BiometricAuthService();
  late final MediaService media = ImagePickerMediaService();
  late final SpeechService voz = SpeechToTextService();
  late final LocationService ubicacion = GeolocatorLocationService();
  late final MapsLauncher mapas = UrlMapsLauncher();
  late final VerificadorTienda verificadorTienda =
      VerificadorTienda(ubicacion, config);

  /// Quién está en turno. Se llena en el login y se guarda en cada registro
  String empleado = '';

  /// Si está activo el modo administrador (se entra con PIN).
  /// Solo en modo admin se ven los botones de borrar y se puede cambiar el mínimo
  bool esAdmin = false;
}
