import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/auth/domain/auth_repository.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/checkout_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_detail_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';
import 'm5_screens_test.dart';

const catalogService = ServiceModel(
  id: 99,
  title: 'Mantenimiento de Boiler',
  description: 'Revisión y limpieza completa.',
  price: '800.00',
  priceType: 'fixed',
  currency: 'MXN',
  category: CategoryModel(id: 1, name: 'Plomería', slug: 'plomeria'),
  professional: ProfessionalModel(
    id: 5,
    name: 'Mario Plomero',
    rating: 4.8,
    totalReviews: 10,
    completedJobs: 15,
    verified: true,
    userId: 20,
  ),
);

const directJobAwaitingPayment = JobModel(
  id: 42,
  clientId: 1,
  title: 'Mantenimiento de Boiler',
  description: 'Revisión y limpieza completa.',
  status: JobStatus.awaitingPayment,
  statusLabel: 'Esperando pago',
  service: catalogService,
  agreedPrice: '800.00',
  currency: 'MXN',
  economicBreakdown: EconomicBreakdown(
    economicModelVersion: 'client_15_professional_15',
    baseAmount: '800.00',
    currency: 'MXN',
    clientServiceFeePercent: '15.00',
    clientServiceFee: '120.00',
    customerTotal: '920.00',
  ),
  professional: ProfessionalModel(
    id: 5,
    name: 'Mario Plomero',
    rating: 4.8,
    totalReviews: 10,
    completedJobs: 15,
    verified: true,
    userId: 20,
  ),
);

final class CustomAuthRepository implements AuthRepository {
  CustomAuthRepository(this.user);
  final User user;

  @override
  Future<AuthSession> login({required String email, required String password}) async =>
      AuthSession(token: 'token', user: user);

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async =>
      AuthSession(token: 'token', user: user);

  @override
  Future<AuthSession> register(RegistrationInput input) async =>
      AuthSession(token: 'token', user: user);

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

Future<ProviderContainer> createTestContainer({
  required JobModel job,
  required User user,
}) async {
  final jobs = FakeJobRepository()..job = job;
  final payments = FakePaymentRepository();
  final authRepo = CustomAuthRepository(user);

  final container = ProviderContainer(
    overrides: [
      jobRepositoryProvider.overrideWithValue(jobs),
      paymentRepositoryProvider.overrideWithValue(payments),
      authRepositoryProvider.overrideWithValue(authRepo),
    ],
  );

  await container.read(authControllerProvider.notifier).login(
    email: user.email ?? 'test@example.com',
    password: 'secret',
  );

  return container;
}

Widget buildWrapper(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

void main() {
  testWidgets('A & K) Cliente normal ve Confirmar contratacion, precio base, desglose y Pagar Chamba sin moneda vacia', (
    tester,
  ) async {
    const clientUser = User(
      id: 1,
      name: 'Carlos Cliente',
      email: 'carlos@test.com',
      role: UserRole.client,
      activeMode: 'client',
    );

    final container = await createTestContainer(
      job: directJobAwaitingPayment,
      user: clientUser,
    );
    addTearDown(container.dispose);

    // Render CheckoutScreen
    await tester.pumpWidget(
      buildWrapper(container, const CheckoutScreen(jobId: 42)),
    );
    await tester.pumpAndSettle();

    // Verificaciones de UI de checkout
    expect(find.text('Confirmar contratación'), findsOneWidget);
    expect(find.text(r'Precio base: $800.00 MXN'), findsOneWidget);
    expect(find.text(r'Cargo de servicio Chambapp (15.00%): +$120.00 MXN'), findsOneWidget);
    expect(find.text(r'Total: $920.00 MXN'), findsOneWidget);
    expect(find.text(r'$- MXN'), findsNothing);
    expect(find.text('Pagar Chamba'), findsOneWidget);
    expect(find.byKey(const Key('pay_chamba_button')), findsOneWidget);
  });

  testWidgets('B) Cliente con role=professional y activeMode=client ve Pagar Chamba', (
    tester,
  ) async {
    const proAsClient = User(
      id: 1, // matches job.clientId
      name: 'Pro pero como cliente',
      email: 'pro-client@test.com',
      role: UserRole.professional,
      activeMode: 'client',
    );

    final container = await createTestContainer(
      job: directJobAwaitingPayment,
      user: proAsClient,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      buildWrapper(container, const JobDetailScreen(jobId: 42)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pagar Chamba'), findsWidgets);
  });

  testWidgets('C) Cliente con role=admin y activeMode=client ve Pagar Chamba', (
    tester,
  ) async {
    const adminAsClient = User(
      id: 1, // matches job.clientId
      name: 'Admin pero como cliente',
      email: 'admin-client@test.com',
      role: UserRole.admin,
      activeMode: 'client',
    );

    final container = await createTestContainer(
      job: directJobAwaitingPayment,
      user: adminAsClient,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      buildWrapper(container, const JobDetailScreen(jobId: 42)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pagar Chamba'), findsWidgets);
  });

  testWidgets('D) Profesional asignado NO ve Pagar Chamba', (
    tester,
  ) async {
    const assignedPro = User(
      id: 20, // matches professional.userId
      name: 'Mario Plomero',
      email: 'mario@test.com',
      role: UserRole.professional,
      activeMode: 'professional',
    );

    final container = await createTestContainer(
      job: directJobAwaitingPayment,
      user: assignedPro,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      buildWrapper(container, const JobDetailScreen(jobId: 42)),
    );
    await tester.pumpAndSettle();

    // The assigned pro must NOT see "Pagar Chamba"
    expect(find.text('Pagar Chamba'), findsNothing);
    expect(find.text('Cliente aceptó'), findsOneWidget);
    expect(find.text('Esperando confirmación del pago.'), findsOneWidget);
  });
}
