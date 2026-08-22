import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';

class ProfessionalServiceCard extends StatelessWidget {
  const ProfessionalServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final ProfessionalServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RemoteImage(
            url: service.coverImageUrl,
            width: 88,
            height: 88,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(service.category?.name ?? 'Sin categoría'),
                Text(
                  service.formattedPrice,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      service.isActive
                          ? Icons.check_circle
                          : Icons.pause_circle,
                      size: 17,
                      color: service.isActive
                          ? AppColors.success
                          : AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(service.isActive ? 'Activo' : 'Inactivo'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Editar servicio',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Eliminar servicio',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
