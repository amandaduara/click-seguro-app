---

description: "Task list for feature 007: serviços de plataforma e voz"
---

# Tasks: Serviços de plataforma e voz

**Input**: Design documents from `/specs/007-servicos-plataforma-voz/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md),
[contracts/platform-services-api.md](contracts/platform-services-api.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): todo serviço e todo controller têm
teste, escrito e **falhando** antes da implementação. Os testes são offline. Os objetos dos
pacotes são trocados por dublês `class _X extends Fake implements <Classe do pacote>` (`Fake` do
`flutter_test`). Nenhum `*_platform_interface` é importado. Arquivos ficam numa pasta temporária
(`Directory.systemTemp.createTemp`, apagada no `tearDown`). Testes que registram algo no `GetIt`
fazem `GetIt.instance.reset()` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` abrevia `click_seguro_app/`; `cmn/` abrevia
  `click_seguro_app/lib/modules/common/`; `tcmn/` abrevia `click_seguro_app/test/modules/common/`;
  `fakes/` abrevia `click_seguro_app/test/fakes/`.
- Assinaturas exatas no [contrato](contracts/platform-services-api.md); estados e transições no
  [data-model](data-model.md); o porquê de cada decisão no [research](research.md). As tarefas
  citam a fonte em vez de repetir tudo.
