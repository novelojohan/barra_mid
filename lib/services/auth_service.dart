import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

// Las posibles respuestas al pedir la huella
enum ResultadoAuth { exito, cancelado, noDisponible, bloqueado, error }

/// Interfaz del login. La pantalla de login solo conoce esto,
/// no sabe que por dentro uso el paquete local_auth
abstract class AuthService {
  Future<ResultadoAuth> autenticar();
}

/// Login con huella o Face ID usando el paquete local_auth.
/// Si el celular no tiene huella configurada, deja usar el PIN del celular
class BiometricAuthService implements AuthService {
  // El objeto del paquete que habla con el sensor de huella
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<ResultadoAuth> autenticar() async {
    try {
      // Primero reviso si el celular tiene huella, Face ID o al menos PIN
      final soportado = await _auth.isDeviceSupported();
      if (!soportado) return ResultadoAuth.noDisponible;

      // Aquí sale la ventanita del sistema pidiendo la huella.
      // Regresa true si la huella coincidió
      final ok = await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para abrir la barra',
      );
      return ok ? ResultadoAuth.exito : ResultadoAuth.cancelado;
    } on PlatformException catch (e) {
      // Si hubo un problema, el paquete manda un código.
      // Lo traduzco a mis propios resultados para enseñar el mensaje correcto
      switch (e.code) {
        // No tiene huella configurada o no tiene PIN
        case 'NotAvailable':
        case 'NotEnrolled':
        case 'PasscodeNotSet':
          return ResultadoAuth.noDisponible;
        // Se equivocó muchas veces y el sensor se bloqueó
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return ResultadoAuth.bloqueado;
        default:
          return ResultadoAuth.error;
      }
    } catch (_) {
      // En la versión nueva del paquete, si el usuario cancela lanza otro tipo de error
      return ResultadoAuth.cancelado;
    }
  }
}
