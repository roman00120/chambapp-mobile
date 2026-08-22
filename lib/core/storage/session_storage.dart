import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<String?> readToken();
  Future<String?> readEmail();
  Future<void> save({required String token, required String email});
  Future<void> clear();
}

final class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'session_email';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  @override
  Future<void> save({required String token, required String email}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}
