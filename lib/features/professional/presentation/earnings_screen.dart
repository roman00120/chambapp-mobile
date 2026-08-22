import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(earningsSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: const SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 64),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Tus ganancias aparecerán aquí cuando completes trabajos pagados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Chambapp mostrará los importes confirmados por el servidor. La app no calcula totales financieros.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
