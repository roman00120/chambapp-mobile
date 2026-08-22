import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/api_client.dart';
import 'package:chambapp_mobile/core/storage/session_storage.dart';
import 'package:chambapp_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:chambapp_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:chambapp_mobile/features/auth/domain/auth_repository.dart';
import 'package:chambapp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:chambapp_mobile/features/auth/presentation/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SecureSessionStorage(ref.watch(secureStorageProvider)),
);

final unauthorizedEventsProvider = Provider<UnauthorizedEvents>((ref) {
  final events = UnauthorizedEvents();
  ref.onDispose(events.dispose);
  return events;
});

final dioProvider = Provider<Dio>(
  (ref) => buildDio(
    storage: ref.watch(sessionStorageProvider),
    unauthorizedEvents: ref.watch(unauthorizedEventsProvider),
  ),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => DioAuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    const ApiErrorMapper(),
  ),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
