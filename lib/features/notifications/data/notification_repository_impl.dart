import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_repository.dart';
import 'package:dio/dio.dart';

final class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<NotificationPage> getNotifications({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'page': page},
      );
      final data = response.data ?? const <String, dynamic>{};
      return NotificationPage(
        items: jsonList(data['data']).map(AppNotification.fromJson).toList(),
        unreadCount: jsonInt(jsonMap(data['meta'])['unread_count']),
      );
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<AppNotification> markRead(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/notifications/$id/read',
      );
      return AppNotification.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.post<void>('/notifications/read-all');
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
