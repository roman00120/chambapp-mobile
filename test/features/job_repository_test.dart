import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/jobs/data/job_repository_impl.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dio_test_adapter.dart';

Map<String, dynamic> _jobJson(String status) => {
  'id': 12,
  'title': 'Solicitud',
  'description': 'Reparar una fuga importante',
  'status': status,
  'status_label': status,
  'category': {'id': 1, 'name': 'Plomería', 'slug': 'plomeria'},
};

void main() {
  test('JobRepository crea immediate con FormData y consulta status', () async {
    final adapter = DioTestAdapter(
      (options) => options.path.endsWith('/status')
          ? jsonResponse({
              'data': {
                'status': 'matched',
                'status_label': 'Profesional encontrado',
              },
            })
          : jsonResponse({'data': _jobJson('searching')}, status: 201),
    );
    final repository = ApiJobRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final job = await repository.createImmediate(
      const ImmediateJobInput(
        categoryId: 1,
        description: 'Reparar una fuga importante',
        location: JobLocationInput(latitude: 19.4, longitude: -99.1),
      ),
    );
    expect(job.status, JobStatus.searching);
    expect(adapter.requests.first.data, isA<FormData>());
    expect((await repository.getStatus(12)).status, JobStatus.matched);
  });

  test('JobRepository crea scheduled con fecha, franja y ubicación', () async {
    final adapter = DioTestAdapter(
      (_) => jsonResponse({'data': _jobJson('pending')}, status: 201),
    );
    final repository = ApiJobRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final scheduledFor = DateTime(2030, 1, 2, 8);
    final job = await repository.createScheduled(
      ScheduledJobInput(
        categoryId: 1,
        title: 'Chamba programada',
        description: 'Instalar un contacto nuevo',
        location: const JobLocationInput(
          address: 'Calle 1',
          city: 'Guadalajara',
          state: 'Jalisco',
          postalCode: '44100',
        ),
        scheduledFor: scheduledFor,
        scheduledSlot: '08:00-11:00',
      ),
    );
    expect(job.status, JobStatus.pending);
    final data = adapter.requests.single.data as Map<String, dynamic>;
    expect(data['scheduled_slot'], '08:00-11:00');
    expect(data['city'], 'Guadalajara');
  });

  test('JobRepository lista jobs aplicando filtro de status', () async {
    final adapter = DioTestAdapter(
      (_) => jsonResponse({
        'data': [_jobJson('completed')],
      }),
    );
    final repository = ApiJobRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    expect(
      (await repository.getJobs(status: JobStatus.completed)).single.status,
      JobStatus.completed,
    );
    expect(adapter.requests.single.queryParameters['status'], 'completed');
  });

  test('todos los estados backend y uno desconocido se parsean sin error', () {
    const values = [
      'pending',
      'searching',
      'matched',
      'awaiting_quote',
      'accepted',
      'rejected',
      'awaiting_payment',
      'paid',
      'on_the_way',
      'arrived',
      'in_progress',
      'awaiting_confirmation',
      'completed',
      'cancelled',
      'expired',
      'disputed',
    ];
    for (final value in values) {
      expect(JobStatus.fromApi(value), isNot(JobStatus.unknown), reason: value);
    }
    expect(JobStatus.fromApi('future_status'), JobStatus.unknown);
  });

  test('JobModel ignora dirección exacta y coordenadas privadas', () {
    final job = JobModel.fromJson({
      ..._jobJson('searching'),
      'address': 'Privada 123',
      'latitude': '19.4',
      'longitude': '-99.1',
    });
    expect(job.address, isNull);
    expect(job.latitude, isNull);
    expect(job.toString(), isNot(contains('Privada 123')));
    expect(job.toString(), isNot(contains('-99.1')));
  });

  test('JobModel acepta datos operativos solo desde paid', () {
    final job = JobModel.fromJson({
      ..._jobJson('paid'),
      'address': 'Privada 123',
      'postal_code': '44100',
      'latitude': '19.4',
      'longitude': '-99.1',
    });
    expect(job.address, 'Privada 123');
    expect(job.latitude, '19.4');
  });

  test('workflow usa acciones explícitas y nunca un status genérico', () async {
    final adapter = DioTestAdapter(
      (options) => jsonResponse({'data': _jobJson('paid')}),
    );
    final repository = ApiJobRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );

    await repository.markOnTheWay(12);
    await repository.markArrived(12);
    await repository.startJob(12);
    await repository.finishJob(12);
    await repository.confirmJob(12, '123456');
    await repository.reportProblem(
      12,
      reason: DisputeReason.notAsAgreed,
      description: 'No coincide.',
    );

    expect(
      adapter.requests.map((request) => request.path),
      containsAllInOrder([
        '/jobs/12/on-the-way',
        '/jobs/12/arrived',
        '/jobs/12/start',
        '/jobs/12/finish',
        '/jobs/12/confirm',
        '/jobs/12/dispute',
      ]),
    );
    expect(adapter.requests[4].data, {'completion_code': '123456'});
    expect(adapter.requests[5].data, {
      'reason': 'not_as_agreed',
      'description': 'No coincide.',
    });
    expect(
      adapter.requests.any(
        (request) =>
            request.data is Map && (request.data as Map).containsKey('status'),
      ),
      isFalse,
    );
  });

  test('completion_code se conserva solo en awaiting_confirmation', () {
    final awaiting = JobModel.fromJson({
      ..._jobJson('awaiting_confirmation'),
      'completion_code': '123456',
    });
    final completed = JobModel.fromJson({
      ..._jobJson('completed'),
      'completion_code': '123456',
    });
    expect(awaiting.completionCode, '123456');
    expect(completed.completionCode, isNull);
  });
}
