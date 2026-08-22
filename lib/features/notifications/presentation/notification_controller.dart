import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/notifications/data/notification_repository_impl.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) =>
      ApiNotificationRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationPage>(
      NotificationController.new,
    );

final class NotificationController extends AsyncNotifier<NotificationPage> {
  @override
  Future<NotificationPage> build() async {
    final userId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    if (userId == null) {
      return const NotificationPage(items: [], unreadCount: 0);
    }
    return ref.watch(notificationRepositoryProvider).getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(notificationRepositoryProvider).getNotifications,
    );
  }

  Future<void> markRead(AppNotification notification) async {
    if (!notification.unread) return;
    final updated = await ref
        .read(notificationRepositoryProvider)
        .markRead(notification.id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      NotificationPage(
        items: current.items
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
        unreadCount: (current.unreadCount - 1).clamp(0, 1 << 31),
      ),
    );
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    final current = state.value;
    if (current == null) return;
    final now = DateTime.now();
    state = AsyncData(
      NotificationPage(
        items: current.items.map((item) => item.copyWith(readAt: now)).toList(),
        unreadCount: 0,
      ),
    );
  }
}
