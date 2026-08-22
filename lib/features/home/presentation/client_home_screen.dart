import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/category_grid.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/service_card.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_bell.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    final categories = ref.watch(categoriesProvider);
    final services = ref.watch(servicesProvider(const ServiceSearchQuery()));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chambapp',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Mi perfil',
            onPressed: () => context.go('/client/profile'),
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.navy,
              child: Text(
                user.name.trim().isEmpty
                    ? 'C'
                    : user.name.trim()[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(servicesProvider(const ServiceSearchQuery()));
            await Future.wait([
              ref.read(categoriesProvider.future),
              ref.read(servicesProvider(const ServiceSearchQuery()).future),
            ]);
          },
          child: ListView(
            key: const Key('client_home'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '¿Qué necesitas hoy?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Encuentra profesionales cerca de ti.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                readOnly: true,
                onTap: () => context.go('/client/search'),
                decoration: const InputDecoration(
                  hintText: 'Buscar servicio o profesional',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      key: const Key('home_immediate'),
                      icon: Icons.bolt,
                      title: 'Ahora',
                      subtitle:
                          'Encuentra un profesional disponible cerca de ti.',
                      color: AppColors.amber,
                      onTap: () => context.push('/request/immediate'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionCard(
                      key: const Key('home_scheduled'),
                      icon: Icons.calendar_month_outlined,
                      title: 'Programar',
                      subtitle: 'Agenda una chamba para otro momento.',
                      color: AppColors.navy,
                      onTap: () => context.push('/request/scheduled'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Categorías', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              categories.when(
                data: (items) => CategoryGrid(
                  categories: items,
                  onTap: (category) =>
                      context.go('/client/search?category=${category.slug}'),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => ErrorState(
                  title: 'No cargaron las categorías',
                  message: error,
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Servicios destacados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              services.when(
                data: (items) => items.isEmpty
                    ? const Text('Aún no hay servicios disponibles.')
                    : Column(
                        children: items
                            .take(4)
                            .map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: ServiceCard(
                                  service: service,
                                  onTap: () =>
                                      context.push('/services/${service.id}'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    const Text('No pudimos cargar los servicios.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = color == AppColors.navy ? Colors.white : AppColors.navy;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 174),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: TextStyle(color: foreground, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