- Padrão de arquivo: contrato abstrato + implementação no mesmo arquivo, com dartdoc em
  português, como em `cmn/services/secure_storage_service.dart`. A implementação recebe o objeto
  do pacote por um parâmetro opcional do construtor, com o uso real como padrão
  (`FlutterSecureStorageService([storage])`).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (número de testes, erros, warnings e infos) no fim desta tarefa. Se algo estiver vermelho, parar e reportar **Linha de base (2026-10-07):** 327 testes verdes; analyze com 28 infos, 0 erros, 0 warnings

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: preparar a plataforma para voz e links ([R6](research.md#r6-abrir-endereço-e-ligar), [R9](research.md#r9-permissões-e-manifest)).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Em `app/android/app/src/main/AndroidManifest.xml`, dentro do `<queries>` existente: acrescentar `<intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>` com o comentário `<!-- flutter_tts: encontrar o motor de voz no Android 11+ (R9 da feature 007). -->` e, junto do `VIEW https`, um `<intent>` igual com `<data android:scheme="http"/>`. **Não** acrescentar permissão de câmera (feature 001 R10)

**Checkpoint**: `flutter analyze` sem mudança; `flutter build apk --debug` compila.

---

## Phase 3: User Story 1 - Ouvir um texto em voz alta (Priority: P1) 🎯 MVP

**Goal**: voz no idioma do app, três velocidades, parar, uma leitura por vez, parar ao fechar a tela e esconder o botão sem voz (FR-001 a FR-007, CB-008).

**Independent Test**: `flutter test tcmn/services/text_to_speech_service_test.dart tcmn/presentation/controller/read_aloud_controller_test.dart` verde, cobrindo os 10 cenários da US1.

### Testes (escrever primeiro e ver falhar)

- [X] T003 [P] [US1] Criar `tcmn/services/text_to_speech_service_test.dart` com um `_FakeFlutterTts extends Fake implements FlutterTts`. O dublê guarda os handlers recebidos em `setStartHandler`/`setCompletionHandler`/`setCancelHandler`/`setErrorHandler`, registra as chamadas a `stop`, `setLanguage`, `setSpeechRate` e `speak` (em ordem) e permite configurar o retorno de `isLanguageAvailable` e de `speak` ou fazê-los lançar. Testar:
  - `SpeechLanguage.fromLocale`: `Locale('pt','BR')` → `ptBr`, `Locale('en','US')` → `enUs`, `Locale('en')` → `enUs`, `Locale('es')` → `ptBr`; `ptBr.tag == 'pt-BR'`, `enUs.tag == 'en-US'`;
  - `isAvailable(SpeechLanguage.ptBr)` chama `isLanguageAvailable('pt-BR')`. Retorno `true` → `true`. `false`, `null` ou exceção → `false`;
  - `speak('Olá', language: enUs, speed: ReadingSpeed.slow)` chama, nesta ordem, `stop`, `setLanguage('en-US')`, `setSpeechRate(0.4)` e `speak('Olá')`. Com `normal` a taxa é `0.5` e com `fast` é `0.6`;
  - o `Future` de `speak` só completa depois do aviso de início seguido do aviso de fim, e devolve `true`. Início seguido de cancelamento devolve `false`. O erro devolve `false` mesmo sem início;
  - **evento atrasado** ([R2](research.md#r2-voz-flutter_tts-sem-stream-de-estado)): com a leitura A pendente, chamar `speak('B')`. O `Future` de A completa com `false`. Um cancelamento disparado **antes** do início de B não completa B. Depois do início de B, o fim completa B com `true`;
  - `speak` do plugin devolvendo `0` ou lançando → `false` sem esperar aviso;
  - **texto longo** ([R2](research.md#r2-voz-flutter_tts-sem-stream-de-estado)): um texto de cerca de 9000 caracteres, em frases terminadas por `.`, vira 3 chamadas ao `speak` do plugin, cada uma com até 3900 caracteres e terminando em fim de frase. A segunda parte só é pedida depois do início e do fim da primeira, e o `Future` só completa com `true` depois do fim da última. Sem nenhum `.`, o corte é no último espaço. Um `stop()` durante a primeira parte devolve `false` e não pede as seguintes;
  - `stop()` chama o `stop` do plugin e não lança quando o plugin lança
- [X] T004 [P] [US1] Criar `tcmn/presentation/controller/read_aloud_controller_test.dart` com o `FakeTextToSpeechService` (T005) e um contador de `notifyListeners` (`addListener`). Um teste por cenário da US1:
  1. com `availableLanguages = {ptBr}`, `prepare(Locale('pt','BR'))` → `isAvailable == true`;
  2. com o conjunto vazio → `isAvailable == false`; e **antes** do `prepare`, `isAvailable == false`;
  3. `speak('texto')` → o fake recebe `('texto', ptBr, normal)` e `isSpeaking == true`;
  4. durante a leitura, `stop()` → `isSpeaking == false` na hora e `stopCalls == 1`;
  5. `fake.finishSpeaking()` → `isSpeaking == false` sozinho;
  6. `speak('A')` e depois `speak('B')` → o fake recebe as duas leituras, o fim atrasado de A **não** marca "parado" (B continua `isSpeaking == true`) e só o fim de B marca "parado";
  7. `setSpeed(ReadingSpeed.fast)` durante uma leitura não a interrompe, e a próxima `speak` usa `fast`;
  8. `dispose()` durante a leitura chama o `stop` do serviço. Um controller **parado** descartado não chama o `stop` (não corta a leitura de outra página, [R3](research.md#r3-readaloudcontroller));
  9. `prepare(Locale('en','US'))` depois de `ptBr` verifica `enUs` (indisponível → `isAvailable == false`), e a próxima `speak` usa `enUs`. Um segundo `prepare` com o mesmo idioma não consulta o serviço de novo (cache);
  10. `fake.failSpeaking()` → `isSpeaking == false`, sem exceção.

  Bordas: `speak('')` e `speak('   ')` não chamam o serviço. `speak` com `isAvailable == false` não chama o serviço. `speed` começa `normal`.

### Implementação

- [X] T005 [P] [US1] Criar `fakes/fake_text_to_speech_service.dart` (`FakeTextToSpeechService implements TextToSpeechService`) conforme a tabela de fakes do [contrato](contracts/platform-services-api.md#fakes-para-as-trilhas--testfakes): `Set<SpeechLanguage> availableLanguages`, `int availabilityChecks`, `List<({String text, SpeechLanguage language, ReadingSpeed speed})> spoken`, `int stopCalls`. `speak` devolve o `Future` de um `Completer<bool>` pendente. `finishSpeaking()` completa com `true` e `failSpeaking()` com `false`. `stop()` completa o pendente com `false`. Um novo `speak` completa o anterior com `false`, para simular o motor real
- [X] T006 [US1] Criar `cmn/services/text_to_speech_service.dart` conforme o [contrato](contracts/platform-services-api.md#texttospeechservice--commonservicestext_to_speech_servicedart) e o [R2](research.md#r2-voz-flutter_tts-sem-stream-de-estado)/[R4](research.md#r4-velocidades)/[R5](research.md#r5-idioma-da-voz):
  - `enum ReadingSpeed { slow, normal, fast }`;
  - `enum SpeechLanguage { ptBr('pt-BR'), enUs('en-US') }` com `final String tag` e `static SpeechLanguage fromLocale(Locale locale)`;
  - o contrato abstrato `TextToSpeechService`;
  - `FlutterTextToSpeechService([FlutterTts? tts])`. As taxas vêm de um `switch` exaustivo sobre `ReadingSpeed` (`slow` → 0.4, `normal` → 0.5, `fast` → 0.6), sem `Map` e sem `!`. O limite das partes é a constante `_maxChunkLength = 3900`, e uma função privada divide o texto conforme o R2. O construtor registra os quatro handlers uma vez e guarda `Completer<bool>? _pending` e `bool _started`. `speak` completa o `_pending` anterior com `false` e chama `stop`, `setLanguage(language.tag)` e `setSpeechRate(<taxa>)`. Depois lê as partes em sequência: para cada parte, cria um novo `_pending`, zera `_started`, chama o `speak(parte)` do plugin e espera o `_pending`. Se o retorno do plugin for `0` ou o `_pending` completar com `false`, para e devolve `false`. Um contador de leitura garante que um `speak` novo encerre o laço do anterior. Início → `_started = true`. Fim ou cancelamento só completam se `_started`. Erro completa sempre. Toda exceção vira `false`. `isAvailable` aceita só `result == true`. Nenhum método lança.

  Faz a T003 passar
- [X] T007 [US1] Criar `cmn/presentation/controller/read_aloud_controller.dart` (`ReadAloudController extends ChangeNotifier`) conforme as transições do [data-model](data-model.md#readaloudcontroller-estado) e o [R3](research.md#r3-readaloudcontroller):
  - getters `isAvailable` (inicial `false`), `isSpeaking` e `speed` (inicial `normal`);
  - `prepare(Locale)` usa um cache `Map<SpeechLanguage, bool>`;
  - `speak(String)` ignora `text.trim().isEmpty` e `!isAvailable`, incrementa `_generation`, marca "lendo" e notifica. Quando o `Future` do serviço termina, marca "parado" só se a geração ainda for a mesma e o controller não tiver sido descartado;
  - `stop()` marca "parado", notifica e chama o serviço;
  - `setSpeed` muda a velocidade e notifica;
  - `dispose()` chama `_tts.stop()` (sem `await` e sem notificar) **só se** `isSpeaking`.

  Sem `BuildContext`. Faz a T004 passar
- [X] T008 [US1] Criar `tcmn/common_module_test.dart` (com `TestWidgetsFlutterBinding.ensureInitialized()`, porque o `FlutterTts()` registra um canal de plataforma, `SharedPreferences.setMockInitialValues({})`, `GetIt.instance.reset()` no `setUp`/`tearDown` e `await CommonModule().registerServices(GetIt.instance)`) testando que `GetIt.instance<TextToSpeechService>()` é `FlutterTextToSpeechService` e que dois `GetIt.instance<ReadAloudController>()` são instâncias diferentes (factory). Em `cmn/common_module.dart`, acrescentar `injector.registerLazySingleton<TextToSpeechService>(() => FlutterTextToSpeechService())` e `injector.registerFactory(() => ReadAloudController(injector<TextToSpeechService>()))`

**Checkpoint**: testes da US1 e suíte inteira verdes. Commit da Base + US1 (T002–T008).

---

## Phase 4: User Story 2 - Abrir a notícia original e ligar (Priority: P1)

**Goal**: abrir só http/https no navegador externo, saber se dá para ligar e abrir o discador com o número limpo (FR-008 a FR-011, CB-009).

**Independent Test**: `flutter test tcmn/services/external_launcher_service_test.dart` verde.

### Testes (escrever primeiro e ver falhar)

- [X] T009 [P] [US2] Criar `tcmn/services/external_launcher_service_test.dart`:
  - `isOpenableWebUrl`: `true` para `https://www.gov.br/noticia` e `http://exemplo.com`; `false` para `''`, `'   '`, `www.gov.br`, `ftp://exemplo.com`, `mailto:a@b.com`, `javascript:alert(1)`, `https://` (sem host) e `'::nao é url'`;
  - `normalizePhoneNumber`: `'(11) 9 1234-5678'` → `'11912345678'`, `'+55 (11) 91234-5678'` → `'+5511912345678'`, `'190'` → `'190'`, `'1+2'` → `'12'` (o `+` só vale no início), e `''`, `'()- '` e `'+'` → `null`;
  - a implementação usa funções injetadas que registram o `Uri` e o `LaunchMode` recebidos. `openUrl('https://www.gov.br')` chama `launchUrl` com `LaunchMode.externalApplication` e devolve o retorno dele. Endereço inválido devolve `false` **sem** chamar `launchUrl`. `launchUrl` devolvendo `false` ou lançando → `false`;
  - `call('(11) 9 1234-5678')` chama `launchUrl` com `Uri(scheme: 'tel', path: '11912345678')`. Número sem dígitos → `false` sem chamar. Exceção → `false`;
  - `canCall()` repassa o retorno de `canLaunchUrl` para um `Uri` `tel:`. Exceção → `false`

### Implementação

- [X] T010 [P] [US2] Criar `fakes/fake_external_launcher_service.dart` (`FakeExternalLauncherService implements ExternalLauncherService`): `bool canCallResult = true`, `bool openResult = true`, `List<String> openedUrls`, `List<String> calledNumbers`. `openUrl` e `call` registram o argumento e devolvem `openResult`
- [X] T011 [US2] Criar `cmn/services/external_launcher_service.dart` conforme o [contrato](contracts/platform-services-api.md#externallauncherservice--commonservicesexternal_launcher_servicedart) e o [R6](research.md#r6-abrir-endereço-e-ligar):
  - funções públicas `bool isOpenableWebUrl(String url)` (aceita só os esquemas `http`/`https`, guardados em constantes) e `String? normalizePhoneNumber(String raw)`;
  - contrato `ExternalLauncherService`;
  - `UrlLauncherExternalLauncherService({Future<bool> Function(Uri, {LaunchMode mode})? launch, Future<bool> Function(Uri)? canLaunch})`, com padrão nas funções `launchUrl`/`canLaunchUrl` do `url_launcher`. O `canCall` consulta `Uri(scheme: 'tel', path: '0')`. Nenhum método lança.

  Faz a T009 passar
- [X] T012 [US2] Em `cmn/common_module.dart`, registrar `injector.registerLazySingleton<ExternalLauncherService>(() => UrlLauncherExternalLauncherService())` e acrescentar a verificação do tipo em `tcmn/common_module_test.dart`

**Checkpoint**: testes da US2 e suíte verdes. Commit da US2 (T009–T012).

---

## Phase 5: User Story 3 - Compartilhar uma notícia (Priority: P2)

**Goal**: menu nativo com o texto. Cancelar não é erro (FR-012).

**Independent Test**: `flutter test tcmn/services/share_service_test.dart` verde.

### Testes (escrever primeiro e ver falhar)

- [X] T013 [P] [US3] Criar `tcmn/services/share_service_test.dart` com `_FakeSharePlus extends Fake implements SharePlus`, que guarda o `ShareParams` recebido e devolve um `ShareResult('', status)` configurável, ou lança:
  - `shareText('Golpe do Pix', subject: 'Click Seguro')` passa `text` e `subject`;
  - os status `success` e `unavailable` resultam em `ShareOutcome.shared`, e `dismissed` em `cancelled` ([R7](research.md#r7-compartilhar));
  - exceção → `failed`;
  - `shareText('')` e `shareText('  ')` → `failed` **sem** chamar `share`

### Implementação

- [X] T014 [P] [US3] Criar `fakes/fake_share_service.dart` (`FakeShareService implements ShareService`): `ShareOutcome outcome = ShareOutcome.shared`, `List<({String text, String? subject})> shared`
- [X] T015 [US3] Criar `cmn/services/share_service.dart` conforme o [contrato](contracts/platform-services-api.md#shareservice--commonservicesshare_servicedart): `enum ShareOutcome { shared, cancelled, failed }`, o contrato `ShareService` e `SharePlusShareService([SharePlus? sharePlus])` (padrão `SharePlus.instance`) com `share(ShareParams(text:, subject:))` e o mapeamento por `switch` exaustivo em `ShareResultStatus`. Não lança. Faz a T013 passar
- [X] T016 [US3] Em `cmn/common_module.dart`, registrar `injector.registerLazySingleton<ShareService>(() => SharePlusShareService())` e acrescentar a verificação em `tcmn/common_module_test.dart`

**Checkpoint**: testes da US3 e suíte verdes. Commit da US3 (T013–T016).

---

## Phase 6: User Story 4 - Escolher a foto de um contato ou do perfil (Priority: P2)

**Goal**: galeria ou câmera, cópia reduzida com nome único na pasta do app, desistência e permissão negada distintas, apagar sem erro (FR-013 a FR-016, CB-010).

**Independent Test**: `flutter test tcmn/services/image_storage_service_test.dart` verde.

### Testes (escrever primeiro e ver falhar)

- [ ] T017 [P] [US4] Criar `tcmn/services/image_storage_service_test.dart` com:
  - `_FakeImagePicker extends Fake implements ImagePicker`. O `pickImage` guarda `source`, `maxWidth`, `maxHeight`, `imageQuality` e `requestFullMetadata`, e devolve um `XFile` de um arquivo criado na pasta temporária, `null`, ou lança;
  - uma função de pasta que devolve a pasta temporária do teste.

  Testar:
  - `pickImage(PhotoSource.gallery)` usa `ImageSource.gallery`, e `camera` usa `ImageSource.camera`. Os dois usam `maxWidth: 1024`, `maxHeight: 1024`, `imageQuality: 85` e `requestFullMetadata: false`;
  - sucesso → `PickedImage` com `path` dentro de `<tmp>/images/`, nome começando por `img_` e com a extensão da origem (`.png` continua `.png`; sem extensão vira `.jpg`). O arquivo existe e tem o mesmo conteúdo da origem;
  - duas escolhas seguidas do mesmo arquivo → dois caminhos diferentes, os dois existindo;
  - `null` → `PickImageCancelled`;
  - `PlatformException(code: 'photo_access_denied')` e `PlatformException(code: 'camera_access_denied')` → `PickImagePermissionDenied`. `PlatformException(code: 'already_active')` e outras exceções → `PickImageFailed`;
  - `delete` de uma cópia guardada apaga o arquivo. Apagar de novo não lança. Um arquivo **fora** de `<tmp>/images/` (criado no teste) **não** é apagado

### Implementação

- [ ] T018 [P] [US4] Criar `fakes/fake_image_storage_service.dart` (`FakeImageStorageService implements ImageStorageService`): `PickImageResult nextResult = PickImageCancelled()`, `List<PhotoSource> pickedSources`, `List<String> deletedPaths`
- [ ] T019 [US4] Criar `cmn/services/image_storage_service.dart` conforme o [contrato](contracts/platform-services-api.md#imagestorageservice--commonservicesimage_storage_servicedart), o [data-model](data-model.md#foto-guardada-arquivo) e o [R8](research.md#r8-fotos-escolher-reduzir-e-guardar):
  - `enum PhotoSource { gallery, camera }`;
  - `sealed class PickImageResult` com `PickedImage(this.path)`, `PickImageCancelled`, `PickImagePermissionDenied` e `PickImageFailed` (`final class`, construtores `const`);
  - o contrato `ImageStorageService`;
  - `PlatformImageStorageService({ImagePicker? picker, Future<Directory> Function()? appDirectory})`, com padrão `ImagePicker()` e `getApplicationDocumentsDirectory`. Constantes nomeadas: `_maxSide = 1024.0`, `_quality = 85`, `_folder = 'images'`, `_prefix = 'img_'`, `_defaultExtension = '.jpg'` e `_deniedCodes = {'photo_access_denied', 'camera_access_denied'}`;
  - cria a pasta se não existir. O nome é `img_<DateTime.now().microsecondsSinceEpoch><ext>`, com sufixo `_1`, `_2`… se já existir. Copia com `XFile.saveTo`;
  - os caminhos são montados com `Platform.pathSeparator` (`dart:io`), sem o pacote `path`, que não é dependência direta;
  - `delete` só apaga se `File(path).absolute.path` começar com `<pasta images absoluta> + Platform.pathSeparator`. Ignora quando o caminho está fora da pasta, o arquivo não existe ou há erro.

  Nenhum método lança. Faz a T017 passar
- [ ] T020 [US4] Em `cmn/common_module.dart`, registrar `injector.registerLazySingleton<ImageStorageService>(() => PlatformImageStorageService())` e acrescentar a verificação em `tcmn/common_module_test.dart`

**Checkpoint**: testes da US4 e suíte verdes. Commit da US4 (T017–T020).

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T021 Criar `app/lib/dev/platform_services_playground.dart`, a tela de validação no aparelho ([quickstart §2](quickstart.md#2-no-aparelho-android-físico-ios-se-disponível)). Ela tem `main` próprio, como `app/lib/style_guide/style_guide.dart`, **não** é importada pelo app. Antes do `runApp`, registra o `CommonModule` com `ModuleManager().registerModules([CommonModule()])` e obtém serviços e `ReadAloudController` pelo `GetIt.instance` (Princípio IV; valida também o registro real). Comentário no topo: "Só para desenvolvimento: `flutter run -t lib/dev/platform_services_playground.dart`". Os textos são fixos, por ser ferramenta de desenvolvimento e não parte do produto (registrado no plano). Seções:
  - **Voz**: "Voz disponível: sim/não" a partir de `ReadAloudController.prepare(Localizations.localeOf(context))`, um `SegmentedButton` lenta/normal/rápida, os textos A (curto) e B (mais de 4000 caracteres, para testar a leitura em partes) com "Ouvir" e "Parar", e o estado "lendo/parado";
  - **Links**: campo de endereço com "Abrir fonte" e o resultado; campo de telefone com "Pode ligar?" e "Ligar";
  - **Compartilhar**: botão e o `ShareOutcome`;
  - **Fotos**: "Galeria", "Câmera", o resultado (caminho, tamanho em px com `decodeImageFromList`, ou o tipo do resultado), a miniatura e "Apagar".

  O controller é descartado no `dispose` da tela
- [ ] T022 Formatar só os arquivos tocados (`dart format` com os caminhos de `cmn/services/`, `cmn/presentation/`, `cmn/common_module.dart`, `app/lib/dev/`, `fakes/` e os testes novos), depois rodar `flutter analyze` (sem avisos novos em relação à T001) e `flutter test` (todos verdes). Revisar o código de produção em busca de código morto ou que só os testes usam (prática do projeto) e anotar o resultado
- [ ] T023 Validar no aparelho os 19 passos do [quickstart.md](quickstart.md#2-no-aparelho-android-físico-ios-se-disponível) e anotar no fim desta tarefa o resultado de cada um
- [ ] T024 Em `.specify/memory/tasks.md`, marcar F0.5 como `[x]` com `(specs/007-servicos-plataforma-voz)` e, na linha do `ReadAloudController`, trocar `rate` por `speed` (nome do contrato). Commit de docs marcando as tarefas

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depois do Setup. Bloqueia as histórias (o manifest vale para US1 e US2 no aparelho).
- **US1–US4 (Phases 3–6)**: depois da Foundational. São independentes entre si: arquivos próprios, e só o `common_module.dart`/`common_module_test.dart` é compartilhado.
- **Polish (Phase 7)**: depois de todas. A T021 usa os quatro serviços.

### User Story Dependencies

- **US1 (P1)**: nenhuma. Cria o `common_module_test.dart` (T008), que as outras histórias estendem.
- **US2 (P1)**, **US3 (P2)**, **US4 (P2)**: nenhuma dependência de código de outra história. A tarefa de registro (T012, T016, T020) depende da T008 existir, por causa do arquivo de teste do módulo.

### Within Each User Story

- Teste do serviço/controller (falhando) → fake → implementação → registro no `CommonModule`.
- Na US1, o teste do controller (T004) depende do fake (T005) para compilar. Escreva os dois e veja o teste falhar antes da T007.

### Parallel Opportunities

- **US1:** T003 ∥ T004 ∥ T005.
- **US2:** T009 ∥ T010.
- **US3:** T013 ∥ T014.
- **US4:** T017 ∥ T018.
- Os testes e fakes das quatro histórias podem ser escritos em paralelo, mas os commits seguem a ordem US1 → US4 (um por história) e as tarefas de registro (T008, T012, T016, T020) são sequenciais, porque editam o mesmo arquivo.

---

## Parallel Example: User Story 1

```bash
Task: "Teste do FlutterTextToSpeechService em click_seguro_app/test/modules/common/services/text_to_speech_service_test.dart"
Task: "Teste do ReadAloudController em click_seguro_app/test/modules/common/presentation/controller/read_aloud_controller_test.dart"
Task: "FakeTextToSpeechService em click_seguro_app/test/fakes/fake_text_to_speech_service.dart"
```

## Parallel Example: fakes das trilhas

```bash
Task: "FakeExternalLauncherService em click_seguro_app/test/fakes/fake_external_launcher_service.dart"
Task: "FakeShareService em click_seguro_app/test/fakes/fake_share_service.dart"
Task: "FakeImageStorageService em click_seguro_app/test/fakes/fake_image_storage_service.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): voz + `ReadAloudController`.
3. **PARAR e VALIDAR**: testes da US1 verdes. A A5 e a B2 já podem usar a voz.

### Incremental Delivery

1. Setup + Foundational → manifest pronto.
2. US1 → voz (MVP; libera A5 e B2).
3. US2 → abrir fonte e ligar (libera A4, A5 e B6).
4. US3 → compartilhar (libera A5).
5. US4 → fotos (libera B6 e B7).
6. Polish → tela de desenvolvimento, aparelho, marcar F0.5. Depois a PR para `develop`.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [USn] mapeia a tarefa para a história da [spec](spec.md).
- Verifique que o teste falha antes de implementar.
- Um commit por história (Base + US1, US2, US3, US4) e um commit de docs no fim. As mensagens
  são Conventional Commits em português, com o trailer `Co-Authored-By`. O
  `click_seguro_app/devtools_options.yaml` fica de fora.
- Nenhum serviço lança: se um teste precisar de `expect(..., throwsA(...))`, o desenho está
  errado ([R1](research.md#r1-formato-dos-contratos-resultados-tipados-nunca-exceção)).
- Sem chaves de i18n novas: os textos das telas ficam com A4, A5, B2, B6 e B7.
- O `dart format` em pastas inteiras reformata arquivos fora do escopo: formate só os arquivos
  tocados pela tarefa.
- Ponto em aberto da spec (voz da notícia sempre em português?): **não** bloqueia esta feature e
  deve ser decidido antes da A5.
