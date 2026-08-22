import 'package:chambapp_mobile/core/storage/session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('guarda, lee y elimina token y correo', () async {
    final storage = SecureSessionStorage(const FlutterSecureStorage());
    await storage.save(token: 'secret-token', email: 'ana@example.test');
    expect(await storage.readToken(), 'secret-token');
    expect(await storage.readEmail(), 'ana@example.test');
    await storage.clear();
    expect(await storage.readToken(), isNull);
    expect(await storage.readEmail(), isNull);
  });
}
