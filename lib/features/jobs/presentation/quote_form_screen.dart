import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({required this.jobId, super.key});
  final int jobId;
  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_refreshPreview)
      ..dispose();
    _description.dispose();
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cents = _parseCents(_amount.text);
    final fee = cents == null ? null : (cents * 15 / 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar cotización')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Precio del trabajo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _amount,
                    label: 'Precio en MXN',
                    prefixText: r'$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,8}([.]\d{0,2})?$'),
                      ),
                    ],
                    validator: (value) => _parseCents(value ?? '') == null
                        ? 'Escribe un precio mayor a cero.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _description,
                    label: 'Nota de la cotización',
                    hint: 'Incluye mano de obra y material básico.',
                    maxLines: 4,
                    maxLength: 300,
                    validator: (value) => value?.trim().isEmpty == true
                        ? 'Describe brevemente qué incluye.'
                        : null,
                  ),
                ],
              ),
            ),
            if (cents != null && fee != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Card(
                color: AppColors.amber.withValues(alpha: .08),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Previsualización estimada',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      _MoneyRow(label: 'Precio', cents: cents),
                      _MoneyRow(
                        label: 'Comisión Chambapp estimada (15%)',
                        cents: fee,
                      ),
                      _MoneyRow(
                        label: 'Monto profesional estimado',
                        cents: cents - fee,
                      ),
                      const Text(
                        'Laravel calculará y confirmará los importes oficiales al crear el pago.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_serverError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _serverError!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(
                _submitting ? 'Enviando cotización…' : 'Enviar cotización',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _serverError = null;
    });
    try {
      final quote = await ref
          .read(quoteRepositoryProvider)
          .createQuote(
            widget.jobId,
            amount: _amount.text,
            description: _description.text,
          );
      ref.invalidate(jobDetailProvider(widget.jobId));
      ref.invalidate(jobQuotesProvider(widget.jobId));
      if (mounted) Navigator.pop<JobQuoteModel>(context, quote);
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _serverError = error.fieldErrors['description'] ?? error.message;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.cents});
  final String label;
  final int cents;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          _formatCents(cents),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

int? _parseCents(String value) {
  final match = RegExp(r'^(\d{1,8})(?:[.](\d{1,2}))?$')
      .firstMatch(value.trim());
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final decimals = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + int.parse(decimals.isEmpty ? '0' : decimals);
  return cents > 0 ? cents : null;
}

String _formatCents(int cents) =>
    '\$${(cents ~/ 100)}.${(cents % 100).toString().padLeft(2, '0')} MXN';
