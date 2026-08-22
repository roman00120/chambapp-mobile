import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';

abstract interface class NotificationRepository {
  Future<NotificationPage> getNotifications({int page = 1});
  Future<AppNotification> markRead(String id);
  Future<void> markAllRead();
}
