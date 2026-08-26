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
    required this.legalAccepted,
    required this.legalDocuments,
  });

  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String password;
  final String passwordConfirmation;
  final bool legalAccepted;
  final Map<String, String> legalDocuments;
}

final class LegalDocument {
  const LegalDocument({
    required this.document,
    required this.title,
    required this.version,
    required this.url,
  });

  final String document;
  final String title;
  final String version;
  final Uri url;
}

final class RegistrationRequirements {
  const RegistrationRequirements({
    required this.acceptanceRequired,
    required this.registrationAvailable,
    required this.documents,
  });

  final bool acceptanceRequired;
  final bool registrationAvailable;
  final List<LegalDocument> documents;
}
