enum LocationFailure {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

final class AppPosition {
  const AppPosition({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

final class LocationException implements Exception {
  const LocationException(this.failure);
  final LocationFailure failure;

  String get message => switch (failure) {
    LocationFailure.permissionDenied =>
      'Permiso de ubicación denegado. Puedes escribir tu dirección.',
    LocationFailure.permissionDeniedForever =>
      'El permiso está bloqueado. Actívalo en Ajustes o escribe tu dirección.',
    LocationFailure.serviceDisabled =>
      'Activa el GPS o escribe tu dirección manualmente.',
    LocationFailure.unavailable =>
      'No pudimos obtener tu ubicación. Intenta nuevamente.',
  };
}

abstract interface class LocationService {
  Future<AppPosition> determinePosition();
  Future<void> openSettings();
}
