import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/shared/widgets/app_feedback.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:chambapp_mobile/shared/widgets/brand_header.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  UserRole _role = UserRole.client;
  RegistrationRequirements? _requirements;
  bool _requirementsLoading = true;
  bool _legalAccepted = false;
  String? _legalError;

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    setState(() {
      _requirementsLoading = true;
      _legalAccepted = false;
      _legalError = null;
    });
    try {
      final requirements = await ref
          .read(authRepositoryProvider)
          .registrationRequirements(_role);
      if (!mounted) return;
      setState(() {
        _requirements = requirements;
        _requirementsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requirements = null;
        _requirementsLoading = false;
        _legalError = 'No pudimos cargar los documentos legales vigentes.';
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirmation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearFeedback();
    if (!_formKey.currentState!.validate()) return;
    final requirements = _requirements;
    if (_requirementsLoading || requirements == null) {
      setState(
        () => _legalError = 'Espera a que carguen los documentos legales.',
      );
      return;
    }
    if (!requirements.registrationAvailable) {
      setState(() => _legalError = 'El registro está temporalmente detenido.');
      return;
    }
    if (requirements.acceptanceRequired && !_legalAccepted) {
      setState(
        () => _legalError =
            'Debes leer y aceptar los documentos legales vigentes.',
      );
      return;
    }
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          RegistrationInput(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            role: _role,
            password: _password.text,
            passwordConfirmation: _confirmation.text,
            legalAccepted: _legalAccepted,
            legalDocuments: {
              for (final document in requirements.documents)
                document.document: document.version,
            },
          ),
        );
    if (!success && mounted) {
      final message = ref.read(authControllerProvider).message;
      if (message != null) AppFeedback.show(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final errors = state.fieldErrors;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandHeader(
                      title: 'Crear cuenta',
                      subtitle: 'Cuéntanos cómo quieres usar Chambapp.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Tipo de cuenta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _RoleOption(
                      key: const Key('role_client'),
                      selected: _role == UserRole.client,
                      icon: Icons.search,
                      title: 'Quiero contratar servicios',
                      subtitle: 'Cuenta de cliente',
                      onTap: () {
                        if (_role == UserRole.client) return;
                        setState(() => _role = UserRole.client);
                        _loadRequirements();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _RoleOption(
                      key: const Key('role_professional'),
                      selected: _role == UserRole.professional,
                      icon: Icons.handyman_outlined,
                      title: 'Quiero ofrecer mis servicios',
                      subtitle: 'Cuenta profesional',
                      onTap: () {
                        if (_role == UserRole.professional) return;
                        setState(() => _role = UserRole.professional);
                        _loadRequirements();
                      },
                    ),
                    if (errors['role'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          errors['role']!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      key: const Key('register_name'),
                      controller: _name,
                      label: 'Nombre completo',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      errorText: errors['name'],
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escribe tu nombre.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      key: const Key('register_email'),
                      controller: _email,
                      label: 'Correo electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: errors['email'],
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      key: const Key('register_phone'),
                      controller: _phone,
                      label: 'Teléfono',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      errorText: errors['phone'],
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escribe tu teléfono.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      key: const Key('register_password'),
                      controller: _password,
                      label: 'Contraseña',
                      textInputAction: TextInputAction.next,
                      errorText: errors['password'],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Escribe una contraseña.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      key: const Key('register_confirmation'),
                      controller: _confirmation,
                      label: 'Confirmar contraseña',
                      textInputAction: TextInputAction.done,
                      validator: (value) => value != _password.text
                          ? 'Las contraseñas no coinciden.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_requirementsLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_requirements != null &&
                        !_requirements!.registrationAvailable)
                      const Text(
                        'El registro está temporalmente detenido hasta publicar los documentos legales definitivos.',
                        key: Key('legal_registration_unavailable'),
                        style: TextStyle(color: AppColors.danger),
                      )
                    else if (_requirements?.acceptanceRequired == true) ...[
                      CheckboxListTile(
                        key: const Key('legal_acceptance_checkbox'),
                        value: _legalAccepted,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          _requirements!.documents.any(
                                (item) => item.document == 'professional_terms',
                              )
                              ? 'He leído y acepto los Términos y Condiciones, el Aviso de Privacidad y los Términos para Profesionales.'
                              : 'He leído y acepto los Términos y Condiciones y el Aviso de Privacidad.',
                        ),
                        onChanged: state.isSubmitting
                            ? null
                            : (value) => setState(() {
                                _legalAccepted = value ?? false;
                                _legalError = null;
                              }),
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final document in _requirements!.documents)
                            TextButton(
                              key: Key('legal_link_${document.document}'),
                              onPressed: () => launchUrl(
                                document.url,
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(document.title),
                            ),
                        ],
                      ),
                    ],
                    if (_legalError != null || errors['legal_accepted'] != null)
                      Text(
                        _legalError ?? errors['legal_accepted']!,
                        key: const Key('legal_acceptance_error'),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    if (state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.message!,
                        key: const Key('register_error'),
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const Key('register_submit'),
                      label: 'Crear cuenta',
                      isLoading: state.isSubmitting,
                      onPressed:
                          _requirementsLoading ||
                              (_requirements?.registrationAvailable == false)
                          ? null
                          : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => context.go('/login'),
                      child: const Text('Ya tengo cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo electrónico.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Ingresa un correo electrónico válido.';
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navy.withValues(alpha: .07)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.navy : const Color(0xFFD7E0E8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.navy : AppColors.muted,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.navy,
            ),
          ],
        ),
      ),
    ),
  );
}
