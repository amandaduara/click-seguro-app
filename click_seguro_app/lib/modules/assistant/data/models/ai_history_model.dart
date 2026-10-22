import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';

import 'ai_analysis_model.dart';

class AiHistoryModel {
  const AiHistoryModel(this.entity);

  factory AiHistoryModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return AiHistoryModel(
      AiHistoryPageEntity(
        items: [
          for (final item in json['data'] as List)
            AiAnalysisModel.fromJson(item as Map<String, dynamic>).entity,
        ],
        page: (meta['page'] as num).toInt(),
        hasNextPage: meta['hasNextPage'] as bool,
      ),
    );
  }

  final AiHistoryPageEntity entity;
}
