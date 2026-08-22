import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: notifications.value?.unreadCount == 0
                ? null
                : ref.read(notificationControllerProvider.notifier).markAllRead,
            child: const Text('Marcar todas'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos cargar tus notificaciones',
            message: error,
            onRetry: ref.read(notificationControllerProvider.notifier).refresh,
          ),
          data: (page) => page.items.isEmpty
              ? const Center(child: Text('No tienes notificaciones.'))
              : RefreshIndicator(
                  onRefresh: ref
                      .read(notificationControllerProvider.notifier)
                      .refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) {
                      final item = page.items[index];
                      return Card(
                        color: item.unread
                            ? AppColors.amber.withValues(alpha: .1)
                            : null,
                        child: ListTile(
                          leading: Icon(_icon(item.type)),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.unread
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${item.message}${item.createdAt == null ? '' : '\n${_date(item.createdAt!)}'}',
                          ),
                          isThreeLine: item.createdAt != null,
                          trailing: item.unread
                              ? Semantics(
                                  label: 'No leída',
                                  child: const Icon(Icons.circle, size: 10),
                                )
                              : null,
                          onTap: () => _open(item),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _open(AppNotification notification) async {
    await ref
        .read(notificationControllerProvider.notifier)
        .markRead(notification);
    if (!mounted) return;
    switch (notification.destination?.kind) {
      case 'job':
        context.push('/jobs/${notification.destination!.id}');
      case 'professional':
        context.push('/professionals/${notification.destination!.id}');
      default:
        break;
    }
  }
}

IconData _icon(String type) {
  if (type.contains('payment')) return Icons.payments_outlined;
  if (type.contains('quote')) return Icons.request_quote_outlined;
  if (type.contains('review')) return Icons.star_outline;
  if (type.contains('job')) return Icons.work_outline;
  return Icons.notifications_outlined;
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
