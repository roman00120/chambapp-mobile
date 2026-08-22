import 'package:chambapp_mobile/core/network/json_helpers.dart';

final class NotificationDestination {
  const NotificationDestination({required this.kind, required this.id});
  final String kind;
  final int id;

  factory NotificationDestination.fromJson(Map<String, dynamic> json) =>
      NotificationDestination(
        kind: json['kind']?.toString() ?? '',
        id: jsonInt(json['id']),
      );

  bool get safe => id > 0 && (kind == 'job' || kind == 'professional');
}

final class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.destination,
    this.readAt,
    this.createdAt,
  });
  final String id;
  final String type;
  final String title;
  final String message;
  final NotificationDestination? destination;
  final DateTime? readAt;
  final DateTime? createdAt;
  bool get unread => readAt == null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    destination: destination,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'] is Map
        ? NotificationDestination.fromJson(jsonMap(json['destination']))
        : null;
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'generic',
      title: json['title']?.toString() ?? 'Notificación',
      message: json['message']?.toString() ?? '',
      destination: destination?.safe == true ? destination : null,
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

final class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount});
  final List<AppNotification> items;
  final int unreadCount;
}
