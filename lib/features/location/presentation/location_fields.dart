import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationFields extends ConsumerWidget {
  const LocationFields({
    required this.address,
    required this.city,
    required this.stateController,
    required this.postalCode,
    this.postalCodeRequired = false,
    super.key,
  });
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController stateController;
  final TextEditingController postalCode;
  final bool postalCodeRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('detect_location'),
          onPressed: location.status == LocationStatus.detecting
              ? null
              : ref.read(locationControllerProvider.notifier).detect,
          icon: location.status == LocationStatus.detecting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(
            location.status == LocationStatus.detecting
                ? 'Detectando ubicación…'
                : 'Usar mi ubicación actual',
          ),
        ),
        if (location.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            location.message!,
            key: const Key('location_message'),
            style: TextStyle(
              color: location.status == LocationStatus.found
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ),
        ],
        if (location.status == LocationStatus.permanentlyDenied) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: ref
                .read(locationControllerProvider.notifier)
                .openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Abrir configuración'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Dirección manual', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Puedes explorar sin ubicación. Para solicitar una chamba necesitamos una zona válida.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('location_address'),
          controller: address,
          label: 'Dirección',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('location_city'),
          controller: city,
          label: 'Ciudad',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('location_state'),
          controller: stateController,
          label: 'Estado',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('location_postal'),
          controller: postalCode,
          label: postalCodeRequired
              ? 'Código postal'
              : 'Código postal (opcional)',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Tu dirección exacta permanece privada y el backend solo la comparte cuando las reglas de pago lo permiten.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ],
    );
  }
}
