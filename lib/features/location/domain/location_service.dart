enum LocationFailure {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

final class AppAddress {
  const AppAddress({
    this.address,
    this.city,
    this.state,
    this.postalCode,
  });

  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;

  bool get isComplete =>
      address?.trim().isNotEmpty == true &&
      city?.trim().isNotEmpty == true &&
      state?.trim().isNotEmpty == true &&
      postalCode?.trim().isNotEmpty == true;
}

final class AppPosition {
  const AppPosition({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final AppAddress? address;
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
