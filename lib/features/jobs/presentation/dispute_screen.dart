import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisputeScreen extends ConsumerStatefulWidget {
  const DisputeScreen({required this.jobId, super.key});
  final int jobId;

  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  DisputeReason? _reason;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reportar un problema')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Cuéntanos qué ocurrió',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'El equipo de Chambapp revisará el caso. Esto no genera un reembolso automático.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<DisputeReason>(
                  initialValue: _reason,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                  items: DisputeReason.values
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason.label),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _reason = value),
                  validator: (value) => value == null
                      ? 'Selecciona el motivo del reporte.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _description,
                  label: 'Descripción (opcional)',
                  maxLines: 5,
                  maxLength: 1000,
                  enabled: !_submitting,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Enviando reporte…' : 'Enviar reporte'),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final job = await ref
          .read(jobRepositoryProvider)
          .reportProblem(
            widget.jobId,
            reason: _reason!,
            description: _description.text,
          );
      ref.invalidate(jobDetailProvider(widget.jobId));
      if (mounted) Navigator.pop<JobModel>(context, job);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
