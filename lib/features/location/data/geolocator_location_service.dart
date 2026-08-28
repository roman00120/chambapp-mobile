import 'package:chambapp_mobile/features/location/domain/location_service.dart';
import 'package:geocoding/geocoding.dart';
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

      AppAddress? appAddress;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final streetParts = [
            if (p.thoroughfare?.trim().isNotEmpty == true) p.thoroughfare!.trim(),
            if (p.subThoroughfare?.trim().isNotEmpty == true) p.subThoroughfare!.trim(),
          ];
          final street = streetParts.isNotEmpty
              ? streetParts.join(' ')
              : (p.street?.trim().isNotEmpty == true ? p.street!.trim() : null);

          final fullAddressParts = [
            if (street != null && street.isNotEmpty) street,
            if (p.subLocality?.trim().isNotEmpty == true && p.subLocality != street)
              p.subLocality!.trim(),
          ];

          appAddress = AppAddress(
            address: fullAddressParts.isNotEmpty ? fullAddressParts.join(', ') : street,
            city: p.locality?.trim().isNotEmpty == true
                ? p.locality!.trim()
                : (p.subAdministrativeArea?.trim().isNotEmpty == true
                    ? p.subAdministrativeArea!.trim()
                    : null),
            state: p.administrativeArea?.trim().isNotEmpty == true
                ? p.administrativeArea!.trim()
                : null,
            postalCode: p.postalCode?.trim().isNotEmpty == true
                ? p.postalCode!.trim()
                : null,
          );
        }
      } catch (_) {
        // Reverse geocoding failed or offline -> coordinates remain valid
      }

      return AppPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        address: appAddress,
      );
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}
