import 'package:click_seguro_app/modules/assistant/assistant_module.dart';
import 'package:click_seguro_app/modules/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_image_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_text_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/send_chat_message_usecase.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../fakes/fake_image_storage_service.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test(
    'registra o grafo da feature e cria controller por página sem request',
    () async {
      final injector = GetIt.instance;
      injector
        ..registerSingleton<ApiClient>(
          ApiClient(dio: Dio(BaseOptions(baseUrl: 'https://api.test'))),
        )
        ..registerSingleton<ImageStorageService>(FakeImageStorageService());
      await AssistantModule().registerServices(injector);

      expect(
        injector<AssistantRemoteDataSource>(),
        isA<AssistantRemoteDataSource>(),
      );
      expect(injector<AssistantRepository>(), isA<AssistantRepository>());
      expect(injector<SendChatMessageUseCase>(), isA<SendChatMessageUseCase>());
      expect(injector<AnalyzeTextUseCase>(), isA<AnalyzeTextUseCase>());
      expect(injector<AnalyzeImageUseCase>(), isA<AnalyzeImageUseCase>());
      expect(injector<GetAiHistoryUseCase>(), isA<GetAiHistoryUseCase>());
      final first = injector<AssistantController>();
      final second = injector<AssistantController>();
      expect(identical(first, second), isFalse);
      expect(first.activeTab.name, 'chat');
      first.dispose();
      second.dispose();
    },
  );
}
