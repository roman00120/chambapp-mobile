import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class JobWizardShell extends StatelessWidget {
  const JobWizardShell({
    required this.title,
    required this.step,
    required this.stepCount,
    required this.child,
    required this.onNext,
    this.onBack,
    this.loading = false,
    this.nextLabel = 'Continuar',
    super.key,
  });
  final String title;
  final int step;
  final int stepCount;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool loading;
  final String nextLabel;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(value: (step + 1) / stepCount),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text('Paso ${step + 1} de $stepCount'),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (onBack != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : onBack,
                      child: const Text('Atrás'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    key: const Key('wizard_next'),
                    label: nextLabel,
                    onPressed: onNext,
                    isLoading: loading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
