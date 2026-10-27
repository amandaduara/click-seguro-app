import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'assistant_validation.dart';

class AnalyzeImageUseCase {
  AnalyzeImageUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Either<Failure, AiAnalysisEntity>> call(
    String path, {
    String? source,
  }) {
    final invalid = path.trim().isEmpty
        ? const AssistantInvalidInputFailure()
        : validateSource(source);
    if (invalid != null) return Future.value(Left(invalid));
    return _repository.analyzeImage(path, source: source?.trim());
  }
}
