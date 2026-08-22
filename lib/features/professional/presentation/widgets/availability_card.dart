import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:flutter/material.dart';

class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    required this.availability,
    required this.loading,
    required this.onChanged,
    this.onManage,
    super.key,
  });

  final AvailabilityModel availability;
  final bool loading;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final status = availability.displayStatus;
    final (color, icon, subtitle) = switch (status) {
      AvailabilityStatus.available => (
        AppColors.success,
        Icons.check_circle,
        'Estás recibiendo chambas cerca de ti.',
      ),
      AvailabilityStatus.busy => (
        AppColors.amberDark,
        Icons.schedule,
        'Actualmente tienes una chamba activa.',
      ),
      AvailabilityStatus.unavailable => (
        AppColors.muted,
        Icons.pause_circle,
        'Activa tu disponibilidad cuando quieras trabajar.',
      ),
    };
    return Semantics(
      label: 'Disponibilidad: ${status.label}',
      child: Card(
        color: color.withValues(alpha: .08),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      status.label,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: color, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (loading)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch.adaptive(
                      key: const Key('availability_switch'),
                      value: availability.isAvailable,
                      onChanged: status == AvailabilityStatus.busy
                          ? null
                          : onChanged,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle),
              if (onManage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    'Ubicación y radio: ${availability.serviceRadiusKm} km',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
