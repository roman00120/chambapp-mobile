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
    this.capabilities = const [],
    this.activeMode,
    this.email,
    this.phone,
    this.avatarUrl,
    this.status,
    this.emailVerified,
  });

  final int id;
  final String name;
  final UserRole role;
  final List<String> capabilities;
  final String? activeMode;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? status;
  final bool? emailVerified;

  bool get canActAsClient =>
      capabilities.contains('client') ||
      role == UserRole.client ||
      role == UserRole.admin;

  bool get canActAsProfessional =>
      capabilities.contains('professional') ||
      role == UserRole.professional ||
      role == UserRole.admin;

  bool get isAdmin => role == UserRole.admin || capabilities.contains('admin');

  UserRole get effectiveRole {
    if (activeMode == 'client') return UserRole.client;
    if (activeMode == 'professional') return UserRole.professional;
    return role;
  }

  User copyWith({
    String? email,
    String? activeMode,
    List<String>? capabilities,
  }) => User(
    id: id,
    name: name,
    role: role,
    capabilities: capabilities ?? this.capabilities,
    activeMode: activeMode ?? this.activeMode,
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
