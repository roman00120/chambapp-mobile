import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeRemoteDataSource remote;
  late MemorySessionStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = FakeRemoteDataSource();
    storage = MemorySessionStorage();
    repository = AuthRepositoryImpl(remote, storage, const ApiErrorMapper());
  });

  test('login guarda token y correo en storage seguro abstraído', () async {
    final session = await repository.login(
      email: ' ana@example.test ',
      password: 'secret',
    );
    expect(session.user, testUser);
    expect(storage.token, 'test-token');
    expect(storage.email, 'ana@example.test');
  });

  test('restaura /me cuando existe token y conserva correo local', () async {
    storage
      ..token = 'existing-token'
      ..email = 'ana@example.test';
    final user = await repository.restoreSession();
    expect(user?.email, 'ana@example.test');
  });

  test('logout limpia sesión aunque falle la API', () async {
    storage.token = 'existing-token';
    remote.error = StateError('token revocado');
    await repository.logout();
    expect(storage.token, isNull);
    expect(storage.clearCount, 1);
  });
}
