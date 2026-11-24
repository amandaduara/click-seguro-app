import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AssistantRepository {
  Future<Either<Failure, String>> sendChatMessage(
    String message, {
    List<AiChatTurn> history = const [],
  });

  Future<Either<Failure, AiAnalysisEntity>> analyzeText(
    String text, {
    String? source,
  });

  Future<Either<Failure, AiAnalysisEntity>> analyzeImage(
    String path, {
    String? source,
  });

  Future<Either<Failure, AiHistoryPageEntity>> getAiHistory({
    required int page,
    required int limit,
    AiHistoryFeature? feature,
  });
}
