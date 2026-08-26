import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/reports/data/disciplinary_repository.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _categories = [
  ('fraud', 'Fraude o estafa'),
  ('threats', 'Amenazas'),
  ('violence', 'Violencia o agresión'),
  ('harassment', 'Acoso o intimidación'),
  ('identity_impersonation', 'Suplantación de identidad'),
  ('theft', 'Robo o extravío de bienes'),
  ('no_show', 'No se presentó al servicio'),
  ('payment_issue', 'Cobro irregular o problema de pago'),
  ('abusive_behavior', 'Comportamiento abusivo o irrespetuoso'),
  ('unsafe_behavior', 'Conducta peligrosa o negligente'),
  ('false_information', 'Información falsa'),
  ('service_misconduct', 'Mala conducta durante el servicio'),
  ('property_damage', 'Daño a propiedad'),
  ('other', 'Otro motivo'),
];

class ReportUserSheet extends ConsumerStatefulWidget {
  const ReportUserSheet({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    this.jobRequestId,
  });

  final int reportedUserId;
  final String reportedUserName;
  final int? jobRequestId;

  static Future<void> show(
    BuildContext context, {
    required int reportedUserId,
    required String reportedUserName,
    int? jobRequestId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportUserSheet(
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        jobRequestId: jobRequestId,
      ),
    );
  }

  @override
  ConsumerState<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends ConsumerState<ReportUserSheet> {
  String _selectedCategory = _categories.first.$1;
  final _descriptionController = TextEditingController();
  bool _confirmed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmed) {
      setState(
        () => _errorMessage = 'Debes confirmar la veracidad del reporte.',
      );
      return;
    }
    if (_descriptionController.text.trim().length < 10) {
      setState(
        () => _errorMessage =
            'Por favor describe lo ocurrido con al menos 10 caracteres.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(disciplinaryRepositoryProvider)
          .createReport(
            reportedId: widget.reportedUserId,
            category: _selectedCategory,
            description: _descriptionController.text.trim(),
            jobRequestId: widget.jobRequestId,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reporte enviado. Nuestro equipo lo revisará. Un reporte no genera una sanción automática.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reportar usuario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Reportando a: ${widget.reportedUserName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Motivo principal:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.$1,
                      child: Text(c.$2, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '¿Qué ocurrió?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe lo sucedido con detalle...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (val) => setState(() => _confirmed = val ?? false),
              title: const Text(
                'Confirmo que la información proporcionada es verdadera según mi conocimiento.',
                style: TextStyle(fontSize: 12),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Enviar reporte',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
