import '../../data/database/app_database.dart';
import '../../data/repositories/sqlite_repositorios.dart';
import '../../domain/repositories/repositorios.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/media_service.dart';
import '../../services/speech_service.dart';
import '../../services/verificador_tienda.dart';

/// Contenedor de dependencias (Service Locator sencillo).
///
/// Aquí es el ÚNICO lugar donde se decide qué implementación concreta se
/// usa. Las pantallas piden la abstracción (ej. [RegistroRepository]) y no
/// saben que por dentro es SQLite.
class Injector {
  Injector._();
  static final Injector instance = Injector._();

  late final AppDatabase _db = AppDatabase();

  // Repositorios
  late final InventarioRepository inventario = SqliteInventarioRepository(_db);
  late final RegistroRepository registros = SqliteRegistroRepository(_db);
  late final PendienteRepository pendientes = SqlitePendienteRepository(_db);
  late final ConfigRepository config = SqliteConfigRepository(_db);

  // Servicios de hardware
  late final AuthService auth = BiometricAuthService();
  late final MediaService media = ImagePickerMediaService();
  late final SpeechService voz = SpeechToTextService();
  late final LocationService ubicacion = GeolocatorLocationService();
  late final MapsLauncher mapas = UrlMapsLauncher();
  late final VerificadorTienda verificadorTienda =
      VerificadorTienda(ubicacion, config);

  /// Nombre de quien está en turno (se pide en el login).
  String empleado = '';
}
