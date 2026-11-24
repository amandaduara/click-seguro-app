import 'package:click_seguro_app/modules/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:click_seguro_app/modules/assistant/data/models/ai_analysis_model.dart';
import 'package:click_seguro_app/modules/assistant/data/models/ai_history_model.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

import 'ai_fixtures.dart';

class FakeAssistantRemoteDataSource implements AssistantRemoteDataSource {
  Object? error;
  int calls = 0;

  @override
  Future<AiAnalysisModel> analyzeImage(String path, String? source) async {
    calls++;
    _throwIfNeeded();
    return AiAnalysisModel.fromJson(aiAnalysisJson());
  }

  @override
  Future<AiAnalysisModel> analyzeText(String text, String? source) async {
    calls++;
    _throwIfNeeded();
    return AiAnalysisModel.fromJson(aiAnalysisJson());
  }

  @override
  Future<AiHistoryModel> getHistory(
    int page,
    int limit,
    AiHistoryFeature? feature,
  ) async {
    calls++;
    _throwIfNeeded();
    return AiHistoryModel.fromJson(aiHistoryJson());
  }

  @override
  Future<String> sendChatMessage(
    String message,
    List<AiChatTurn> history,
  ) async {
    calls++;
    _throwIfNeeded();
    return 'Resposta';
  }

  void _throwIfNeeded() {
    final value = error;
    if (value is ApiException) throw value;
    if (value is Exception) throw value;
  }
}
