import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/features/jobs/data/commerce_repositories_impl.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dio_test_adapter.dart';

Map<String, dynamic> quoteJson({String status = 'pending'}) => {
  'id': 4,
  'job_id': 12,
  'professional_id': 3,
  'amount': '1000.00',
  'currency': 'MXN',
  'description': 'Incluye mano de obra.',
  'status': status,
  'created_at': '2026-08-21T10:00:00-06:00',
};

Map<String, dynamic> paymentJson({
  String status = 'pending',
  String percent = '15.00',
}) => {
  'id': 7,
  'job_id': 12,
  'status': status,
  'gross_amount': '1000.00',
  'platform_fee_percent': percent,
  'platform_fee': percent == '10.00' ? '100.00' : '150.00',
  'professional_amount': percent == '10.00' ? '900.00' : '850.00',
  'currency': 'MXN',
};

Map<String, dynamic> dualFeePaymentJson() => {
  'id': 8,
  'job_id': 12,
  'status': 'pending',
  'economic_model_version': 'client_15_professional_15',
  'base_amount': '1000.00',
  'client_service_fee_percent': '15.00',
  'client_service_fee': '150.00',
  'customer_total': '1150.00',
  'professional_commission_percent': '15.00',
  'professional_commission': '150.00',
  'professional_amount_before_external_costs': '850.00',
  'currency': 'MXN',
};

void main() {
  test(
    'QuoteRepository usa crear, listar, aceptar y rechazar reales',
    () async {
      final adapter = DioTestAdapter((options) {
        final status = options.path.endsWith('/accept')
            ? 'accepted'
            : options.path.endsWith('/reject')
            ? 'rejected'
            : 'pending';
        return jsonResponse({
          'data': options.method == 'GET'
              ? [quoteJson(status: status)]
              : quoteJson(status: status),
        }, status: options.path == '/professional/jobs/12/quotes' ? 201 : 200);
      });
      final repository = ApiQuoteRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );
      expect((await repository.getQuotes(12)).single.amount, '1000.00');
      await repository.createQuote(
        12,
        amount: '1000.00',
        description: 'Incluye mano de obra.',
      );
      expect(
        (await repository.acceptQuote(12, 4)).status,
        QuoteStatus.accepted,
      );
      expect(
        (await repository.rejectQuote(12, 4, reason: 'price_high')).status,
        QuoteStatus.rejected,
      );
      expect(adapter.requests.map((item) => item.path), [
        '/jobs/12/quotes',
        '/professional/jobs/12/quotes',
        '/jobs/12/quotes/4/accept',
        '/jobs/12/quotes/4/reject',
      ]);
      expect((adapter.requests.last.data as Map)['reason'], 'price_high');
    },
  );

  test(
    '422 ContactInformationGuard conserva mensaje por description',
    () async {
      final adapter = DioTestAdapter(
        (_) => jsonResponse({
          'message': 'Revisa los datos.',
          'errors': {
            'description': ['No compartas datos de contacto.'],
          },
        }, status: 422),
      );
      final repository = ApiQuoteRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );
      await expectLater(
        repository.createQuote(
          12,
          amount: '1000',
          description: 'WhatsApp 5512345678',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.fieldErrors['description'],
            'description',
            'No compartas datos de contacto.',
          ),
        ),
      );
    },
  );

  test('checkout no envía amount y parsea cálculo oficial 15%', () async {
    final adapter = DioTestAdapter(
      (_) => jsonResponse({
        'data': {
          'checkout_url': 'https://sandbox.mercadopago.com/checkout',
          'payment': paymentJson(),
        },
      }),
    );
    final repository = ApiPaymentRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final result = await repository.createCheckout(12);
    expect(result.checkoutUrl, startsWith('https://sandbox.mercadopago.com'));
    expect(result.payment.platformFee, '150.00');
    expect(result.payment.professionalAmount, '850.00');
    expect(adapter.requests.single.data, isNull);
  });

  test(
    'Payment conserva snapshot histórico 10% y tolera status desconocido',
    () async {
      final historical = PaymentModel.fromJson(paymentJson(percent: '10.00'));
      expect(historical.platformFeePercent, '10.00');
      expect(historical.platformFee, '100.00');
      expect(historical.professionalAmount, '900.00');
      expect(
        PaymentModel.fromJson(paymentJson(status: 'future')).status,
        PaymentStatus.unknown,
      );
    },
  );

  test(
    'Payment V2 consume el desglose oficial del servidor sin calcularlo',
    () {
      final payment = PaymentModel.fromJson(dualFeePaymentJson());

      expect(payment.baseAmount, '1000.00');
      expect(payment.clientServiceFee, '150.00');
      expect(payment.customerTotal, '1150.00');
      expect(payment.professionalCommission, '150.00');
      expect(payment.professionalAmountBeforeExternalCosts, '850.00');
      expect(payment.grossAmount, '1150.00');
    },
  );

  test('PaymentModel no espera ni serializa secretos del proveedor', () {
    final payment = PaymentModel.fromJson({
      ...paymentJson(),
      'access_token': 'secret',
      'client_secret': 'secret-2',
      'card_number': '4111111111111111',
      'webhook_payload': {'private': true},
    });
    expect(payment.toString(), isNot(contains('secret')));
    expect(payment.grossAmount, '1000.00');
  });
}
