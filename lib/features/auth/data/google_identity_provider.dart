import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class GoogleIdentityProvider {
  Future<String> authenticate();
}

final class NativeGoogleIdentityProvider implements GoogleIdentityProvider {
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  bool _initialized = false;

  @override
  Future<String> authenticate() async {
    if (_serverClientId.isEmpty) {
      throw const AppException(
        message: 'El inicio con Google no está configurado en esta versión.',
        code: 'GOOGLE_NOT_CONFIGURED',
      );
    }

    try {
      if (!_initialized) {
        await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
        _initialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppException(
          message: 'Google no entregó una credencial válida.',
          code: 'GOOGLE_TOKEN_MISSING',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AppException(
          message: 'Se canceló el inicio de sesión con Google.',
          code: 'GOOGLE_CANCELED',
        );
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const AppException(
          message: 'Google no está configurado correctamente para esta APK.',
          code: 'GOOGLE_CONFIGURATION_ERROR',
        );
      }
      throw const AppException(
        message: 'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
        code: 'GOOGLE_SIGN_IN_FAILED',
      );
    }
  }
}
