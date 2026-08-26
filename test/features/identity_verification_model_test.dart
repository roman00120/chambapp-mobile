import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a verified identity independently from profile review', () {
    final model = IdentityVerificationModel.fromJson({
      'status': 'verified',
      'is_required': true,
      'identity_verified': true,
      'can_accept_jobs': true,
      'can_start_verification': false,
      'documents_stored_by_chambapp': false,
      'verified_at': '2026-08-23T12:00:00Z',
    });

    expect(model.status, IdentityVerificationStatus.verified);
    expect(model.identityVerified, isTrue);
    expect(model.canAcceptJobs, isTrue);
    expect(model.documentsStoredByChambapp, isFalse);
  });

  test('parses safe defaults for a professional who has not started', () {
    final model = IdentityVerificationModel.fromJson({
      'status': 'not_started',
      'is_required': false,
      'identity_verified': false,
      'can_accept_jobs': true,
      'can_start_verification': false,
      'documents_stored_by_chambapp': false,
    });

    expect(model.status, IdentityVerificationStatus.notStarted);
    expect(model.identityVerified, isFalse);
    expect(model.canAcceptJobs, isTrue);
  });

  test('parses only an HTTPS hosted verification URL', () {
    final start = IdentityVerificationStart.fromJson({
      'verification_url': 'https://verify.didit.me/session/test-token',
      'status': 'pending',
    });

    expect(start.url.host, 'verify.didit.me');
    expect(start.status, IdentityVerificationStatus.pending);
    expect(
      () => IdentityVerificationStart.fromJson({
        'verification_url': 'http://example.test/session',
        'status': 'pending',
      }),
      throwsFormatException,
    );
  });

  test('legacy professional verification is labelled as profile review', () {
    expect(ProfessionalVerification.verified.label, 'Perfil habilitado');
  });

  test('public badge ignores the legacy verified flag', () {
    final legacy = ProfessionalModel.fromJson({
      'id': 1,
      'name': 'Profesional',
      'verified': true,
    });
    final identity = ProfessionalModel.fromJson({
      'id': 2,
      'name': 'Profesional',
      'identity_verified': true,
    });

    expect(legacy.verified, isFalse);
    expect(identity.verified, isTrue);
  });
}
