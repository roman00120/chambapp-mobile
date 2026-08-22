import 'package:chambapp_mobile/features/location/data/geolocator_location_service.dart';
import 'package:chambapp_mobile/features/location/domain/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocationStatus {
  idle,
  detecting,
  found,
  denied,
  permanentlyDenied,
  disabled,
  error,
}

final class LocationState {
  const LocationState({
    this.status = LocationStatus.idle,
    this.position,
    this.message,
  });
  final LocationStatus status;
  final AppPosition? position;
  final String? message;
}

final class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> detect() async {
    state = const LocationState(status: LocationStatus.detecting);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .determinePosition();
      state = LocationState(
        status: LocationStatus.found,
        position: position,
        message: 'Ubicación encontrada.',
      );
    } on LocationException catch (error) {
      state = LocationState(
        status: switch (error.failure) {
          LocationFailure.permissionDenied => LocationStatus.denied,
          LocationFailure.permissionDeniedForever =>
            LocationStatus.permanentlyDenied,
          LocationFailure.serviceDisabled => LocationStatus.disabled,
          LocationFailure.unavailable => LocationStatus.error,
        },
        message: error.message,
      );
    }
  }

  Future<void> openSettings() =>
      ref.read(locationServiceProvider).openSettings();
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);
final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);
