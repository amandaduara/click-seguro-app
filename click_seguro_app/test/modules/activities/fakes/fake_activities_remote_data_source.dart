import 'dart:async';

import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source.dart';
import 'package:click_seguro_app/modules/activities/data/models/activities_dashboard_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/guest_answer.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

import 'activities_fixtures.dart';

/// Serviço de atividades em memória: [modules] devolve o JSON (ou lança a
/// `ApiException`) e [answerErrors] decide a falha de cada resposta enviada.
class FakeActivitiesRemoteDataSource implements ActivitiesRemoteDataSource {
  Map<String, dynamic> modules = dashboardJson();
  ApiException? modulesError;
  int modulesCalls = 0;

  /// Respostas enviadas, em ordem (inclusive as que falharam).
  final List<GuestAnswer> sent = [];

  /// Falha por `lessonId`; ausente → sucesso.
  final Map<String, ApiException> answerErrors = {};

  /// Quando definido, cada envio só termina ao completar.
  Completer<void>? answerGate;

  /// Ordem das chamadas ("answer"/"modules"), para conferir que a
  /// transferência vem antes da leitura.
  final List<String> calls = [];

  Map<String, dynamic> moduleDetail = moduleDetailJson();
  ApiException? moduleDetailError;
  int moduleDetailCalls = 0;

  @override
  Future<ModuleDetailModel> getModuleDetail(String moduleId) async {
    moduleDetailCalls++;
    final ApiException? error = moduleDetailError;
    if (error != null) throw error;
    return ModuleDetailModel.fromJson(moduleDetail);
  }

  @override
  Future<ActivitiesDashboardModel> getModules() async {
    modulesCalls++;
    calls.add('modules');
    final ApiException? error = modulesError;
    if (error != null) throw error;
    return ActivitiesDashboardModel.fromJson(modules);
  }

  @override
  Future<void> answerLesson({
    required String moduleId,
    required String lessonId,
    required String selectedOptionId,
  }) async {
    calls.add('answer');
    sent.add(
      GuestAnswer(
        moduleId: moduleId,
        lessonId: lessonId,
        selectedOptionId: selectedOptionId,
      ),
    );
    await answerGate?.future;
    final ApiException? error = answerErrors[lessonId];
    if (error != null) throw error;
  }
}

ApiException apiError(
  ApiErrorType type, {
  int? statusCode,
  String? errorCode,
}) => ApiException(
  type: type,
  message: 'falha de teste',
  statusCode: statusCode,
  errorCode: errorCode,
);
