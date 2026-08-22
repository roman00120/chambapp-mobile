final class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
