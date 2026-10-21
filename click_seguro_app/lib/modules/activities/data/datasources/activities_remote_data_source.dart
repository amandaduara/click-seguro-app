import 'package:click_seguro_app/modules/activities/data/models/activities_dashboard_model.dart';

/// Lança `ApiException`; o repositório converte em `Failure`.
abstract class ActivitiesRemoteDataSource {
  /// `GET /app/educational/modules`. Sem token, o visitante recebe o
  /// progresso zerado.
  Future<ActivitiesDashboardModel> getModules();

  /// `POST …/lessons/{lessonId}/answer`. Na B1, só para transferir as
  /// respostas do visitante à conta nova; o resultado não é usado.
  Future<void> answerLesson({
    required String moduleId,
    required String lessonId,
    required String selectedOptionId,
  });
}
