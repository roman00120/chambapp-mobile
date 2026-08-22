import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(
      authControllerProvider.select((state) => state.message),
    );
    return Scaffold(
      body: SafeArea(
        child: message != null
            ? ErrorState(
                title: 'No pudimos conectarnos',
                message: message,
                onRetry: ref
                    .read(authControllerProvider.notifier)
                    .restoreSession,
              )
            : Center(
                child: Semantics(
                  label: 'Verificando sesión',
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image(
                        image: AssetImage(
                          'assets/branding/chambapp-logo-current.jpeg',
                        ),
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Verificando tu sesión…'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
