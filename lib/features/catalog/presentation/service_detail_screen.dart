import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({required this.serviceId, super.key});
  final int serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(serviceDetailProvider(serviceId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del servicio')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: 'No pudimos cargar el servicio',
          message: error,
          onRetry: () => ref.invalidate(serviceDetailProvider(serviceId)),
        ),
        data: (service) => SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              RemoteImage(
                url: service.coverImageUrl,
                height: 230,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.category != null)
                      Text(
                        service.category!.name,
                        style: const TextStyle(
                          color: AppColors.amberDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      service.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      service.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (service.professional != null)
                      Card(
                        child: ListTile(
                          onTap: () => context.push(
                            '/professionals/${service.professional!.id}',
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              service.professional!.name.isEmpty
                                  ? 'P'
                                  : service.professional!.name[0],
                            ),
                          ),
                          title: Text(service.professional!.name),
                          subtitle: Text(
                            '★ ${service.professional!.rating.toStringAsFixed(1)} · ${service.professional!.generalLocation}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const Key('request_service'),
                      label: 'Solicitar chamba',
                      onPressed: () => context.push(
                        '/request/immediate?category=${service.category?.id ?? ''}&service=${service.id}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
