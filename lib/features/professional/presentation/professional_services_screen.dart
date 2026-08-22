import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/professional_service_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfessionalServicesScreen extends ConsumerWidget {
  const ProfessionalServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(professionalServicesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis servicios'),
        actions: [
          IconButton(
            tooltip: 'Crear servicio',
            onPressed: () => context.push('/professional/services/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/professional/services/new'),
        icon: const Icon(Icons.add),
        label: const Text('Crear servicio'),
      ),
      body: SafeArea(
        top: false,
        child: services.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos cargar tus servicios',
            message: error,
            onRetry: () => ref.invalidate(professionalServicesProvider),
          ),
          data: (items) => items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_business_outlined, size: 58),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Aún no tienes servicios publicados.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton(
                          onPressed: () =>
                              context.push('/professional/services/new'),
                          child: const Text('Crear servicio'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(professionalServicesProvider);
                    await ref.read(professionalServicesProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      96,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final service = items[index];
                      return ProfessionalServiceCard(
                        service: service,
                        onEdit: () => context.push(
                          '/professional/services/${service.id}/edit',
                          extra: service,
                        ),
                        onDelete: () => _confirmDelete(context, ref, service),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProfessionalServiceModel service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este servicio?'),
        content: Text(
          '${service.title} dejará de aparecer en el catálogo. Esta API no permite reactivarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(professionalServicesProvider.notifier).delete(service.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Servicio eliminado.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos eliminar el servicio.')),
        );
      }
    }
  }
}
