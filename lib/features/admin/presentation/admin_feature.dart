import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class AdminDashboard {
  const AdminDashboard(this.data);
  final Map<String, dynamic> data;
  int count(String key) => (data[key] as num?)?.toInt() ?? 0;
  String amount(String key) => data[key]?.toString() ?? '0.00';
}

final class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;

  factory AdminUserItem.fromJson(Map<String, dynamic> json) => AdminUserItem(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
  );
}

final class AdminProfessionalItem {
  const AdminProfessionalItem({
    required this.id,
    required this.name,
    required this.email,
    required this.city,
    required this.status,
    required this.services,
  });
  final int id;
  final String name;
  final String email;
  final String city;
  final String status;
  final int services;

  factory AdminProfessionalItem.fromJson(Map<String, dynamic> json) =>
      AdminProfessionalItem(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        city: json['city']?.toString() ?? 'Sin ciudad',
        status: json['verification_status']?.toString() ?? '',
        services: (json['active_services_count'] as num?)?.toInt() ?? 0,
      );
}

final class AdminRepository {
  const AdminRepository(this._dio);
  final Dio _dio;

  Future<AdminDashboard> dashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/dashboard');
      return AdminDashboard(
        Map<String, dynamic>.from(response.data!['data'] as Map),
      );
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }

  Future<List<AdminUserItem>> users() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/users');
      return (response.data!['data'] as List)
          .map(
            (item) =>
                AdminUserItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }

  Future<void> updateUserStatus(int id, String status) async {
    try {
      await _dio.patch<void>(
        '/admin/users/$id/status',
        data: {'status': status},
      );
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }

  Future<List<AdminProfessionalItem>> professionals() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/professionals',
      );
      return (response.data!['data'] as List)
          .map(
            (item) => AdminProfessionalItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }

  Future<void> verifyProfessional(
    int id,
    String status, {
    String? reason,
  }) async {
    try {
      await _dio.patch<void>(
        '/admin/professionals/$id/verification',
        data: {'status': status, 'reason': ?reason},
      );
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);
final adminDashboardProvider = FutureProvider<AdminDashboard>(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
);
final adminUsersProvider = FutureProvider<List<AdminUserItem>>(
  (ref) => ref.watch(adminRepositoryProvider).users(),
);
final adminProfessionalsProvider = FutureProvider<List<AdminProfessionalItem>>(
  (ref) => ref.watch(adminRepositoryProvider).professionals(),
);

class AdminShell extends StatelessWidget {
  const AdminShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Resumen',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Usuarios',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified),
          label: 'Verificar',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: 'Gestión',
        ),
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Cuenta',
        ),
      ],
    ),
  );
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(
          error: error,
          retry: () => ref.invalidate(adminDashboardProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminDashboardProvider.future),
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
            childAspectRatio: 1.25,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _Metric('Usuarios', data.count('users'), Icons.people),
              _Metric('Clientes', data.count('clients'), Icons.person),
              _Metric(
                'Profesionales',
                data.count('professionals'),
                Icons.handyman,
              ),
              _Metric(
                'Por verificar',
                data.count('pending_verifications'),
                Icons.pending_actions,
              ),
              _Metric(
                'Servicios activos',
                data.count('active_services'),
                Icons.home_repair_service,
              ),
              _Metric(
                'Chambas activas',
                data.count('in_progress_jobs'),
                Icons.work,
              ),
              _Metric(
                'Disputas abiertas',
                data.count('open_disputes'),
                Icons.gavel,
              ),
              _Metric(
                'Reportes pendientes',
                data.count('pending_reports'),
                Icons.flag,
              ),
              _AmountMetric('Comisiones', data.amount('platform_fees')),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminUsersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(
          error: error,
          retry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (users) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminUsersProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    '${user.email}\n${_role(user.role)} · ${_userStatus(user.status)}',
                  ),
                  isThreeLine: true,
                  trailing: user.role == 'admin'
                      ? const Icon(Icons.shield)
                      : PopupMenuButton<String>(
                          onSelected: (status) =>
                              _changeUserStatus(context, ref, user, status),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'active',
                              child: Text('Activar'),
                            ),
                            PopupMenuItem(
                              value: 'suspended',
                              child: Text('Suspender'),
                            ),
                            PopupMenuItem(
                              value: 'blocked',
                              child: Text('Bloquear'),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _changeUserStatus(
    BuildContext context,
    WidgetRef ref,
    AdminUserItem user,
    String status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cambio'),
        content: Text(
          '¿Cambiar a ${_userStatus(status)} la cuenta de ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(adminRepositoryProvider).updateUserStatus(user.id, status);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Estado actualizado.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class AdminProfessionalsScreen extends ConsumerWidget {
  const AdminProfessionalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProfessionalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesionales'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminProfessionalsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(
          error: error,
          retry: () => ref.invalidate(adminProfessionalsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminProfessionalsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${item.email}\n${item.city} · ${item.services} servicios',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(label: Text(_verification(item.status))),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _reject(context, ref, item),
                            child: const Text('Rechazar'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () =>
                                _verify(context, ref, item, 'verified'),
                            child: const Text('Aprobar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _verify(
    BuildContext context,
    WidgetRef ref,
    AdminProfessionalItem item,
    String status, {
    String? reason,
  }) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .verifyProfessional(item.id, status, reason: reason);
      ref.invalidate(adminProfessionalsProvider);
      ref.invalidate(adminDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verificación actualizada.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    AdminProfessionalItem item,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Motivo del rechazo'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Indica qué debe corregir',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && context.mounted) {
      await _verify(context, ref, item, 'rejected', reason: reason);
    }
  }
}

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta administrativa')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.admin_panel_settings, size: 88),
          const SizedBox(height: 12),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(user.email ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Administrador'),
              subtitle: Text('Acceso protegido y acciones auditadas'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: auth.isSubmitting
                ? null
                : ref.read(authControllerProvider.notifier).logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _AmountMetric extends StatelessWidget {
  const _AmountMetric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payments_outlined),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              '\$$value',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Text(label),
        ],
      ),
    ),
  );
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _role(String value) => switch (value) {
  'admin' => 'Administrador',
  'professional' => 'Profesional',
  _ => 'Cliente',
};
String _userStatus(String value) => switch (value) {
  'active' => 'Activo',
  'suspended' => 'Suspendido',
  'blocked' => 'Bloqueado',
  _ => value,
};
String _verification(String value) => switch (value) {
  'verified' => 'Verificado',
  'pending' => 'Pendiente',
  'rejected' => 'Rechazado',
  _ => 'Sin verificar',
};
