import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/professional/data/professional_repositories_impl.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dio_test_adapter.dart';

void main() {
  test('perfil profesional parsea verificación y actualiza campos permitidos vía JSON y multipart', () async {
    final adapter = DioTestAdapter((options) {
      expect(options.path, '/professional/profile');
      return jsonResponse({
        'data': {
          'id': 5,
          'name': 'Carlos',
          'rating': '4.80',
          'total_reviews': 9,
          'completed_jobs': 20,
          'verification_status': 'verified',
          'is_available': false,
          'postal_code': '44100',
        },
      });
    });
    final repository = ApiProfessionalProfileRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final profile = await repository.getProfile();
    expect(profile.verification, ProfessionalVerification.verified);
    expect(profile.rating, 4.8);
    expect(profile.postalCode, '44100');

    await repository.updateProfile(
      const ProfessionalProfileInput(
        name: 'Carlos',
        phone: '5512345678',
        experienceYears: 8,
        bio: 'Experiencia profesional',
        postalCode: '44100',
      ),
    );
    final jsonPayload = adapter.requests.last.data as Map<String, dynamic>;
    expect(adapter.requests.last.method, 'PATCH');
    expect(jsonPayload['name'], 'Carlos');
    expect(jsonPayload['phone'], '5512345678');
    expect(jsonPayload['experience_years'], 8);
    expect(jsonPayload['postal_code'], '44100');
    expect(jsonPayload.containsKey('verification_status'), isFalse);
    expect(jsonPayload.containsKey('rating'), isFalse);
  });

  test(
    'availability envía preferencia, radio y ubicación al endpoint real',
    () async {
      final adapter = DioTestAdapter(
        (options) => jsonResponse({
          'data': {
            'is_available': true,
            'availability_status': 'available',
            'service_radius_km': 15,
            'location_updated_at': '2026-08-21T12:00:00-06:00',
          },
        }),
      );
      final repository = ApiAvailabilityRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );
      final result = await repository.updateAvailability(
        isAvailable: true,
        serviceRadiusKm: 15,
        latitude: 20.67,
        longitude: -103.34,
      );
      expect(adapter.requests.single.path, '/professional/availability');
      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.data['service_radius_km'], 15);
      expect(result.displayStatus, AvailabilityStatus.available);
    },
  );

  test(
    'servicios usan endpoints propios y no envían is_active inventado',
    () async {
      final adapter = DioTestAdapter(
        (options) => jsonResponse({
          'data': {
            'id': 9,
            'title': 'Reparación de fugas',
            'description': 'Descripción profesional suficientemente larga.',
            'price_type': 'fixed',
            'price': '500.00',
            'currency': 'MXN',
            'is_active': true,
          },
        }, status: options.method == 'POST' ? 201 : 200),
      );
      final repository = ApiProfessionalServiceRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );
      await repository.create(
        const ProfessionalServiceInput(
          categoryId: 1,
          title: 'Reparación de fugas',
          description: 'Descripción profesional suficientemente larga.',
          priceType: ProfessionalPriceType.fixed,
          price: '500.00',
        ),
      );
      final form = adapter.requests.single.data as FormData;
      final fields = Map.fromEntries(form.fields);
      expect(adapter.requests.single.path, '/professional/services');
      expect(fields['price_type'], 'fixed');
      expect(fields.containsKey('is_active'), isFalse);
    },
  );

  test('invitaciones ignoran datos privados y descartan expiradas', () async {
    final adapter = DioTestAdapter(
      (options) => jsonResponse({
        'data': [
          {
            'id': 1,
            'status': 'viewed',
            'distance_km': '2.80',
            'expires_at': '2099-01-01T00:00:00Z',
            'job': {
              'id': 12,
              'title': 'Fuga',
              'description': 'Fuga debajo del lavabo',
              'city': 'Guadalajara',
              'phone': '5512345678',
              'email': 'private@example.test',
              'exact_address': 'Privada 123',
              'latitude': 20.67,
            },
          },
          {
            'id': 2,
            'distance_km': '1.00',
            'expires_at': '2020-01-01T00:00:00Z',
            'job': {'id': 13, 'title': 'Expirada'},
          },
        ],
      }),
    );
    final repository = ApiJobInvitationRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final values = await repository.getInvitations();
    expect(values, hasLength(1));
    expect(values.single.distanceKm, 2.8);
    expect(values.single.toString(), isNot(contains('private@example.test')));
    expect(values.single.toString(), isNot(contains('5512345678')));
  });

  test('invitaciones aceptan y rechazan usando los endpoints reales', () async {
    final adapter = DioTestAdapter((options) {
      if (options.path.endsWith('/accept')) {
        return jsonResponse({
          'data': {
            'id': 12,
            'title': 'Chamba asignada',
            'description': 'Trabajo confirmado por el servidor',
            'status': 'matched',
            'status_label': 'Profesional encontrado',
          },
        });
      }
      return jsonResponse({'data': null, 'message': 'Rechazada'});
    });
    final repository = ApiJobInvitationRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final job = await repository.acceptInvitation(7);
    await repository.declineInvitation(8);
    expect(job.id, 12);
    expect(adapter.requests[0].path, '/professional/job-invitations/7/accept');
    expect(adapter.requests[1].path, '/professional/job-invitations/8/decline');
    expect(
      adapter.requests.every((request) => request.method == 'POST'),
      isTrue,
    );
  });

  test('accept conserva código JOB_ALREADY_TAKEN del backend', () async {
    final adapter = DioTestAdapter(
      (options) => jsonResponse({
        'message': 'La oportunidad ya fue tomada.',
        'code': 'JOB_ALREADY_TAKEN',
        'errors': {},
      }, status: 409),
    );
    final repository = ApiJobInvitationRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    await expectLater(
      repository.acceptInvitation(7),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'JOB_ALREADY_TAKEN',
        ),
      ),
    );
  });

  test('trabajos profesionales usan ruta, filtro real y mapean 403', () async {
    var forbidden = false;
    final adapter = DioTestAdapter(
      (options) => forbidden
          ? jsonResponse({'message': 'Prohibido'}, status: 403)
          : jsonResponse({
              'data': [
                {
                  'id': 4,
                  'title': 'Chamba',
                  'description': 'Trabajo asignado',
                  'status': 'in_progress',
                  'status_label': 'En proceso',
                },
              ],
            }),
    );
    final repository = ApiProfessionalJobRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final jobs = await repository.getJobs(status: JobStatus.inProgress);
    expect(jobs.single.status, JobStatus.inProgress);
    expect(adapter.requests.single.path, '/professional/jobs');
    expect(adapter.requests.single.queryParameters['status'], 'in_progress');
    expect(
      adapter.requests.single.queryParameters.containsKey('professional_id'),
      isFalse,
    );

    forbidden = true;
    await expectLater(
      repository.getJobs(),
      throwsA(
        isA<AppException>().having((error) => error.statusCode, 'status', 403),
      ),
    );
  });
}
