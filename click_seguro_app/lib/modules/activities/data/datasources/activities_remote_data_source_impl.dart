import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source.dart';
import 'package:click_seguro_app/modules/activities/data/models/activities_dashboard_model.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

class ActivitiesRemoteDataSourceImpl implements ActivitiesRemoteDataSource {
  ActivitiesRemoteDataSourceImpl(this._apiClient);

  static const String modulesPath = '/app/educational/modules';

  static String answerPath(String moduleId, String lessonId) =>
      '$modulesPath/$moduleId/lessons/$lessonId/answer';

  final ApiClient _apiClient;

  // O ApiClient só manda o token se a sessão tiver um: o visitante vai sem.
  @override
  Future<ActivitiesDashboardModel> getModules() async {
    final response = await _apiClient.get(modulesPath);
    return response.toModel(ActivitiesDashboardModel.fromJson);
  }

  @override
  Future<void> answerLesson({
    required String moduleId,
    required String lessonId,
    required String selectedOptionId,
  }) async {
    await _apiClient.post(
      answerPath(moduleId, lessonId),
      data: {'selectedOptionId': selectedOptionId},
    );
  }
}
