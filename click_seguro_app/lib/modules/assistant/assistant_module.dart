import 'dart:async';

import 'package:click_seguro_app/modules/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:click_seguro_app/modules/assistant/data/datasources/assistant_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_image_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_text_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/send_chat_message_usecase.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

class AssistantModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<AssistantRemoteDataSource>(
        () => AssistantRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<AssistantRepository>(
        () => AssistantRepositoryImpl(injector<AssistantRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => SendChatMessageUseCase(injector<AssistantRepository>()),
      )
      ..registerLazySingleton(
        () => AnalyzeTextUseCase(injector<AssistantRepository>()),
      )
      ..registerLazySingleton(
        () => AnalyzeImageUseCase(injector<AssistantRepository>()),
      )
      ..registerLazySingleton(
        () => GetAiHistoryUseCase(injector<AssistantRepository>()),
      )
      ..registerFactory(
        () => AssistantController(
          sendChatMessage: injector<SendChatMessageUseCase>(),
          analyzeText: injector<AnalyzeTextUseCase>(),
          analyzeImage: injector<AnalyzeImageUseCase>(),
          getAiHistory: injector<GetAiHistoryUseCase>(),
          imageStorage: injector<ImageStorageService>(),
        ),
      );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) => [];
}
