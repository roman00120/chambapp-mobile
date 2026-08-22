import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/availability_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});
  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  int? _radius;

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(availabilityProvider);
    final location = ref.watch(locationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: SafeArea(
        top: false,
        child: availability.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos cargar tu disponibilidad',
            message: error,
            onRetry: () => ref.invalidate(availabilityProvider),
          ),
          data: (value) {
            _radius ??= value.serviceRadiusKm;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AvailabilityCard(
                  availability: value,
                  loading: availability.isLoading,
                  onChanged: value.displayStatus == AvailabilityStatus.busy
                      ? null
                      : (enabled) => _save(value, enabled),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ubicación',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value.locationUpdatedAt == null
                      ? 'Aún no has compartido tu ubicación.'
                      : 'Ubicación actualizada ${DateFormat('dd/MM, HH:mm').format(value.locationUpdatedAt!.toLocal())}',
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: location.status == LocationStatus.detecting
                      ? null
                      : () => _updateLocation(value),
                  icon: location.status == LocationStatus.detecting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Actualizar ubicación'),
                ),
                if (location.message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(location.message!),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '¿Hasta qué distancia quieres recibir chambas?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [5, 10, 15, 25]
                      .map(
                        (radius) => ChoiceChip(
                          label: Text('$radius km'),
                          selected: _radius == radius,
                          onSelected: (_) => setState(() => _radius = radius),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed:
                      availability.isLoading || _radius == value.serviceRadiusKm
                      ? null
                      : () => _save(value, value.isAvailable),
                  child: const Text('Guardar radio'),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'La ubicación se solicita solo mientras usas la app. Chambapp no realiza seguimiento en segundo plano.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateLocation(AvailabilityModel value) async {
    await ref.read(locationControllerProvider.notifier).detect();
    final position = ref.read(locationControllerProvider).position;
    if (position == null) return;
    final ok = await ref
        .read(availabilityProvider.notifier)
        .saveAvailability(
          isAvailable: value.isAvailable,
          serviceRadiusKm: _radius ?? value.serviceRadiusKm,
          latitude: position.latitude,
          longitude: position.longitude,
        );
    if (ok && mounted) _message('Ubicación actualizada.');
  }

  Future<void> _save(AvailabilityModel value, bool enabled) async {
    double? latitude;
    double? longitude;
    if (enabled && (value.latitude == null || value.longitude == null)) {
      await ref.read(locationControllerProvider.notifier).detect();
      final position = ref.read(locationControllerProvider).position;
      if (position == null) {
        if (mounted) {
          _message(
            ref.read(locationControllerProvider).message ??
                'Actualiza tu ubicación antes de ponerte disponible.',
          );
        }
        return;
      }
      latitude = position.latitude;
      longitude = position.longitude;
    }
    final ok = await ref
        .read(availabilityProvider.notifier)
        .saveAvailability(
          isAvailable: enabled,
          serviceRadiusKm: _radius ?? value.serviceRadiusKm,
          latitude: latitude,
          longitude: longitude,
        );
    if (mounted) {
      _message(
        ok
            ? 'Disponibilidad actualizada.'
            : '${ref.read(availabilityProvider).error}',
      );
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
}
