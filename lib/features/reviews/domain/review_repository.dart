import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';

abstract interface class ReviewRepository {
  Future<ReviewModel> create(int jobId, {required int rating, String? comment});
}
