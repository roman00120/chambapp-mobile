import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/category_grid.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/service_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ImmediateJobScreen extends ConsumerStatefulWidget {
  const ImmediateJobScreen({this.initialCategoryId, this.serviceId, super.key});
  final int? initialCategoryId;
  final int? serviceId;

  @override
  ConsumerState<ImmediateJobScreen> createState() => _ImmediateJobScreenState();
}

class _ImmediateJobScreenState extends ConsumerState<ImmediateJobScreen> {
  int? _categoryId;
  CategoryModel? _category;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // Buscamos los servicios correspondientes a la categoría seleccionada
    final servicesInput = ServiceSearchQuery(
      categorySlug: _category?.slug,
    );
    final servicesAsync = _category != null
        ? ref.watch(servicesProvider(servicesInput))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamba ahora ⚡'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Banner de marketplace directo
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.amberDark.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.amberDark, size: 28),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Elige la categoría y selecciona al profesional disponible de tu preferencia para contratarlo directamente.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 1. Selección de Categoría
            Text(
              '¿Qué necesitas resolver hoy?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              data: (items) {
                if (_categoryId != null && _category == null) {
                  _category = items
                      .where((item) => item.id == _categoryId)
                      .firstOrNull;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryGrid(
                      categories: items,
                      selectedId: _categoryId,
                      onTap: (cat) => setState(() {
                        _categoryId = cat.id;
                        _category = cat;
                      }),
                    ),
                    if (_category != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Categoría activa: ${_category!.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => ErrorState(
                title: 'No pudimos cargar las categorías',
                message: error,
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Lista de Profesionales y Servicios Disponibles
            if (_category != null) ...[
              Text(
                'Profesionales y servicios disponibles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (servicesAsync != null)
                servicesAsync.when(
                  data: (services) => services.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                          ),
                          child: const Center(
                            child: Text(
                              'Aún no hay profesionales registrados en esta categoría.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: services
                              .map(
                                (service) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: ServiceCard(
                                    service: service,
                                    onTap: () => context.push(
                                      '/services/${service.id}',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => ErrorState(
                    title: 'No pudimos cargar los profesionales',
                    message: error,
                    onRetry: () => ref.invalidate(servicesProvider(servicesInput)),
                  ),
                ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Toca una categoría para ver los profesionales y servicios listos para atenderte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
