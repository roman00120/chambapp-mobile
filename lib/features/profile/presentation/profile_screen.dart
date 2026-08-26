import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_bell.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state.user!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                child: Text(
                  _initials(user.name),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(user.role.label, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: user.email ?? 'No disponible en la API',
                    ),
                    if (user.phone != null) ...[
                      const Divider(height: AppSpacing.lg),
                      _ProfileRow(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: user.phone!,
                      ),
                    ],
                    const Divider(height: AppSpacing.lg),
                    _ProfileRow(
                      icon: Icons.badge_outlined,
                      label: 'Tipo de cuenta',
                      value: user.role.label,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (user.role.apiValue == 'client') ...[
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.work_outline),
                      title: const Text('Mis chambas'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/client/jobs'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite_outline),
                      title: const Text('Favoritos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/client/favorites'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (user.canActAsProfessional) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz, color: AppColors.navy),
                  title: const Text(
                    'Cambiar a modo profesional',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Ver solicitudes, servicios y pagos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref
                        .read(authControllerProvider.notifier)
                        .switchActiveMode('professional');
                    context.go('/professional/home');
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (user.isAdmin) ...[
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.shield_outlined,
                    color: Colors.amber,
                  ),
                  title: const Text(
                    'Panel de administración',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/home'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            PrimaryButton(
              key: const Key('logout_button'),
              label: 'Cerrar sesión',
              isLoading: state.isSubmitting,
              onPressed: ref.read(authControllerProvider.notifier).logout,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.navy),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}
