import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/reports/data/disciplinary_repository.dart';
import 'package:chambapp_mobile/features/reports/domain/disciplinary_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityCenterScreen extends ConsumerStatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  ConsumerState<SecurityCenterScreen> createState() =>
      _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends ConsumerState<SecurityCenterScreen> {
  bool _isLoading = true;
  String? _error;
  int _activeYellowCards = 0;
  List<DisciplinaryActionModel> _actions = [];
  List<UserReport> _myReports = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(disciplinaryRepositoryProvider);
      final discData = await repo.getMyDisciplinaryActions();
      final reportsData = await repo.getMyReports();

      if (mounted) {
        setState(() {
          _activeYellowCards = discData.activeYellowCards;
          _actions = discData.actions;
          _myReports = reportsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAppealDialog(DisciplinaryActionModel action) async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Apelar decisión disciplinaria'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explica de forma respetuosa los motivos por los cuales consideras que esta sanción debe ser revisada.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: textController,
                  maxLines: 4,
                  minLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().length < 20) {
                      return 'Por favor escribe al menos 20 caracteres.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Describe tus argumentos...',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    dialogError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSending = true;
                        dialogError = null;
                      });
                      try {
                        await ref
                            .read(disciplinaryRepositoryProvider)
                            .submitAppeal(
                              actionId: action.id,
                              appealText: textController.text.trim(),
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Apelación enviada a revisión administrativa.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSending = false;
                          dialogError = e.toString().replaceAll(
                            'Exception: ',
                            '',
                          );
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar apelación'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad y Reportes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_error != null) ...[
                    Card(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Tarjeta Estado de Cuenta & Advertencias
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Estado de tu cuenta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Chip(
                                label: Text(
                                  user?.status ?? 'Activa',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: user?.status == 'suspended'
                                    ? AppColors.amberDark
                                    : user?.status == 'blocked'
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.lg),
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.amberDark,
                                size: 28,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_activeYellowCards / 3 Tarjetas amarillas activas',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Text(
                                    '1: Advertencia · 2: Advertencia grave · 3: Revisión',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mis Avisos y Sanciones
                  Text(
                    'Mis avisos disciplinarios',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_actions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No tienes advertencias ni sanciones registradas.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  else
                    ..._actions.map(
                      (act) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    act.actionTypeLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.amberDark,
                                    ),
                                  ),
                                  Text(
                                    act.statusLabel,
                                    style: TextStyle(
                                      color: act.isActive
                                          ? AppColors.danger
                                          : AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(act.reasonText),
                              if (act.isActive) ...[
                                const SizedBox(height: AppSpacing.sm),
                                if (act.appeal != null)
                                  Text(
                                    'Apelación: ${act.appeal!.statusLabel}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _showAppealDialog(act),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      size: 16,
                                    ),
                                    label: const Text('Apelar decisión'),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mis Reportes Enviados
                  Text(
                    'Mis reportes enviados',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_myReports.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No has enviado reportes.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  else
                    ..._myReports.map(
                      (rep) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: const Icon(
                            Icons.flag_outlined,
                            color: AppColors.muted,
                          ),
                          title: Text(rep.categoryLabel),
                          subtitle: Text(
                            'Reportado: ${rep.reportedUserName ?? 'Usuario'}',
                          ),
                          trailing: Chip(
                            label: Text(
                              rep.status == 'submitted'
                                  ? 'Enviado'
                                  : rep.status == 'under_review'
                                  ? 'En revisión'
                                  : 'Revisado',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
