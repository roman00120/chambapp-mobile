import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';

enum JobWorkflowActionType {
  onTheWay,
  arrived,
  start,
  finish,
  confirm,
  dispute,
}

final class JobPrimaryAction {
  const JobPrimaryAction({
    required this.type,
    required this.label,
    required this.loadingLabel,
    this.destructive = false,
  });

  final JobWorkflowActionType type;
  final String label;
  final String loadingLabel;
  final bool destructive;
}

abstract final class JobWorkflowActions {
  static JobPrimaryAction? primary(UserRole role, JobStatus status) {
    if (role == UserRole.professional) {
      return switch (status) {
        JobStatus.paid => const JobPrimaryAction(
          type: JobWorkflowActionType.onTheWay,
          label: 'Ir al servicio',
          loadingLabel: 'Actualizando estado…',
        ),
        JobStatus.onTheWay => const JobPrimaryAction(
          type: JobWorkflowActionType.arrived,
          label: 'Ya llegué',
          loadingLabel: 'Registrando llegada…',
        ),
        JobStatus.arrived => const JobPrimaryAction(
          type: JobWorkflowActionType.start,
          label: 'Iniciar trabajo',
          loadingLabel: 'Iniciando trabajo…',
        ),
        JobStatus.inProgress => const JobPrimaryAction(
          type: JobWorkflowActionType.finish,
          label: 'Marcar como terminado',
          loadingLabel: 'Marcando como terminado…',
        ),
        _ => null,
      };
    }
    if (role == UserRole.client && status == JobStatus.awaitingConfirmation) {
      return const JobPrimaryAction(
        type: JobWorkflowActionType.confirm,
        label: 'Confirmar trabajo',
        loadingLabel: 'Confirmando trabajo…',
      );
    }
    return null;
  }

  static JobPrimaryAction? secondary(UserRole role, JobStatus status) =>
      role == UserRole.client && status == JobStatus.awaitingConfirmation
      ? const JobPrimaryAction(
          type: JobWorkflowActionType.dispute,
          label: 'Reportar un problema',
          loadingLabel: 'Enviando reporte…',
          destructive: true,
        )
      : null;
}
