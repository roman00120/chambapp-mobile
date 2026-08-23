import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/shared/widgets/app_feedback.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:chambapp_mobile/shared/widgets/brand_header.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearFeedback();
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .login(email: _email.text, password: _password.text);
    if (!success && mounted) {
      final message = ref.read(authControllerProvider).message;
      if (message != null) AppFeedback.show(context, message);
    }
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearFeedback();
    final success = await ref
        .read(authControllerProvider.notifier)
        .loginWithGoogle();
    if (!success && mounted) {
      final message = ref.read(authControllerProvider).message;
      if (message != null) AppFeedback.show(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandHeader(
                        title: 'Iniciar sesión',
                        subtitle: 'Entra para encontrar ayuda o administrar tus chambas.',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        key: const Key('login_email'),
                        controller: _email,
                        label: 'Correo electrónico',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        errorText: state.fieldErrors['email'],
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordField(
                        key: const Key('login_password'),
                        controller: _password,
                        label: 'Contraseña',
                        textInputAction: TextInputAction.done,
                        errorText: state.fieldErrors['password'],
                        validator: (value) => value == null || value.isEmpty
                            ? 'Escribe tu contraseña.'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (state.message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.message!,
                          key: const Key('login_error'),
                          style: const TextStyle(color: AppColors.danger),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        key: const Key('login_submit'),
                        label: 'Iniciar sesión',
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'o continúa con',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          key: const Key('login_google'),
                          onPressed: state.isSubmitting ? null : _submitGoogle,
                          icon: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          label: const Text('Continuar con Google'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => context.go('/register'),
                        child: const Text('¿No tienes cuenta? Crear cuenta'),
                      ),
                    ],
                  ),
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
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }
}
