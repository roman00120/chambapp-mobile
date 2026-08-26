import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref.read(unauthorizedEventsProvider).stream.listen((
      _,
    ) {
      unawaited(expireSession());
    });
    ref.onDispose(subscription.cancel);
    return const AuthState();
  }

  Future<void> restoreSession({Future<void>? waitFor}) async {
    state = const AuthState(status: AuthStatus.checking);
    late final AuthState restoredState;
    try {
      final user = await ref.read(authRepositoryProvider).restoreSession();
      restoredState = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } on AppException catch (error) {
      if (error.isUnauthorized || error.statusCode == 403) {
        restoredState = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        restoredState = AuthState(
          status: AuthStatus.checking,
          message: error.message,
        );
      }
    } catch (_) {
      restoredState = const AuthState(
        status: AuthStatus.checking,
        message: 'No pudimos verificar tu sesión. Intenta nuevamente.',
      );
    }

    if (waitFor != null) {
      try {
        await waitFor;
      } catch (_) {
        // A startup animation must never block access to the app.
      }
    }
    state = restoredState;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      isSubmitting: true,
      clearMessage: true,
      fieldErrors: const {},
    );
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } on AppException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        message: error.message,
        fieldErrors: error.fieldErrors,
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    if (state.isSubmitting) return false;
    state = state.copyWith(
      isSubmitting: true,
      clearMessage: true,
      fieldErrors: const {},
    );
    try {
      final idToken = await ref.read(googleIdentityProvider).authenticate();
      final session = await ref
          .read(authRepositoryProvider)
          .loginWithGoogle(idToken: idToken);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } on AppException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        message: error.message,
        fieldErrors: error.fieldErrors,
      );
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
      );
      return false;
    }
  }

  Future<bool> register(RegistrationInput input) async {
    state = state.copyWith(
      isSubmitting: true,
      clearMessage: true,
      fieldErrors: const {},
    );
    try {
      final session = await ref.read(authRepositoryProvider).register(input);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } on AppException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        message: error.message,
        fieldErrors: error.fieldErrors,
      );
      return false;
    }
  }

  Future<void> logout() async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearMessage: true);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> expireSession() async {
    if (state.status == AuthStatus.unauthenticated) return;
    await ref.read(authRepositoryProvider).clearLocalSession();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      message: 'Tu sesión expiró. Inicia sesión nuevamente.',
    );
  }

  void clearFeedback() =>
      state = state.copyWith(clearMessage: true, fieldErrors: const {});

  void switchActiveMode(String mode) {
    if (state.user == null) return;
    final updatedUser = state.user!.copyWith(activeMode: mode);
    state = state.copyWith(user: updatedUser);
  }
}
