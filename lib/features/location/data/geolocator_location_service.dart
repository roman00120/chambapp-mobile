import 'package:chambapp_mobile/features/location/domain/location_service.dart';
import 'package:geolocator/geolocator.dart';

final class GeolocatorLocationService implements LocationService {
  @override
  Future<AppPosition> determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.permissionDeniedForever);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return AppPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}
