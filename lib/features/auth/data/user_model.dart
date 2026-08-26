import 'package:chambapp_mobile/features/auth/domain/user.dart';

final class UserModel {
  const UserModel._();

  static User fromJson(Map<String, dynamic> json, {String? fallbackEmail}) =>
      User(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
        role: UserRole.fromApi(json['role']),
        capabilities:
            (json['capabilities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [json['role']?.toString() ?? 'client'],
        activeMode: json['active_mode']?.toString(),
        email: json['email']?.toString() ?? fallbackEmail,
        phone: json['phone']?.toString(),
        avatarUrl: (json['avatar'] ?? json['profile_photo_url'])?.toString(),
        status: json['status']?.toString(),
        emailVerified: json['email_verified'] is bool
            ? json['email_verified'] as bool
            : null,
      );

  static int _asInt(Object? value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
}
