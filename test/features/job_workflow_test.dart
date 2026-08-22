import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mapper profesional no permite saltos y asigna una acción por estado',
    () {
      expect(
        JobWorkflowActions.primary(UserRole.professional, JobStatus.paid)?.type,
        JobWorkflowActionType.onTheWay,
      );
      expect(
        JobWorkflowActions.primary(
          UserRole.professional,
          JobStatus.onTheWay,
        )?.type,
        JobWorkflowActionType.arrived,
      );
      expect(
        JobWorkflowActions.primary(
          UserRole.professional,
          JobStatus.arrived,
        )?.type,
        JobWorkflowActionType.start,
      );
      expect(
        JobWorkflowActions.primary(
          UserRole.professional,
          JobStatus.inProgress,
        )?.type,
        JobWorkflowActionType.finish,
      );
      for (final status in [
        JobStatus.awaitingConfirmation,
        JobStatus.completed,
        JobStatus.disputed,
        JobStatus.cancelled,
      ]) {
        expect(
          JobWorkflowActions.primary(UserRole.professional, status),
          isNull,
        );
      }
    },
  );

  test('cliente solo confirma o disputa en awaiting_confirmation', () {
    expect(
      JobWorkflowActions.primary(
        UserRole.client,
        JobStatus.awaitingConfirmation,
      )?.type,
      JobWorkflowActionType.confirm,
    );
    expect(
      JobWorkflowActions.secondary(
        UserRole.client,
        JobStatus.awaitingConfirmation,
      )?.type,
      JobWorkflowActionType.dispute,
    );
    expect(
      JobWorkflowActions.primary(UserRole.client, JobStatus.inProgress),
      isNull,
    );
    expect(
      JobWorkflowActions.primary(UserRole.client, JobStatus.completed),
      isNull,
    );
  });
}
