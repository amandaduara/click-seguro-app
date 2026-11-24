import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAiHistoryUseCase {
  GetAiHistoryUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Either<Failure, AiHistoryPageEntity>> call({
    int page = 1,
    int limit = AssistantLimits.historyPageSize,
    AiHistoryFeature? feature,
  }) {
    if (page < AssistantLimits.historyPageMin ||
        limit < AssistantLimits.historyPageMin ||
        limit > AssistantLimits.historyLimitMax) {
      return Future.value(const Left(AssistantInvalidInputFailure()));
    }
    return _repository.getAiHistory(page: page, limit: limit, feature: feature);
  }
}
