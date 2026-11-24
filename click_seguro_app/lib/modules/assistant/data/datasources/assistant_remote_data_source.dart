import 'package:click_seguro_app/modules/assistant/data/models/ai_analysis_model.dart';
import 'package:click_seguro_app/modules/assistant/data/models/ai_history_model.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';

abstract interface class AssistantRemoteDataSource {
  Future<String> sendChatMessage(String message, List<AiChatTurn> history);
  Future<AiAnalysisModel> analyzeText(String text, String? source);
  Future<AiAnalysisModel> analyzeImage(String path, String? source);
  Future<AiHistoryModel> getHistory(
    int page,
    int limit,
    AiHistoryFeature? feature,
  );
}
