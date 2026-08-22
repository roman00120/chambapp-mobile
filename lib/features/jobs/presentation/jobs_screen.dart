import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/widgets/job_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  _HistoryView _filter = _HistoryView.active;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Mis chambas')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  _chip('Activas', _HistoryView.active),
                  _chip('Completadas', _HistoryView.completed),
                  _chip('Canceladas', _HistoryView.cancelled),
                  _chip('Todas', _HistoryView.all),
                ],
              ),
            ),
            Expanded(
              child: jobs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  title: 'No pudimos cargar tus chambas',
                  message: error,
                  onRetry: () => ref.invalidate(jobsProvider(null)),
                ),
                data: (allItems) {
                  final items = allItems.where(_filter.includes).toList();
                  return items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'Aún no tienes chambas en esta sección.',
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(jobsProvider(null));
                            await ref.read(jobsProvider(null).future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final job = items[index];
                              return JobCard(
                                job: job,
                                onTap: () => job.status == JobStatus.searching
                                    ? context.push(
                                        '/jobs/${job.id}/searching',
                                        extra: job,
                                      )
                                    : context.push('/jobs/${job.id}'),
                              );
                            },
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _HistoryView status) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == status,
      onSelected: (_) => setState(() => _filter = status),
    ),
  );
}

enum _HistoryView {
  active,
  completed,
  cancelled,
  all;

  bool includes(JobModel job) => switch (this) {
    active => !{
      JobStatus.completed,
      JobStatus.cancelled,
      JobStatus.expired,
      JobStatus.rejected,
      JobStatus.disputed,
    }.contains(job.status),
    completed => job.status == JobStatus.completed,
    cancelled => {
      JobStatus.cancelled,
      JobStatus.expired,
      JobStatus.rejected,
    }.contains(job.status),
    all => true,
  };
}
