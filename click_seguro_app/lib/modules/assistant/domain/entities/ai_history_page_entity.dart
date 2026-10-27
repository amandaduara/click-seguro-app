import 'ai_analysis_entity.dart';

class AiHistoryPageEntity {
  const AiHistoryPageEntity({
    required this.items,
    required this.page,
    required this.hasNextPage,
  });

  final List<AiAnalysisEntity> items;
  final int page;
  final bool hasNextPage;
}
