import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      notificationControllerProvider.select(
        (state) => state.value?.unreadCount ?? 0,
      ),
    );
    return IconButton(
      tooltip: unread == 0
          ? 'Notificaciones'
          : '$unread notificaciones sin leer',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
