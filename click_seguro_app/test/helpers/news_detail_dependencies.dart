import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_detail_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/mark_news_as_read_usecase.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_text_to_speech_service.dart';
import '../modules/news/fakes/fake_news_repository.dart';

/// O que a rota `/news/:id` busca no `GetIt` (usecases e voz), com fakes. Para
/// testes que abrem o detalhe pelo roteador do app.
void registerNewsDetailDependencies(GetIt injector) {
  final repository = FakeNewsRepository();
  final preferences = AccessibilityPreferencesNotifier();
  final tts = FakeTextToSpeechService();
  injector
    ..registerSingleton(GetNewsDetailUseCase(repository))
    ..registerSingleton(MarkNewsAsReadUseCase(repository))
    ..registerSingleton(preferences)
    ..registerFactory(() => ReadAloudController(tts, preferences: preferences));
}
