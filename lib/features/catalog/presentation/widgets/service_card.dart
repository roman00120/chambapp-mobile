import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({required this.service, required this.onTap, super.key});
  final ServiceModel service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final professional = service.professional;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('service_${service.id}'),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RemoteImage(url: service.coverImageUrl, width: 112, height: 132),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (professional != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        professional.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.amberDark,
                          ),
                          Text(' ${professional.rating.toStringAsFixed(1)}'),
                          if (professional.generalLocation.isNotEmpty)
                            Expanded(
                              child: Text(
                                ' · ${professional.generalLocation}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _priceLabel(service),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priceLabel(ServiceModel service) {
    if (service.price == null || service.priceType == 'quote') {
      return 'Cotización';
    }
    final prefix = service.priceType == 'starting_at' ? 'Desde ' : '';
    return '$prefix\$${service.price} ${service.currency}';
  }
}
