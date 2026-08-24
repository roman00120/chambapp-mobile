import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AdminSection {
  categories('categories', 'Categorías', Icons.category_outlined),
  services('services', 'Servicios', Icons.home_repair_service_outlined),
  jobs('jobs', 'Chambas', Icons.work_outline),
  payments('payments', 'Pagos', Icons.payments_outlined),
  commissions(
    'commissions',
    'Comisiones',
    Icons.account_balance_wallet_outlined,
  ),
  reports('reports', 'Reportes', Icons.flag_outlined),
  reviews('reviews', 'Reseñas', Icons.star_outline),
  disputes('disputes', 'Disputas', Icons.gavel_outlined);

  const AdminSection(this.api, this.label, this.icon);
  final String api;
  final String label;
  final IconData icon;
}

final class AdminOperationItem {
  const AdminOperationItem(this.data);
  final Map<String, dynamic> data;
  int get id => (data['id'] as num).toInt();
  String get title => data['title']?.toString() ?? '';
  String get subtitle => data['subtitle']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

final class AdminOperationFeed {
  const AdminOperationFeed(this.items, this.summary);
  final List<AdminOperationItem> items;
  final Map<String, dynamic> summary;
}

final class AdminOperationsRepository {
  const AdminOperationsRepository(this._dio);
  final Dio _dio;

  Future<AdminOperationFeed> list(AdminSection section) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/operations/${section.api}',
      );
      final body = response.data!;
      return AdminOperationFeed(
        (body['data'] as List)
            .map(
              (item) =>
                  AdminOperationItem(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
        body['summary'] is Map
            ? Map<String, dynamic>.from(body['summary'] as Map)
            : const {},
      );
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }

  Future<void> action(
    AdminSection section,
    int id,
    String action, {
    String? reason,
  }) async {
    try {
      switch (section) {
        case AdminSection.categories:
          await _dio.patch<void>('/admin/categories/$id/toggle');
        case AdminSection.services:
          await _dio.patch<void>(
            '/admin/services/$id/moderate',
            data: {'action': action},
          );
        case AdminSection.reports:
          await _dio.patch<void>(
            '/admin/reports/$id/status',
            data: {'status': action},
          );
        case AdminSection.reviews:
          await _dio.patch<void>(
            '/admin/reviews/$id/moderate',
            data: {'action': action, 'reason': ?reason},
          );
        case AdminSection.disputes:
          await _dio.patch<void>(
            '/admin/disputes/$id/status',
            data: {'status': action},
          );
        case AdminSection.jobs ||
            AdminSection.payments ||
            AdminSection.commissions:
          return;
      }
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }

  Future<void> saveCategory({
    int? id,
    required String name,
    required String description,
    required int sortOrder,
    required bool active,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'sort_order': sortOrder,
        'is_active': active,
      };
      if (id == null) {
        await _dio.post<void>('/admin/categories', data: data);
      } else {
        await _dio.put<void>('/admin/categories/$id', data: data);
      }
    } catch (error) {
      throw const ApiErrorMapper().map(error);
    }
  }
}

final adminOperationsRepositoryProvider = Provider<AdminOperationsRepository>(
  (ref) => AdminOperationsRepository(ref.watch(dioProvider)),
);
final adminOperationsProvider =
    FutureProvider.family<AdminOperationFeed, AdminSection>(
      (ref, section) =>
          ref.watch(adminOperationsRepositoryProvider).list(section),
    );

class AdminOperationsScreen extends ConsumerStatefulWidget {
  const AdminOperationsScreen({super.key});
  @override
  ConsumerState<AdminOperationsScreen> createState() =>
      _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends ConsumerState<AdminOperationsScreen> {
  AdminSection section = AdminSection.categories;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOperationsProvider(section));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión'),
        actions: [
          if (section == AdminSection.categories)
            IconButton(
              onPressed: () => _categoryDialog(),
              icon: const Icon(Icons.add),
            ),
          IconButton(
            onPressed: () => ref.invalidate(adminOperationsProvider(section)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: DropdownButtonFormField<AdminSection>(
              initialValue: section,
              decoration: const InputDecoration(
                labelText: 'Sección administrativa',
              ),
              items: AdminSection.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(value.icon),
                          const SizedBox(width: 10),
                          Text(value.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                section = value ?? section;
                query = '';
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar en esta sección',
              ),
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error', textAlign: TextAlign.center),
                ),
              ),
              data: (feed) {
                final items = feed.items
                    .where(
                      (item) =>
                          query.isEmpty ||
                          item.title.toLowerCase().contains(query) ||
                          item.subtitle.toLowerCase().contains(query),
                    )
                    .toList();
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(adminOperationsProvider(section).future),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (section == AdminSection.commissions)
                        _CommissionSummary(feed.summary),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: Text('No hay registros.')),
                        ),
                      for (final item in items)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Icon(section.icon)),
                            title: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${item.subtitle}\n${_status(item.status)}',
                              maxLines: 3,
                            ),
                            isThreeLine: true,
                            onTap: () => _details(item),
                            trailing: _actions(item),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _actions(AdminOperationItem item) {
    final actions = switch (section) {
      AdminSection.categories => ['toggle'],
      AdminSection.services => [
        'activate',
        'deactivate',
        'feature',
        'unfeature',
      ],
      AdminSection.reports => ['reviewing', 'resolved', 'dismissed'],
      AdminSection.reviews => item.status == 'hidden' ? ['restore'] : ['hide'],
      AdminSection.disputes => ['reviewing', 'resolved', 'rejected'],
      _ => <String>[],
    };
    if (actions.isEmpty) return const Icon(Icons.chevron_right);
    return PopupMenuButton<String>(
      onSelected: (action) =>
          section == AdminSection.categories && action == 'toggle'
          ? _run(item, action)
          : section == AdminSection.reviews && action == 'hide'
          ? _reasonAndRun(item, action)
          : _run(item, action),
      itemBuilder: (_) => [
        for (final action in actions)
          PopupMenuItem(value: action, child: Text(_action(action))),
      ],
    );
  }

