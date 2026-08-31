import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/auth/domain/auth_repository.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_detail_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';

final class _CustomAuthRepository implements AuthRepository {
  _CustomAuthRepository(this.user);
  final User user;

  @override
  Future<AuthSession> login({required String email, required String password}) async =>
      AuthSession(token: 'test_token', user: user);

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async =>
      AuthSession(token: 'test_token', user: user);

  @override
  Future<AuthSession> register(RegistrationInput input) async =>
      AuthSession(token: 'test_token', user: user);

  @override
  Future<RegistrationRequirements> registrationRequirements(UserRole role) async =>
      testRegistrationRequirements;

  @override
  Future<User?> restoreSession() async => user;

  @override
  Future<User> me() async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> clearLocalSession() async {}
}

const _testPro = ProfessionalModel(
  id: 10,
  userId: 1, // User ID 1
  name: 'Roman Pro',
  rating: 5.0,
  totalReviews: 10,
  completedJobs: 5,
  verified: true,
);

final _awaitingPaymentJob = JobModel(
  id: 134,
  clientId: 6, // Client User ID 6
  professionalId: 10,
  title: 'Chamba Test',
  description: 'Reparacion',
  status: JobStatus.awaitingPayment,
  statusLabel: 'Esperando pago',
  agreedPrice: '50.00',
  currency: 'MXN',
  professional: _testPro,
  quotes: const [],
);

Future<ProviderContainer> _createContainer(User user) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_CustomAuthRepository(user)),
      jobRepositoryProvider.overrideWithValue(
        FakeJobRepository(statuses: [
          const JobStatusModel(status: JobStatus.awaitingPayment, label: 'Esperando pago'),
        ])..job = _awaitingPaymentJob,
      ),
      jobDetailProvider(134).overrideWith((ref) async => _awaitingPaymentJob),
      jobQuotesProvider(134).overrideWith((ref) async => const []),
    ],
  );
  await container.read(authControllerProvider.notifier).login(email: 'test@example.com', password: 'secret');
  return container;
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.light,
    home: const JobDetailScreen(jobId: 134),
  ),
);

void main() {
  testWidgets('A) role professional + activeMode client + clientId coincide -> Pagar Chamba', (tester) async {
    const proWithClientModeUser = User(
      id: 6,
      name: 'Pro en modo cliente',
      role: UserRole.professional,
      activeMode: 'client',
    );

    final container = await _createContainer(proWithClientModeUser);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Pagar Chamba'), findsWidgets);
    expect(find.text('Esperando confirmación del pago del cliente.'), findsNothing);
  });

  testWidgets('B) role admin + activeMode client + clientId coincide -> Pagar Chamba', (tester) async {
    const adminWithClientModeUser = User(
      id: 6,
      name: 'Admin en modo cliente',
      role: UserRole.admin,
      activeMode: 'client',
    );

    final container = await _createContainer(adminWithClientModeUser);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Pagar Chamba'), findsWidgets);
    expect(find.text('Esperando confirmación del pago del cliente.'), findsNothing);
  });

  testWidgets('C) role client + clientId coincide -> Pagar Chamba', (tester) async {
    const clientUser = User(
      id: 6,
      name: 'Cliente normal',
      role: UserRole.client,
    );

    final container = await _createContainer(clientUser);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Pagar Chamba'), findsWidgets);
    expect(find.text('Esperando confirmación del pago del cliente.'), findsNothing);
  });

  testWidgets('D) professional asignado (userId == 1) -> no Pagar Chamba y muestra Esperando confirmacion', (tester) async {
    const assignedProUser = User(
      id: 1, // Matches professional.userId
      name: 'Roman Pro Asignado',
      role: UserRole.professional,
    );

    final container = await _createContainer(assignedProUser);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Esperando confirmación del pago del cliente.'), findsOneWidget);
    expect(find.text('Pagar Chamba'), findsNothing);
  });

  testWidgets('E) usuario ajeno -> no Pagar Chamba', (tester) async {
    const thirdPartyPro = User(
      id: 99,
      name: 'Tercero',
      role: UserRole.professional,
    );

    final container = await _createContainer(thirdPartyPro);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Pagar Chamba'), findsNothing);
  });
}
