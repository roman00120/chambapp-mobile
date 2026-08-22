import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.prefixIcon,
    this.prefixText,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final String? prefixText;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    focusNode: focusNode,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onFieldSubmitted,
    maxLines: maxLines,
    maxLength: maxLength,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      prefixText: prefixText,
      hintText: hint,
    ),
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.errorText,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _obscure,
    textInputAction: widget.textInputAction,
    autofillHints: const [AutofillHints.password],
    validator: widget.validator,
    onChanged: widget.onChanged,
    onFieldSubmitted: widget.onFieldSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.errorText,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
