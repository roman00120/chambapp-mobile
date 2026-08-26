import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_repositories.dart';
import 'package:chambapp_mobile/features/professional/presentation/identity_verification_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires consent, opens Didit and refreshes after returning', (
    tester,
  ) async {
    final repository = _FakeIdentityVerificationRepository();
    Uri? openedUrl;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityVerificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: IdentityVerificationScreen(
            urlOpener: (url) async {
              openedUrl = url;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final startButton = find.widgetWithText(
      FilledButton,
      'Verificar mi identidad',
    );
    expect(tester.widget<FilledButton>(startButton).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);

    await tester.tap(startButton);
    await tester.pumpAndSettle();
    expect(repository.starts, 1);
    expect(openedUrl, Uri.parse('https://verify.didit.me/session/test-token'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.syncs, 1);
    expect(find.text('Estado actualizado de forma segura.'), findsOneWidget);
  });

  for (final status in IdentityVerificationStatus.values.where(
    (value) => value != IdentityVerificationStatus.unknown,
  )) {
    testWidgets('renders ${status.apiValue} safely', (tester) async {
      final repository = _FakeIdentityVerificationRepository(status: status);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            identityVerificationRepositoryProvider.overrideWithValue(
              repository,
            ),
          ],
          child: const MaterialApp(home: IdentityVerificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(status.label), findsOneWidget);
    });
  }
}

final class _FakeIdentityVerificationRepository
    implements IdentityVerificationRepository {
  _FakeIdentityVerificationRepository({
    this.status = IdentityVerificationStatus.notStarted,
  });

  final IdentityVerificationStatus status;
  int starts = 0;
  int syncs = 0;

  @override
  Future<IdentityVerificationModel> getStatus() async => _model(status);

  @override
  Future<IdentityVerificationStart> start() async {
    starts++;
    return IdentityVerificationStart(
      url: Uri.parse('https://verify.didit.me/session/test-token'),
      status: IdentityVerificationStatus.pending,
    );
  }

  @override
  Future<IdentityVerificationModel> sync() async {
    syncs++;
    return _model(IdentityVerificationStatus.verified);
  }

  IdentityVerificationModel _model(IdentityVerificationStatus value) =>
      IdentityVerificationModel(
        status: value,
        isRequired: false,
        identityVerified: value == IdentityVerificationStatus.verified,
        canAcceptJobs: true,
        canStartVerification: value != IdentityVerificationStatus.verified,
        documentsStoredByChambapp: false,
      );
}
