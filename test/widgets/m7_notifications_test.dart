import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_repository.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_bell.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

const _unknown = AppNotification(
  id: 'unknown-1',
  type: 'new.backend.type',
  title: 'Nuevo aviso',
  message: 'Este tipo futuro sigue siendo legible.',
);

final class _NotificationFake implements NotificationRepository {
  int readCalls = 0;
  int readAllCalls = 0;

  @override
  Future<NotificationPage> getNotifications({int page = 1}) async =>
      const NotificationPage(items: [_unknown], unreadCount: 127);

  @override
  Future<AppNotification> markRead(String id) async {
    readCalls++;
    return AppNotification(
      id: id,
      type: _unknown.type,
      title: _unknown.title,
      message: _unknown.message,
      readAt: DateTime(2026, 8, 21),
    );
  }

  @override
  Future<void> markAllRead() async => readAllCalls++;
}

Future<ProviderContainer> _container(_NotificationFake repository) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      notificationRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await container
      .read(authControllerProvider.notifier)
      .login(email: 'ana@example.test', password: 'secret');
  return container;
}

Widget _app(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

void main() {
  testWidgets('campana muestra el unread_count global exacto', (tester) async {
    final repository = _NotificationFake();
    final container = await _container(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(
        container,
        Scaffold(appBar: AppBar(actions: const [NotificationBell()])),
      ),
    );
    await tester.pump();

    expect(find.text('127'), findsOneWidget);
    expect(find.byTooltip('127 notificaciones sin leer'), findsOneWidget);
  });

  testWidgets('tipo desconocido es legible y se puede marcar como leído', (
    tester,
  ) async {
    final repository = _NotificationFake();
    final container = await _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const NotificationsScreen()));
    await tester.pump();

    expect(find.text('Nuevo aviso'), findsOneWidget);
    expect(
      find.textContaining('Este tipo futuro sigue siendo legible.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Nuevo aviso'));
    await tester.pump();
    expect(repository.readCalls, 1);
    expect(
      container.read(notificationControllerProvider).value!.unreadCount,
      126,
    );

    await tester.tap(find.text('Marcar todas'));
    await tester.pump();
    expect(repository.readAllCalls, 1);
    expect(
      container.read(notificationControllerProvider).value!.unreadCount,
      0,
    );
  });
}
