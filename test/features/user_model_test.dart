import 'package:chambapp_mobile/features/auth/data/user_model.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parsea únicamente los campos expuestos y tolera opcionales ausentes',
    () {
      final user = UserModel.fromJson({
        'id': 12,
        'name': 'Luis Gómez',
        'role': 'professional',
        'status': 'active',
      }, fallbackEmail: 'luis@example.test');
      expect(user.id, 12);
      expect(user.role, UserRole.professional);
      expect(user.email, 'luis@example.test');
      expect(user.phone, isNull);
      expect(user.avatarUrl, isNull);
    },
  );

  test('reconoce el rol administrador para abrir su panel móvil', () {
    final user = UserModel.fromJson({
      'id': 1,
      'name': 'Administración Chambapp',
      'email': 'admin@example.test',
      'role': 'admin',
      'status': 'active',
    });

    expect(user.role, UserRole.admin);
    expect(user.role.label, 'Administrador');
  });
}
