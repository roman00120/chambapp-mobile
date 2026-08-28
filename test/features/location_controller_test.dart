import 'package:chambapp_mobile/features/location/domain/location_service.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeLocationService implements LocationService {
  _FakeLocationService({this.position, this.error});
  final AppPosition? position;
  final LocationException? error;
  int openSettingsCalls = 0;

  @override
  Future<AppPosition> determinePosition() async {
    if (error != null) throw error!;
    return position!;
  }

  @override
  Future<void> openSettings() async => openSettingsCalls++;
}

void main() {
  test('ubicación encontrada conserva coordenadas válidas y mensaje de completar si no hay dirección', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            position: const AppPosition(latitude: 19.4326, longitude: -99.1332),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(locationControllerProvider.notifier).detect();
    final state = container.read(locationControllerProvider);
    expect(state.status, LocationStatus.found);
    expect(state.position?.latitude, 19.4326);
    expect(state.message, 'Ubicación encontrada. Completa tu dirección.');
  });

  test('ubicación con reverse geocoding completo muestra mensaje de éxito', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            position: const AppPosition(
              latitude: 19.4326,
              longitude: -99.1332,
              address: AppAddress(
                address: 'Av. Insurgentes Sur 1200',
                city: 'Ciudad de México',
                state: 'CDMX',
                postalCode: '03100',
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(locationControllerProvider.notifier).detect();
    final state = container.read(locationControllerProvider);
    expect(state.status, LocationStatus.found);
    expect(state.position?.address?.isComplete, isTrue);
    expect(state.message, 'Ubicación encontrada ✓');
  });

  test('permiso denegado ofrece mensaje para dirección manual', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            error: const LocationException(LocationFailure.permissionDenied),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(locationControllerProvider.notifier).detect();
    final state = container.read(locationControllerProvider);
    expect(state.status, LocationStatus.denied);
    expect(state.message, contains('dirección'));
  });

  test('GPS desactivado se distingue de permiso denegado', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            error: const LocationException(LocationFailure.serviceDisabled),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(locationControllerProvider.notifier).detect();
    expect(
      container.read(locationControllerProvider).status,
      LocationStatus.disabled,
    );
  });

  test('permiso bloqueado permite abrir los ajustes del sistema', () async {
    final service = _FakeLocationService(
      error: const LocationException(LocationFailure.permissionDeniedForever),
    );
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(locationControllerProvider.notifier).detect();
    expect(
      container.read(locationControllerProvider).status,
      LocationStatus.permanentlyDenied,
    );
    await container.read(locationControllerProvider.notifier).openSettings();
    expect(service.openSettingsCalls, 1);
  });
}
