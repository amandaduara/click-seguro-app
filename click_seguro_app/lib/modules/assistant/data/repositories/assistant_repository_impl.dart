import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:fpdart/fpdart.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl(this._remote);

  static const providerFailedCode = 'AI_PROVIDER_FAILED';
  static const parseFailedCode = 'AI_PARSE_FAILED';

  final AssistantRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> sendChatMessage(
    String message, {
    List<AiChatTurn> history = const [],
  }) => _guard(() => _remote.sendChatMessage(message, history));

  @override
  Future<Either<Failure, AiAnalysisEntity>> analyzeText(
    String text, {
    String? source,
  }) => _guard(() async => (await _remote.analyzeText(text, source)).entity);

  @override
  Future<Either<Failure, AiAnalysisEntity>> analyzeImage(
    String path, {
    String? source,
  }) => _guard(() async => (await _remote.analyzeImage(path, source)).entity);

  @override
  Future<Either<Failure, AiHistoryPageEntity>> getAiHistory({
    required int page,
    required int limit,
    AiHistoryFeature? feature,
  }) => _guard(
    () async => (await _remote.getHistory(page, limit, feature)).entity,
  );

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ApiException catch (error) {
      if (error.statusCode == 429) {
        return const Left(AssistantRateLimitedFailure());
      }
      return Left(switch (error.errorCode) {
        providerFailedCode => const AssistantProviderFailure(),
        parseFailedCode => const AssistantParseFailure(),
        AssistantImageErrorCodes.invalidFormat =>
          const AssistantInvalidImageFailure(),
        _ when error.type == ApiErrorType.invalidResponse =>
          const AssistantParseFailure(),
        _ => error.toFailure(),
      });
    } on FormatException {
      return const Left(AssistantParseFailure());
    } on TypeError {
      return const Left(AssistantParseFailure());
    } on Exception {
      return const Left(ServerFailure());
    }
  }
}
