# Contrato: API pública dos serviços de plataforma e do `ReadAloudController`

**Feature**: [../spec.md](../spec.md) · **Plan**: [../plan.md](../plan.md)

Esta é a interface que as trilhas (A4, A5, B2, B6, B7) consomem. Todos os tipos ficam acessíveis
importando os arquivos de `package:click_seguro_app/modules/common/...` indicados abaixo e são
resolvidos pelo `GetIt` (registrados no `CommonModule`). Nenhum método lança exceção.

## `TextToSpeechService` — `common/services/text_to_speech_service.dart`

```dart
enum ReadingSpeed { slow, normal, fast }

enum SpeechLanguage {
  ptBr('pt-BR'), enUs('en-US');
  final String tag;
  static SpeechLanguage fromLocale(Locale locale); // en → enUs; outro → ptBr
}

abstract class TextToSpeechService {
  /// Há voz para [language] no aparelho. Sem motor, sem voz ou erro → false.
  Future<bool> isAvailable(SpeechLanguage language);

  /// Para a leitura anterior e lê [text]. Completa quando a leitura termina:
  /// true = até o fim; false = interrompida por [stop] ou falha.
  Future<bool> speak(String text, {required SpeechLanguage language, required ReadingSpeed speed});

  Future<void> stop();
}
// Registro: injector.registerLazySingleton<TextToSpeechService>(() => FlutterTextToSpeechService());
```

## `ReadAloudController` — `common/presentation/controller/read_aloud_controller.dart`

```dart
class ReadAloudController extends ChangeNotifier {
  ReadAloudController(TextToSpeechService tts);

  bool get isAvailable;        // false até prepare() terminar
  bool get isSpeaking;
  ReadingSpeed get speed;      // padrão normal

  Future<void> prepare(Locale locale); // verifica a voz no idioma (cache por idioma)
  Future<void> speak(String text);     // ignora vazio e indisponível; interrompe a anterior
  Future<void> stop();
  void setSpeed(ReadingSpeed speed);   // vale para a próxima leitura
  @override void dispose();            // para a leitura
}
// Registro: injector.registerFactory(() => ReadAloudController(injector<TextToSpeechService>()));
```

**Uso esperado numa página (A5/B2)**:

```dart
ChangeNotifierProvider(
  create: (_) => GetIt.I<ReadAloudController>(),
  child: ...,
);
// em didChangeDependencies: context.read<ReadAloudController>().prepare(context.locale);
// botão "Ouvir" só se controller.isAvailable (CB-008).
```

## `ExternalLauncherService` — `common/services/external_launcher_service.dart`

```dart
abstract class ExternalLauncherService {
  /// Abre http/https no navegador do aparelho. Vazio, malformado, outro esquema ou falha → false.
  Future<bool> openUrl(String url);

  /// Existe discador no aparelho. Erro → false (CB-009: a tela mostra o número para copiar).
  Future<bool> canCall();

  /// Abre o discador com o número (só dígitos e '+' inicial). Sem dígitos ou falha → false.
  Future<bool> call(String phoneNumber);
}

String? normalizePhoneNumber(String raw); // "(11) 9 1234-5678" → "11912345678"; "+55 11…" → "+5511…"; sem dígitos → null
bool isOpenableWebUrl(String url);         // esquema http/https e host não vazio

// Registro: injector.registerLazySingleton<ExternalLauncherService>(() => UrlLauncherExternalLauncherService());
```

## `ShareService` — `common/services/share_service.dart`

```dart
enum ShareOutcome { shared, cancelled, failed }

abstract class ShareService {
  /// Abre o menu nativo com [text] (e [subject] opcional). Texto vazio → failed sem abrir.
  Future<ShareOutcome> shareText(String text, {String? subject});
}
// Registro: injector.registerLazySingleton<ShareService>(() => SharePlusShareService());
```

## `ImageStorageService` — `common/services/image_storage_service.dart`

```dart
enum PhotoSource { gallery, camera }

sealed class PickImageResult {}
final class PickedImage extends PickImageResult { final String path; }
final class PickImageCancelled extends PickImageResult {}
final class PickImagePermissionDenied extends PickImageResult {}
final class PickImageFailed extends PickImageResult {}

abstract class ImageStorageService {
  /// Escolhe/tira a foto, reduz para ≤ 1024 px e guarda uma cópia com nome único na pasta do app.
  Future<PickImageResult> pickImage(PhotoSource source);

  /// Apaga uma cópia guardada pelo app. Inexistente ou fora da pasta do app → ignora.
  Future<void> delete(String path);
}
// Registro: injector.registerLazySingleton<ImageStorageService>(() => PlatformImageStorageService());
```

## Fakes para as trilhas — `test/fakes/`

| Fake | Controle no teste |
|---|---|
| `FakeTextToSpeechService` | `availableLanguages` (Set), `spoken` (lista de `(text, language, speed)`), `stopCalls`, `finishSpeaking()`, `failSpeaking()` |
| `FakeExternalLauncherService` | `canCallResult`, `openResult`, `openedUrls`, `calledNumbers` |
| `FakeShareService` | `outcome`, `sharedTexts` |
| `FakeImageStorageService` | `nextResult`, `pickedSources`, `deletedPaths` |

Os nomes exatos dos campos dos fakes podem ser ajustados na implementação. O que vale é cada
fake permitir simular todos os resultados do contrato sem tocar no aparelho (FR-018, SC-005).
