import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/favorites/domain/favorite_repository.dart';
import 'package:chambapp_mobile/features/favorites/presentation/favorite_controller.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_repository.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';

const _unread = AppNotification(
  id: 'notification-1',
  type: 'future.unknown',
  title: 'Aviso',
  message: 'Tu cuenta tiene una actualización.',
  destination: NotificationDestination(kind: 'job', id: 12),
);

final class _Notifications implements NotificationRepository {
  int listCalls = 0;
  int readCalls = 0;
  int readAllCalls = 0;

  @override
  Future<NotificationPage> getNotifications({int page = 1}) async {
    listCalls++;
    return const NotificationPage(items: [_unread], unreadCount: 27);
  }

  @override
  Future<AppNotification> markRead(String id) async {
    readCalls++;
    return AppNotification(
      id: id,
      type: _unread.type,
      title: _unread.title,
      message: _unread.message,
      destination: _unread.destination,
      readAt: DateTime(2026, 8, 21),
    );
  }

  @override
  Future<void> markAllRead() async => readAllCalls++;
}

final class _Favorites implements FavoriteRepository {
  int listCalls = 0;

  @override
  Future<void> add(int professionalId) async {}

  @override
  Future<List<ProfessionalModel>> getFavorites() async {
    listCalls++;
    return const [testProfessional];
  }

  @override
  Future<void> remove(int professionalId) async {}
}

void main() {
  test('contador, lectura y marcar todas se sincronizan localmente', () async {
    final repository = _Notifications();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .login(email: 'ana@example.test', password: 'secret');

    expect(
      (await container.read(notificationControllerProvider.future)).unreadCount,
      27,
    );
    await container
        .read(notificationControllerProvider.notifier)
        .markRead(_unread);
    expect(
      container.read(notificationControllerProvider).value!.unreadCount,
      26,
    );
    expect(repository.readCalls, 1);
    await container.read(notificationControllerProvider.notifier).markAllRead();
    final state = container.read(notificationControllerProvider).value!;
    expect(state.unreadCount, 0);
    expect(state.items.single.unread, isFalse);
    expect(repository.readAllCalls, 1);
  });

  test(
    'logout limpia notificaciones y favoritos ligados a la cuenta',
    () async {
      final notifications = _Notifications();
      final favorites = _Favorites();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          notificationRepositoryProvider.overrideWithValue(notifications),
          favoriteRepositoryProvider.overrideWithValue(favorites),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(authControllerProvider.notifier)
          .login(email: 'ana@example.test', password: 'secret');
      expect(
        (await container.read(notificationControllerProvider.future)).items,
        isNotEmpty,
      );
      expect(
        await container.read(favoriteControllerProvider.future),
        isNotEmpty,
      );

      await container.read(authControllerProvider.notifier).logout();

      expect(
        (await container.read(notificationControllerProvider.future)).items,
        isEmpty,
      );
      expect(await container.read(favoriteControllerProvider.future), isEmpty);
      expect(notifications.listCalls, 1);
      expect(favorites.listCalls, 1);
    },
  );
}
