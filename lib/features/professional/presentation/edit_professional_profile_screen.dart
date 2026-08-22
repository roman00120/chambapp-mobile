import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfessionalProfileScreen extends ConsumerStatefulWidget {
  const EditProfessionalProfileScreen({super.key});
  @override
  ConsumerState<EditProfessionalProfileScreen> createState() =>
      _EditProfessionalProfileScreenState();
}

class _EditProfessionalProfileScreenState
    extends ConsumerState<EditProfessionalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _experience = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  bool _initialized = false;
  bool _submitting = false;
  XFile? _photo;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _bio,
      _experience,
      _city,
      _state,
      _postalCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(professionalProfileProvider);
    final user = ref.watch(authControllerProvider).user!;
    final value = profile.value;
    if (!_initialized && value != null) {
      _initialized = true;
      _name.text = value.name;
      _phone.text = user.phone ?? '';
      _bio.text = value.bio ?? '';
      _experience.text = '${value.experienceYears ?? 0}';
      _city.text = value.city ?? '';
      _state.text = value.state ?? '';
      _postalCode.text = value.postalCode ?? '';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        top: false,
        child: value == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        _photo == null
                            ? 'Cambiar foto de perfil'
                            : _photo!.name,
                      ),
                    ),
                    const Text('JPEG, PNG o WebP. Máximo 2 MB.'),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _name,
                      label: 'Nombre',
                      errorText: _errors['name'],
                      onChanged: (_) => _clearError('name'),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Escribe tu nombre.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _phone,
                      label: 'Teléfono',
                      keyboardType: TextInputType.phone,
                      errorText: _errors['phone'],
                      onChanged: (_) => _clearError('phone'),
                      validator: (value) => (value?.trim().length ?? 0) < 10
                          ? 'Escribe un teléfono válido.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _bio,
                      label: 'Descripción profesional',
                      maxLines: 5,
                      errorText: _errors['bio'],
                      onChanged: (_) => _clearError('bio'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _experience,
                      label: 'Años de experiencia',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorText: _errors['experience_years'],
                      onChanged: (_) => _clearError('experience_years'),
                      validator: (value) {
                        final years = int.tryParse(value ?? '');
                        return years == null || years < 0 || years > 60
                            ? 'Ingresa un valor entre 0 y 60.'
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _city,
                      label: 'Ciudad',
                      errorText: _errors['city'],
                      onChanged: (_) => _clearError('city'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _state,
                      label: 'Estado',
                      errorText: _errors['state'],
                      onChanged: (_) => _clearError('state'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _postalCode,
                      label: 'Código postal',
                      errorText: _errors['postal_code'],
                      onChanged: (_) => _clearError('postal_code'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Guardar perfil',
                      isLoading: _submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _clearError(String field) {
    if (_errors.containsKey(field)) {
      setState(() {
        final next = Map<String, String>.from(_errors);
        next.remove(field);
        _errors = next;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (photo == null) return;
    final extension = photo.name.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension) ||
        await photo.length() > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen no cumple el tipo o tamaño permitido.'),
          ),
        );
      }
      return;
    }
    setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errors = const {};
    });
    try {
      await ref
          .read(professionalProfileProvider.notifier)
          .saveProfile(
            ProfessionalProfileInput(
              name: _name.text,
              phone: _phone.text,
              experienceYears: int.parse(_experience.text),
              bio: _bio.text,
              city: _city.text,
              state: _state.text,
              postalCode: _postalCode.text,
              photoPath: _photo?.path,
            ),
          );
      final result = ref.read(professionalProfileProvider);
      if (result.hasError) throw result.error!;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
        context.pop();
      }
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _errors = error.fieldErrors);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos actualizar el perfil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
