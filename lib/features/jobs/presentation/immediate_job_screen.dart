import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/category_grid.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_wizard_shell.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:chambapp_mobile/features/location/presentation/location_fields.dart';
import 'package:chambapp_mobile/shared/widgets/app_feedback.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
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
  int _step = 0;
  int? _categoryId;
  CategoryModel? _category;
  bool _submitting = false;
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    for (final controller in [_description, _address, _city, _state, _postal]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && _categoryId == null) {
      return _error('Selecciona una categoría.');
    }
    if (_step == 1 && _description.text.trim().length < 10) {
      return _error('Cuéntanos qué necesitas con al menos 10 caracteres.');
    }
    if (_step == 2 && !_hasLocation()) {
      return _error(
        'Comparte tu ubicación o escribe dirección, ciudad y estado.',
      );
    }
    if (_step < 3) setState(() => _step++);
  }

  bool _hasLocation() {
    final position = ref.read(locationControllerProvider).position;
    return position != null ||
        (_address.text.trim().isNotEmpty &&
            _city.text.trim().isNotEmpty &&
            _state.text.trim().isNotEmpty);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final position = ref.read(locationControllerProvider).position;
    try {
      final job = await ref
          .read(jobRepositoryProvider)
          .createImmediate(
            ImmediateJobInput(
              categoryId: _categoryId!,
              serviceId: widget.serviceId,
              description: _description.text,
              location: JobLocationInput(
                latitude: position?.latitude,
                longitude: position?.longitude,
                address: _address.text,
                city: _city.text,
                state: _state.text,
                postalCode: _postal.text,
              ),
            ),
          );
      ref.invalidate(jobsProvider);
      if (mounted) context.go('/jobs/${job.id}/searching', extra: job);
    } catch (error) {
      if (mounted) _error('$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return JobWizardShell(
      title: 'Chamba ahora',
      step: _step,
      stepCount: 4,
      loading: _submitting,
      nextLabel: _step == 3 ? 'Buscar profesionales' : 'Continuar',
      onBack: _step == 0 ? null : () => setState(() => _step--),
      onNext: _step == 3 ? _submit : _next,
      child: switch (_step) {
        0 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué necesitas?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            categories.when(
              data: (items) {
                if (_categoryId != null) {
                  _category = items
                      .where((item) => item.id == _categoryId)
                      .firstOrNull;
                }
                return CategoryGrid(
                  categories: items,
                  onTap: (category) => setState(() {
                    _categoryId = category.id;
                    _category = category;
                  }),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  const Text('No pudimos cargar las categorías.'),
            ),
            if (_category != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  'Seleccionada: ${_category!.name}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        1 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción breve',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Ejemplo: Tengo una fuga debajo del fregadero.'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('immediate_description'),
              controller: _description,
              label: 'Cuéntanos qué necesitas',
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        2 => LocationFields(
          address: _address,
          city: _city,
          stateController: _state,
          postalCode: _postal,
        ),
        _ => _Confirmation(
          category: _category?.name ?? 'Categoría seleccionada',
          description: _description.text,
          location: _address.text.isNotEmpty
              ? '${_address.text}, ${_city.text}'
              : 'Ubicación del dispositivo',
        ),
      },
    );
  }

  void _error(String message) => AppFeedback.show(context, message);
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.category,
    required this.description,
    required this.location,
  });
  final String category;
  final String description;
  final String location;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Confirmar solicitud',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.lg),
      _line('Categoría', category),
      _line('Descripción', description),
      _line('Ubicación', location),
      const SizedBox(height: AppSpacing.lg),
      const Text(
        'Al continuar, el backend buscará profesionales disponibles. No se comparte contacto personal.',
      ),
    ],
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        Text(value),
      ],
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
