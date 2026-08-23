import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        label: 'Chambapp',
        child: ExcludeSemantics(
          child: Image.asset(
            'assets/branding/chambapp-logo.png',
            width: 164,
            height: 86,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}
