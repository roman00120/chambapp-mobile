import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';

enum JobWorkflowActionType {
  acceptJob,
  rejectJob,
  pay,
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
  static JobPrimaryAction? primaryForJob({
    required bool isClient,
    required bool isProfessional,
    required JobStatus status,
  }) {
    if (isClient) {
      if (status == JobStatus.awaitingPayment) {
        return const JobPrimaryAction(
          type: JobWorkflowActionType.pay,
          label: 'Pagar Chamba',
          loadingLabel: 'Abriendo pago…',
        );
      }
      if (status == JobStatus.awaitingConfirmation) {
        return const JobPrimaryAction(
          type: JobWorkflowActionType.confirm,
          label: 'Confirmar trabajo',
          loadingLabel: 'Confirmando trabajo…',
        );
      }
    }
    if (isProfessional) {
      return switch (status) {
        JobStatus.pending => const JobPrimaryAction(
          type: JobWorkflowActionType.acceptJob,
          label: 'Aceptar solicitud',
          loadingLabel: 'Aceptando solicitud…',
        ),
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
    return null;
  }

  static JobPrimaryAction? primary(UserRole role, JobStatus status) =>
      primaryForJob(
        isClient: role == UserRole.client || role == UserRole.admin,
        isProfessional: role == UserRole.professional,
        status: status,
      );

  static JobPrimaryAction? secondaryForJob({
    required bool isClient,
    required bool isProfessional,
    required JobStatus status,
  }) {
    if (isClient && status == JobStatus.awaitingConfirmation) {
      return const JobPrimaryAction(
        type: JobWorkflowActionType.dispute,
        label: 'Reportar un problema',
        loadingLabel: 'Enviando reporte…',
        destructive: true,
      );
    }
    if (isProfessional && status == JobStatus.pending) {
      return const JobPrimaryAction(
        type: JobWorkflowActionType.rejectJob,
        label: 'Rechazar solicitud',
        loadingLabel: 'Rechazando solicitud…',
        destructive: true,
      );
    }
    return null;
  }

  static JobPrimaryAction? secondary(UserRole role, JobStatus status) =>
      secondaryForJob(
        isClient: role == UserRole.client || role == UserRole.admin,
        isProfessional: role == UserRole.professional,
        status: status,
      );
}
