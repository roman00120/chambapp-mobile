import 'dart:async';

import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef VerificationUrlOpener = Future<bool> Function(Uri url);

Future<bool> openVerificationUrl(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({
    super.key,
    this.urlOpener = openVerificationUrl,
  });

  final VerificationUrlOpener urlOpener;

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen>
    with WidgetsBindingObserver {
  bool _consent = false;
  bool _starting = false;
  bool _verificationOpened = false;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _verificationOpened) {
      _verificationOpened = false;
      unawaited(_sync());
    }
  }

  Future<void> _start() async {
    if (!_consent || _starting) return;
    setState(() {
      _starting = true;
      _actionMessage = null;
    });

    try {
      final result = await ref
          .read(identityVerificationRepositoryProvider)
          .start();
      final opened = await widget.urlOpener(result.url);
      if (!opened) {
        throw StateError('No se pudo abrir el navegador seguro.');
      }
      _verificationOpened = true;
      if (mounted) {
        setState(() {
          _actionMessage = 'Completa el proceso en Didit y regresa a Chambapp para actualizar el estado.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionMessage =
              'No pudimos iniciar la verificación. Inténtalo nuevamente más tarde.';
        });
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _sync() async {
    setState(() => _actionMessage = 'Actualizando el estado con Didit…');
    try {
      await ref.read(identityVerificationRepositoryProvider).sync();
      ref.invalidate(identityVerificationProvider);
      if (mounted) {
        setState(() => _actionMessage = 'Estado actualizado de forma segura.');
      }
    } catch (_) {
      ref.invalidate(identityVerificationProvider);
      if (mounted) {
        setState(() {
          _actionMessage = 'Didit todavía está procesando la verificación. Vuelve a actualizar en unos momentos.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Antes de continuar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Didit puede tratar tu documento oficial, fotografía o selfie, comparación facial y prueba de vida para verificar identidad y prevenir fraude.',
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'La captura ocurre en Didit. Chambapp no almacena documentos, selfies, videos ni biometría cruda. La verificación no implica una consulta a una base gubernamental específica.',
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                onChanged: value.canStartVerification && !_starting
                    ? (checked) => setState(() => _consent = checked == true)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Acepto expresamente iniciar la verificación con Didit para las finalidades descritas.',
                ),
                subtitle: const Text(
                  'Texto sujeto a revisión jurídica. Puedes no continuar mientras la verificación no sea obligatoria.',
                ),
              ),
              if (_actionMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_actionMessage!, key: const Key('kyc-action-message')),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: value.canStartVerification && _consent && !_starting
                    ? _start
                    : null,
                icon: _starting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  _starting ? 'Iniciando…' : 'Verificar mi identidad',
                ),
              ),
              if (value.canStartVerification) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _starting ? null : _sync,
                  child: const Text('Actualizar estado'),
                ),
              ],
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
                : 'La verificación está disponible, pero todavía no bloquea tu operación.',
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
