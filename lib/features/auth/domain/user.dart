enum UserRole {
  client('client', 'Cliente'),
  professional('professional', 'Profesional'),
  admin('admin', 'Administrador'),
  unsupported('unsupported', 'No compatible');

  const UserRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static UserRole fromApi(Object? value) => switch (value) {
    'client' => UserRole.client,
    'professional' => UserRole.professional,
    'admin' => UserRole.admin,
    _ => UserRole.unsupported,
  };
}

final class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.avatarUrl,
    this.status,
    this.emailVerified,
  });

  final int id;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? status;
  final bool? emailVerified;

  User copyWith({String? email}) => User(
    id: id,
    name: name,
    role: role,
    email: email ?? this.email,
    phone: phone,
    avatarUrl: avatarUrl,
    status: status,
    emailVerified: emailVerified,
  );
}

final class AuthSession {
  const AuthSession({required this.token, required this.user});
  final String token;
  final User user;
}

final class RegistrationInput {
  const RegistrationInput({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.password,
    required this.passwordConfirmation,
  });

  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String password;
  final String passwordConfirmation;
}
