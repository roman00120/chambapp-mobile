import 'dart:async';

import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/jobs/domain/commerce_repositories.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/checkout_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/quote_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/m2_fakes.dart';

const quote = JobQuoteModel(
  id: 4,
  jobId: 12,
  professionalId: 3,
  amount: '1000.00',
  currency: 'MXN',
  description: 'Incluye mano de obra.',
  status: QuoteStatus.pending,
);

const pendingPayment = PaymentModel(
  id: 7,
  jobId: 12,
  status: PaymentStatus.pending,
  grossAmount: '1000.00',
  platformFeePercent: '15.00',
  platformFee: '150.00',
  professionalAmount: '850.00',
  currency: 'MXN',
);

final class FakeQuoteRepository implements QuoteRepository {
  Object? createError;
  Completer<JobQuoteModel>? createCompleter;
  int createCalls = 0;
  @override
  Future<JobQuoteModel> createQuote(
    int jobId, {
    required String amount,
    required String description,
  }) {
    createCalls++;
    if (createError != null) throw createError!;
    return createCompleter?.future ?? Future.value(quote);
  }

  @override
  Future<JobQuoteModel> acceptQuote(int jobId, int quoteId) async => quote;
  @override
  Future<List<JobQuoteModel>> getQuotes(int jobId, {int page = 1}) async =>
      const [quote];
  @override
  Future<JobQuoteModel> rejectQuote(
    int jobId,
    int quoteId, {
    required String reason,
    String? reasonDetail,
  }) async => quote;
}

final class FakePaymentRepository implements PaymentRepository {
  int checkoutCalls = 0;
  Completer<CheckoutResult>? completer;
  PaymentModel payment = pendingPayment;
  @override
  Future<CheckoutResult> createCheckout(int jobId) {
    checkoutCalls++;
    return completer?.future ??
        Future.value(
          CheckoutResult(
            checkoutUrl: 'https://sandbox.mercadopago.com/checkout',
            payment: payment,
          ),
        );
  }

  @override
  Future<PaymentModel> getPayment(int paymentId) async => payment;
}

Widget material(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

void main() {
  testWidgets('quote preview muestra 15% estimado y bloquea doble submit', (
    tester,
  ) async {
    final quotes = FakeQuoteRepository()
      ..createCompleter = Completer<JobQuoteModel>();
    final container = ProviderContainer(
      overrides: [quoteRepositoryProvider.overrideWithValue(quotes)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      material(container, const QuoteFormScreen(jobId: 12)),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio en MXN'),
      '1000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nota de la cotizaciÃ³n'),
      'Incluye mano de obra.',
    );
    await tester.pump();
    expect(find.text(r'$150.00 MXN'), findsOneWidget);
    expect(find.text(r'$850.00 MXN'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar cotizaciÃ³n'));
    await tester.pump();
    await tester.tap(find.text('Enviando cotizaciÃ³nâ€¦'));
    expect(quotes.createCalls, 1);
    quotes.createCompleter!.complete(quote);
    await tester.pumpAndSettle();
  });

  testWidgets('ContactInformationGuard 422 muestra mensaje amigable', (
    tester,
  ) async {
    final quotes = FakeQuoteRepository()
      ..createError = const AppException(
        message: 'Revisa los datos.',
        statusCode: 422,
        fieldErrors: {'description': 'No compartas datos de contacto.'},
      );
    final container = ProviderContainer(
      overrides: [quoteRepositoryProvider.overrideWithValue(quotes)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      material(container, const QuoteFormScreen(jobId: 12)),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio en MXN'),
      '1000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nota de la cotizaciÃ³n'),
      'WhatsApp 5512345678',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar cotizaciÃ³n'));
    await tester.pump();
    expect(find.text('No compartas datos de contacto.'), findsOneWidget);
  });

  testWidgets(
    'checkout bloquea doble tap y return pending no declara approved',
    (tester) async {
      final jobs = FakeJobRepository()
        ..job = const JobModel(
          id: 12,
          title: 'Fuga',
          description: 'Reparar fuga',
          status: JobStatus.awaitingPayment,
          statusLabel: 'Esperando pago',
          agreedPrice: '1000.00',
          currency: 'MXN',
        );
      final payments = FakePaymentRepository()
        ..completer = Completer<CheckoutResult>();
      final container = ProviderContainer(
        overrides: [
          jobRepositoryProvider.overrideWithValue(jobs),
          paymentRepositoryProvider.overrideWithValue(payments),
          externalUrlLauncherProvider.overrideWithValue((_) async => true),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        material(container, const CheckoutScreen(jobId: 12)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pagar en Chambapp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(payments.checkoutCalls, 1);
      payments.completer!.complete(
        const CheckoutResult(
          checkoutUrl: 'https://sandbox.mercadopago.com/checkout',
          payment: pendingPayment,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Tu pago estÃ¡ siendo procesado'), findsOneWidget);
      expect(find.text('Pago aprobado'), findsNothing);
    },
  );

  testWidgets('payment rejected renderiza retry y paid renderiza aprobado', (
    tester,
  ) async {
    for (final entry in [
      (PaymentStatus.rejected, 'No pudimos procesar el pago'),
      (PaymentStatus.approved, 'Pago aprobado'),
    ]) {
      final payment = PaymentModel(
        id: 7,
        jobId: 12,
        status: entry.$1,
        grossAmount: '1000.00',
        platformFeePercent: '10.00',
        platformFee: '100.00',
        professionalAmount: '900.00',
        currency: 'MXN',
      );
      final jobs = FakeJobRepository()
        ..job = JobModel(
          id: 12,
          title: 'Fuga',
          description: 'Reparar fuga',
          status: entry.$1 == PaymentStatus.approved
              ? JobStatus.paid
              : JobStatus.awaitingPayment,
          statusLabel: 'Estado',
          agreedPrice: '1000.00',
          payment: payment,
        );
      final container = ProviderContainer(
        overrides: [
          jobRepositoryProvider.overrideWithValue(jobs),
          paymentRepositoryProvider.overrideWithValue(
            FakePaymentRepository()..payment = payment,
          ),
        ],
      );
      await tester.pumpWidget(
        material(container, const CheckoutScreen(jobId: 12)),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
  });
}
