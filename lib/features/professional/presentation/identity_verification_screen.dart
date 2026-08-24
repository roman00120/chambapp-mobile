import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IdentityVerificationScreen extends ConsumerWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(identityVerificationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación de identidad')),
      body: SafeArea(
        child: status.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos consultar tu estado',
            message: error,
            onRetry: () => ref.invalidate(identityVerificationProvider),
          ),
          data: (value) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _StatusCard(value: value),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Qué se verificará',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '• Documento oficial vigente y autenticidad.\n'
                '• Coincidencia facial y prueba de vida cuando aplique.\n'
                '• Resultado y vigencia de la verificación.',
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Chambapp no almacena imágenes de documentos ni biometría en esta arquitectura. Sólo conserva el estado mínimo y fechas necesarias.',
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: value.canStartVerification ? () {} : null,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Iniciar verificación (próximamente)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.value});
  final IdentityVerificationModel value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            value.identityVerified ? Icons.verified_user : Icons.badge_outlined,
            color: value.identityVerified
                ? AppColors.success
                : AppColors.amberDark,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.status.label,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.isRequired
                ? (value.message ?? 'La verificación es necesaria para operar.')
                : 'La función aún no es obligatoria mientras se selecciona e integra un proveedor real.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'La revisión de perfil, correo y teléfono no equivale a verificar identidad.',
          ),
        ],
      ),
    ),
  );
}
