import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/features/reports/domain/disciplinary_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final disciplinaryRepositoryProvider = Provider<DisciplinaryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DisciplinaryRepository(dio);
});

class DisciplinaryRepository {
  const DisciplinaryRepository(this._dio);
  final Dio _dio;

  Future<void> createReport({
    required int reportedId,
    required String category,
    required String description,
    int? jobRequestId,
  }) async {
    await _dio.post(
      '/reports',
      data: {
        'reported_id': reportedId,
        'category': category,
        'description': description,
        'confirm_truthfulness': true,
        'job_request_id': ?jobRequestId,
      },
    );
  }

  Future<List<UserReport>> getMyReports() async {
    final response = await _dio.get('/reports/mine');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => UserReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({int activeYellowCards, List<DisciplinaryActionModel> actions})>
  getMyDisciplinaryActions() async {
    final response = await _dio.get('/disciplinary-actions/mine');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final activeCards = data['active_yellow_cards'] is int
        ? data['active_yellow_cards'] as int
        : int.tryParse(data['active_yellow_cards']?.toString() ?? '0') ?? 0;
    final actionsList = (data['actions'] as List<dynamic>? ?? [])
        .map((e) => DisciplinaryActionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return (activeYellowCards: activeCards, actions: actionsList);
  }

  Future<void> submitAppeal({
    required int actionId,
    required String appealText,
  }) async {
    await _dio.post(
      '/disciplinary-actions/$actionId/appeal',
      data: {'appeal_text': appealText},
    );
  }
}
