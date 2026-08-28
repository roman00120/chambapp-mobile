import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:chambapp_mobile/shared/widgets/app_feedback.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ServiceRequestScreen extends ConsumerStatefulWidget {
  const ServiceRequestScreen({
    required this.serviceId,
    this.service,
    super.key,
  });

  final int serviceId;
  final ServiceModel? service;

  @override
  ConsumerState<ServiceRequestScreen> createState() =>
      _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends ConsumerState<ServiceRequestScreen> {
  static const slots = [
    '08:00-11:00',
    '11:00-14:00',
    '14:00-17:00',
    '17:00-20:00',
  ];

  late DateTime _date;
  String _slot = slots[0];
  bool _submitting = false;

  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();

  String? _addressError;
  String? _cityError;
  String? _stateError;
  String? _postalError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _date = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));
    _prefillFromLocationIfAvailable();
  }

  void _prefillFromLocationIfAvailable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = ref.read(locationControllerProvider);
      _applyAddressIfEmpty(loc);
    });
  }

  void _applyAddressIfEmpty(LocationState loc) {
    final addr = loc.position?.address;
    if (addr == null) return;

    if (_address.text.trim().isEmpty && addr.address?.isNotEmpty == true) {
      _address.text = addr.address!;
    }
    if (_city.text.trim().isEmpty && addr.city?.isNotEmpty == true) {
      _city.text = addr.city!;
    }
    if (_state.text.trim().isEmpty && addr.state?.isNotEmpty == true) {
      _state.text = addr.state!;
    }
    if (_postal.text.trim().isEmpty && addr.postalCode?.isNotEmpty == true) {
      _postal.text = addr.postalCode!;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _description,
      _address,
      _city,
      _state,
      _postal,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final tomorrow = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(tomorrow) ? tomorrow : _date,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _submit(ServiceModel service) async {
    if (_submitting) return;

    setState(() {
      _descriptionError = null;
      _addressError = null;
      _cityError = null;
      _stateError = null;
      _postalError = null;
    });

    final desc = _description.text.trim();
    final addr = _address.text.trim();
    final city = _city.text.trim();
    final state = _state.text.trim();
    final postal = _postal.text.trim();

    bool hasErrors = false;

    if (desc.length < 5) {
      setState(() {
        _descriptionError = 'Describe brevemente lo que necesitas (mínimo 5 caracteres).';
      });
      AppFeedback.show(
        context,
        'Describe brevemente lo que necesitas (mínimo 5 caracteres).',
      );
      hasErrors = true;
    }

    if (addr.isEmpty) {
      setState(() => _addressError = 'Ingresa la dirección del servicio.');
      if (!hasErrors) {
        AppFeedback.show(context, 'Ingresa la dirección del servicio.');
      }
      hasErrors = true;
    }

    if (city.isEmpty) {
      setState(() => _cityError = 'Ingresa la ciudad.');
      if (!hasErrors) {
        AppFeedback.show(context, 'Ingresa la ciudad.');
      }
      hasErrors = true;
    }

    if (state.isEmpty) {
      setState(() => _stateError = 'Ingresa el estado.');
      if (!hasErrors) {
        AppFeedback.show(context, 'Ingresa el estado.');
      }
      hasErrors = true;
    }

    if (postal.isEmpty) {
      setState(() => _postalError = 'Ingresa el código postal.');
      if (!hasErrors) {
        AppFeedback.show(context, 'Ingresa el código postal.');
      }
      hasErrors = true;
    }

    if (hasErrors) {
      return;
    }

    setState(() => _submitting = true);
    final position = ref.read(locationControllerProvider).position;
    final startHour = int.parse(_slot.substring(0, 2));
    final scheduledFor = DateTime(
      _date.year,
      _date.month,
      _date.day,
      startHour,
    );

    try {
      final job = await ref.read(jobRepositoryProvider).createScheduled(
        ScheduledJobInput(
          categoryId: service.category?.id ?? 1,
          serviceId: service.id,
          title: service.title,
          description: desc,
          location: JobLocationInput(
            latitude: position?.latitude,
            longitude: position?.longitude,
            address: addr,
            city: city,
            state: state,
            postalCode: postal,
          ),
          scheduledFor: scheduledFor,
          scheduledSlot: _slot,
        ),
      );

      ref.invalidate(jobsProvider);
      HapticFeedback.mediumImpact();

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.check, size: 40, color: AppColors.success),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '¡Solicitud enviada!',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tu solicitud fue enviada directamente a ${service.professional?.name ?? 'el profesional'}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Ver detalle de la solicitud',
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );

      if (mounted) {
        context.go('/jobs/${job.id}?created=scheduled');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.show(context, '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationControllerProvider, (prev, next) {
      if (next.status == LocationStatus.found) {
        _applyAddressIfEmpty(next);
      }
    });

    if (widget.service != null) {
      return _buildForm(context, widget.service!);
    }

    final detail = ref.watch(serviceDetailProvider(widget.serviceId));
    return detail.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Solicitar servicio')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Solicitar servicio')),
        body: ErrorState(
          title: 'No pudimos cargar el servicio',
          message: '$error',
          onRetry: () => ref.invalidate(serviceDetailProvider(widget.serviceId)),
        ),
      ),
      data: (service) => _buildForm(context, service),
    );
  }

  Widget _buildForm(BuildContext context, ServiceModel service) {
    final location = ref.watch(locationControllerProvider);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(_date);

    final isLocationFound = location.status == LocationStatus.found && location.position != null;
    final isDetecting = location.status == LocationStatus.detecting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar servicio'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Resumen superior del servicio y profesional
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.category != null)
                      Text(
                        service.category!.name,
                        style: const TextStyle(
                          color: AppColors.amberDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      service.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (service.price != null && service.price!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$${service.price} ${service.currency}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    if (service.professional != null) ...[
                      const Divider(height: AppSpacing.lg),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            child: Text(
                              service.professional!.name.isEmpty
                                  ? 'P'
                                  : service.professional!.name[0],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.professional!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '★ ${service.professional!.rating.toStringAsFixed(1)} · ${service.professional!.generalLocation}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sección 1: Fecha y Horario
            Text('Fecha y Horario', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.navy),
                title: Text(dateFormatted),
                subtitle: const Text('Toca para cambiar la fecha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: slots.map((slot) {
                final isSelected = _slot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _slot = slot),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sección 2: Ubicación
            Text('Ubicación del servicio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            if (isLocationFound) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        location.message ?? 'Ubicación encontrada ✓',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.success),
                      tooltip: 'Actualizar ubicación',
                      onPressed: isDetecting
                          ? null
                          : ref.read(locationControllerProvider.notifier).detect,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ] else ...[
              OutlinedButton.icon(
                key: const Key('detect_location_button'),
                onPressed: isDetecting
                    ? null
                    : ref.read(locationControllerProvider.notifier).detect,
                icon: isDetecting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isDetecting
                      ? 'Obteniendo dirección…'
                      : 'Usar mi ubicación actual',
                ),
              ),
              if (location.message != null && location.status != LocationStatus.idle) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  location.message!,
                  style: TextStyle(
                    color: location.status == LocationStatus.error ||
                            location.status == LocationStatus.denied ||
                            location.status == LocationStatus.disabled
                        ? Theme.of(context).colorScheme.error
                        : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
            AppTextField(
              key: const Key('request_address'),
              controller: _address,
              label: 'Dirección (calle y número)',
              errorText: _addressError,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_addressError != null) setState(() => _addressError = null);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    key: const Key('request_city'),
                    controller: _city,
                    label: 'Ciudad',
                    errorText: _cityError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_cityError != null) setState(() => _cityError = null);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    key: const Key('request_state'),
                    controller: _state,
                    label: 'Estado',
                    errorText: _stateError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_stateError != null) setState(() => _stateError = null);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const Key('request_postal'),
              controller: _postal,
              label: 'Código postal',
              errorText: _postalError,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_postalError != null) setState(() => _postalError = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sección 3: Detalles de la solicitud
            Text('Detalles del trabajo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              key: const Key('request_description'),
              controller: _description,
              label: '¿Qué necesitas que realice el profesional?',
              hint: 'Describe brevemente los requerimientos, detalles o dudas...',
              errorText: _descriptionError,
              maxLines: 3,
              onChanged: (_) {
                if (_descriptionError != null) setState(() => _descriptionError = null);
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sección 4: Confirmación y Envío
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de solicitud',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('• Servicio: ${service.title}'),
                    if (service.professional != null)
                      Text('• Profesional: ${service.professional!.name}'),
                    Text('• Horario: $dateFormatted ($_slot)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              key: const Key('confirm_service_request'),
              label: _submitting ? 'Enviando solicitud…' : 'Confirmar solicitud',
              isLoading: _submitting,
              onPressed: _submitting ? null : () => _submit(service),
            ),
          ],
        ),
      ),
    );
  }
}
