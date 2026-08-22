import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({this.service, super.key});
  final ProfessionalServiceModel? service;
  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  int? _categoryId;
  late ProfessionalPriceType _priceType;
  final List<XFile> _images = [];
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get editing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _title = TextEditingController(text: service?.title);
    _description = TextEditingController(text: service?.description);
    _price = TextEditingController(text: service?.price);
    _categoryId = service?.category?.id;
    _priceType = service?.priceType ?? ProfessionalPriceType.fixed;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar servicio' : 'Crear servicio'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    const Text('No pudimos cargar las categorías.'),
                data: (items) => DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    errorText: _fieldErrors['category_id'],
                  ),
                  items: items
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona una categoría.' : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _title,
                label: 'Título',
                errorText: _fieldErrors['title'],
                validator: (value) => (value?.trim().length ?? 0) < 5
                    ? 'Escribe al menos 5 caracteres.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _description,
                label: 'Descripción',
                maxLines: 5,
                errorText: _fieldErrors['description'],
                validator: (value) => (value?.trim().length ?? 0) < 20
                    ? 'Describe tu servicio con al menos 20 caracteres.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ProfessionalPriceType>(
                initialValue: _priceType,
                decoration: InputDecoration(
                  labelText: 'Tipo de precio',
                  errorText: _fieldErrors['price_type'],
                ),
                items: ProfessionalPriceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) =>
                          setState(() => _priceType = value ?? _priceType),
              ),
              if (_priceType != ProfessionalPriceType.quote) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _price,
                  label: 'Precio (MXN)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,8}([.]\d{0,2})?'),
                    ),
                  ],
                  errorText: _fieldErrors['price'],
                  validator: (value) =>
                      double.tryParse(value?.trim() ?? '') == null
                      ? 'Escribe un precio válido.'
                      : null,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _submitting || _images.length >= 5
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _images.isEmpty
                      ? 'Agregar imágenes'
                      : '${_images.length} imagen(es) seleccionada(s)',
                ),
              ),
              const Text('JPEG, PNG o WebP. Máximo 5 imágenes de 4 MB.'),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Chambapp cobra una comisión del 15% sobre trabajos pagados dentro de la plataforma.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: editing ? 'Guardar cambios' : 'Publicar servicio',
                isLoading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final selected = await ImagePicker().pickMultiImage(
      imageQuality: 90,
      limit: 5 - _images.length,
    );
    for (final file in selected) {
      final extension = file.name.split('.').last.toLowerCase();
      final allowed = {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
      if (!allowed || await file.length() > 4 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file.name} no cumple tipo o tamaño permitido.'),
            ),
          );
        }
        continue;
      }
      _images.add(file);
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });
    final input = ProfessionalServiceInput(
      categoryId: _categoryId!,
      title: _title.text,
      description: _description.text,
      priceType: _priceType,
      price: _price.text,
      imagePaths: _images.map((file) => file.path).toList(),
    );
    try {
      final controller = ref.read(professionalServicesProvider.notifier);
      if (editing) {
        await controller.updateService(widget.service!.id, input);
      } else {
        await controller.create(input);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing ? 'Servicio actualizado.' : 'Servicio publicado.',
            ),
          ),
        );
        context.pop();
      }
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _fieldErrors = error.fieldErrors);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar el servicio.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