  Future<void> _run(
    AdminOperationItem item,
    String action, {
    String? reason,
  }) async {
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .action(section, item.id, action, reason: reason);
      ref.invalidate(adminOperationsProvider(section));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cambio guardado.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _reasonAndRun(AdminOperationItem item, String action) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Motivo de moderación'),
        content: TextField(controller: controller, maxLines: 3, maxLength: 500),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && mounted) await _run(item, action, reason: reason);
  }

  Future<void> _categoryDialog([AdminOperationItem? item]) async {
    final name = TextEditingController(text: item?.title);
    final description = TextEditingController();
    final order = TextEditingController(
      text: item?.data['sort_order']?.toString() ?? '0',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Nueva categoría' : 'Editar categoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextField(
                controller: order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Orden'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await ref
            .read(adminOperationsRepositoryProvider)
            .saveCategory(
              id: item?.id,
              name: name.text.trim(),
              description: description.text.trim(),
              sortOrder: int.tryParse(order.text) ?? 0,
              active: item?.status != 'inactive',
            );
        ref.invalidate(adminOperationsProvider(section));
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
    name.dispose();
    description.dispose();
    order.dispose();
  }

  void _details(AdminOperationItem item) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(item.subtitle),
            const SizedBox(height: 8),
            Chip(label: Text(_status(item.status))),
            if (section == AdminSection.payments ||
                section == AdminSection.commissions) ...[
              Text('Precio base: \$${item.data['base_amount'] ?? '0.00'}'),
              Text(
                'Cargo cliente: \$${item.data['client_service_fee'] ?? '0.00'}',
              ),
              Text(
                'Comisión profesional: \$${item.data['professional_commission'] ?? '0.00'}',
              ),
              Text('Total cliente: \$${item.data['customer_total'] ?? '0.00'}'),
              Text(
                'Ingreso bruto plataforma: \$${item.data['platform_gross_fee'] ?? '0.00'}',
              ),
              Text(
                'Profesional antes de costos: \$${item.data['professional_amount_before_external_costs'] ?? '0.00'}',
              ),
              Text(
                'Costo proveedor: \$${item.data['provider_fee'] ?? 'No informado'}',
              ),
              Text('Reembolso: \$${item.data['refunded_amount'] ?? '0.00'}'),
            ],
            if (section == AdminSection.categories)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _categoryDialog(item);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CommissionSummary extends StatelessWidget {
  const _CommissionSummary(this.summary);
  final Map<String, dynamic> summary;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de cargos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('Total cobrado: \$${summary['gross'] ?? '0.00'}'),
          Text('Ingreso bruto plataforma: \$${summary['fees'] ?? '0.00'}'),
          Text('Profesionales: \$${summary['professional_amount'] ?? '0.00'}'),
        ],
      ),
    ),
  );
}

String _status(String value) => switch (value) {
  'active' => 'Activo',
  'inactive' => 'Inactivo',
  'pending' => 'Pendiente',
  'reviewing' => 'En revisión',
  'resolved' => 'Resuelto',
  'dismissed' => 'Descartado',
  'rejected' => 'Rechazado',
  'hidden' => 'Oculto',
  'visible' => 'Visible',
  'approved' => 'Aprobado',
  _ => value.replaceAll('_', ' '),
};
String _action(String value) => switch (value) {
  'toggle' => 'Cambiar estado',
  'activate' => 'Activar',
  'deactivate' => 'Desactivar',
  'feature' => 'Destacar',
  'unfeature' => 'Quitar destacado',
  'reviewing' => 'Marcar en revisión',
  'resolved' => 'Resolver',
  'dismissed' => 'Descartar',
  'rejected' => 'Rechazar',
  'hide' => 'Ocultar',
  'restore' => 'Restaurar',
  _ => value,
};
