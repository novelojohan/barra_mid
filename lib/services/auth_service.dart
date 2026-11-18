import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum ResultadoAuth { exito, cancelado, noDisponible, bloqueado, error }

/// Contrato de autenticación (permite cambiar la implementación o
/// simularla en pruebas).
abstract class AuthService {
  Future<ResultadoAuth> autenticar();
}

/// Login con huella / rostro. Si el celular no tiene biometría
/// configurada, el sistema permite usar el PIN o patrón del celular.
class BiometricAuthService implements AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<ResultadoAuth> autenticar() async {
    try {
      final soportado = await _auth.isDeviceSupported();
      if (!soportado) return ResultadoAuth.noDisponible;

      // Por defecto acepta huella, rostro o el PIN del celular como respaldo
      final ok = await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para abrir la barra',
      );
      return ok ? ResultadoAuth.exito : ResultadoAuth.cancelado;
    } on PlatformException catch (e) {
      // Códigos de local_auth (package:local_auth/error_codes.dart)
      switch (e.code) {
        case 'NotAvailable':
        case 'NotEnrolled':
        case 'PasscodeNotSet':
          return ResultadoAuth.noDisponible;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return ResultadoAuth.bloqueado;
        default:
          return ResultadoAuth.error;
      }
    } catch (_) {
      // local_auth 3.x lanza LocalAuthException (ej. el usuario canceló)
      return ResultadoAuth.cancelado;
    }
  }
}
