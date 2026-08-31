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
import 'package:intl/intl.dart';

class ScheduledJobScreen extends ConsumerStatefulWidget {
  const ScheduledJobScreen({this.initialCategoryId, this.serviceId, super.key});
  final int? initialCategoryId;
  final int? serviceId;

  @override
  ConsumerState<ScheduledJobScreen> createState() => _ScheduledJobScreenState();
}

class _ScheduledJobScreenState extends ConsumerState<ScheduledJobScreen> {
  static const slots = [
    '08:00-11:00',
    '11:00-14:00',
    '14:00-17:00',
    '17:00-20:00',
  ];
  int _step = 0;
  int? _categoryId;
  CategoryModel? _category;
  DateTime? _date;
  String? _slot;
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
    if (_step == 1 && _description.text.trim().isEmpty) {
      return _error('Cuéntanos qué necesitas.');
    }
    if (_step == 2 && !_manualComplete()) {
      return _error('Completa dirección, ciudad, estado y código postal.');
    }
    if (_step < 3) setState(() => _step++);
  }

  bool _manualComplete() => [
    _address,
    _city,
    _state,
    _postal,
  ].every((controller) => controller.text.trim().isNotEmpty);

  Future<void> _pickDate() async {
    final tomorrow = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_date == null || _slot == null) {
      return _error('Selecciona fecha y franja horaria.');
    }
    setState(() => _submitting = true);
    final position = ref.read(locationControllerProvider).position;
    final startHour = int.parse(_slot!.substring(0, 2));
    final scheduledFor = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      startHour,
    );
    try {
      final job = await ref
          .read(jobRepositoryProvider)
          .createScheduled(
            ScheduledJobInput(
              categoryId: _categoryId!,
              serviceId: widget.serviceId,
              title: 'Chamba programada',
              description: _description.text,
              location: JobLocationInput(
                latitude: position?.latitude,
                longitude: position?.longitude,
                address: _address.text,
                city: _city.text,
                state: _state.text,
                postalCode: _postal.text,
              ),
              scheduledFor: scheduledFor,
              scheduledSlot: _slot!,
            ),
          );
      ref.invalidate(jobsProvider);
      if (mounted) {
        if (job.status == JobStatus.awaitingPayment) {
          context.go('/jobs/${job.id}/checkout');
        } else {
          context.go('/jobs/${job.id}?created=scheduled');
        }
      }
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
      title: 'Programar chamba',
      step: _step,
      stepCount: 4,
      loading: _submitting,
      nextLabel: _step == 3 ? 'Programar chamba' : 'Continuar',
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
                _category ??= items
                    .where((item) => item.id == _categoryId)
                    .firstOrNull;
                return CategoryGrid(
                  categories: items,
                  selectedId: _categoryId,
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
              'Descripción',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('scheduled_description'),
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
          postalCodeRequired: true,
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fecha y horario',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              key: const Key('scheduled_date'),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _date == null
                    ? 'Seleccionar fecha'
                    : DateFormat('dd/MM/yyyy').format(_date!),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: const Key('scheduled_slot'),
              initialValue: _slot,
              decoration: const InputDecoration(labelText: 'Franja horaria'),
              items: slots
                  .map(
                    (slot) => DropdownMenuItem(value: slot, child: Text(slot)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _slot = value),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
            Text(_category?.name ?? 'Categoría seleccionada'),
            Text(_description.text),
            Text('${_address.text}, ${_city.text}, ${_state.text}'),
          ],
        ),
      },
    );
  }

  void _error(String message) => AppFeedback.show(context, message);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
