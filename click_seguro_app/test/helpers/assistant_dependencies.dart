import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_image_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_text_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/send_chat_message_usecase.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_image_storage_service.dart';
import '../fakes/fake_text_to_speech_service.dart';
import '../modules/assistant/fakes/fake_assistant_repository.dart';

FakeAssistantRepository registerAssistantDependencies(
  GetIt injector, {
  FakeAssistantRepository? repository,
  ImageStorageService? imageStorage,
  TextToSpeechService? tts,
  AccessibilityPreferencesNotifier? preferences,
}) {
  final fake = repository ?? FakeAssistantRepository();
  final storage = imageStorage ?? FakeImageStorageService();
  final AccessibilityPreferencesNotifier accessibility =
      preferences ?? AccessibilityPreferencesNotifier();
  final TextToSpeechService voice = tts ?? FakeTextToSpeechService();
  // A tela lê as respostas em voz alta com a leitura automática ligada.
  if (!injector.isRegistered<AccessibilityPreferencesNotifier>()) {
    injector.registerSingleton(accessibility);
  }
  injector
    ..registerFactory(
      () => ReadAloudController(voice, preferences: accessibility),
    )
    ..registerSingleton<AssistantRepository>(fake)
    ..registerSingleton(SendChatMessageUseCase(fake))
    ..registerSingleton(AnalyzeTextUseCase(fake))
    ..registerSingleton(AnalyzeImageUseCase(fake))
    ..registerSingleton(GetAiHistoryUseCase(fake))
    ..registerFactory(
      () => AssistantController(
        sendChatMessage: injector<SendChatMessageUseCase>(),
        analyzeText: injector<AnalyzeTextUseCase>(),
        analyzeImage: injector<AnalyzeImageUseCase>(),
        getAiHistory: injector<GetAiHistoryUseCase>(),
        imageStorage: storage,
      ),
    );
  return fake;
}

AssistantController createAssistantController(
  AssistantRepository repository,
  ImageStorageService imageStorage,
) => AssistantController(
  sendChatMessage: SendChatMessageUseCase(repository),
  analyzeText: AnalyzeTextUseCase(repository),
  analyzeImage: AnalyzeImageUseCase(repository),
  getAiHistory: GetAiHistoryUseCase(repository),
  imageStorage: imageStorage,
);
