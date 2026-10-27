import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'assistant_validation.dart';

class AnalyzeTextUseCase {
  AnalyzeTextUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Either<Failure, AiAnalysisEntity>> call(
    String text, {
    String? source,
  }) {
    final invalid =
        validateBoundedText(
          text,
          min: AssistantLimits.analysisTextMin,
          max: AssistantLimits.analysisTextMax,
        ) ??
        validateSource(source);
    if (invalid != null) return Future.value(Left(invalid));
    return _repository.analyzeText(text.trim(), source: source?.trim());
  }
}
