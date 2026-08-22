import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  const JobCard({required this.job, required this.onTap, super.key});
  final JobModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      key: Key('job_${job.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.category?.name ?? job.service?.title ?? job.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusChip(job: job),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (job.professional != null)
              Text('Profesional: ${job.professional!.name}'),
            if (job.scheduledFor != null)
              Text(
                '${job.scheduledFor!.day}/${job.scheduledFor!.month}/${job.scheduledFor!.year} · ${job.scheduledSlot ?? ''}',
              ),
            if (job.generalLocation.isNotEmpty) Text(job.generalLocation),
            if (job.agreedPrice != null)
              Text('\$${job.agreedPrice} ${job.currency ?? 'MXN'}'),
            if (job.status == JobStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  job.review == null ? 'Pendiente de calificar' : 'Calificado',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: job.status.active
          ? AppColors.amber.withValues(alpha: .18)
          : AppColors.navy.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      job.statusLabel,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}
