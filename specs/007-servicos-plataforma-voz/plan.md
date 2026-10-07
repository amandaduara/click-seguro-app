# Implementation Plan: Serviços de plataforma e voz

**Branch**: `007-servicos-plataforma-voz` | **Date**: 2026-10-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-servicos-plataforma-voz/spec.md`

**Base**: tarefa F0.5 do [tasks do produto](../../.specify/memory/tasks.md),
[plano do produto](../../.specify/memory/plan.md) §3.3 e §5,
[especificação do produto](../../.specify/memory/specification.md) v2.2.0 (RF-013, RF-015 a
RF-017, RF-032 a RF-036, RF-040, RF-042, CB-008 a CB-010, RN-007),
[constituição](../../.specify/memory/constitution.md) v1.1.0, permissões da
[feature 001](../001-sessao-persistente-visitante/research.md) (R10) e padrão de serviços de
`common/services/` (features 001 e 002).

## Summary

Entregar em `lib/modules/common/` os recursos do aparelho que as trilhas vão usar, sem tela nova:

- **Voz** ([R2](research.md#r2-voz-flutter_tts-sem-stream-de-estado)–[R5](research.md#r5-idioma-da-voz)):
  `TextToSpeechService` (`flutter_tts`) com `isAvailable(idioma)`, `speak(texto, idioma,
  velocidade)` que completa no fim da leitura, e `stop`. O `ReadAloudController` (factory, um
  por página) guarda `isAvailable`/`isSpeaking`/`speed`, prepara o idioma a partir do `Locale` do
  app, interrompe a leitura anterior e para no `dispose`. Velocidades `slow/normal/fast` =
  0.4/0.5/0.6.
- **Abrir e ligar** ([R6](research.md#r6-abrir-endereço-e-ligar)): `ExternalLauncherService`
  (`url_launcher`) com `openUrl` (só http/https, navegador externo), `canCall` e `call` (dígitos e
  `+`).
- **Compartilhar** ([R7](research.md#r7-compartilhar)): `ShareService` (`share_plus`) →
  `ShareOutcome { shared, cancelled, failed }`.
- **Fotos** ([R8](research.md#r8-fotos-escolher-reduzir-e-guardar)): `ImageStorageService`
  (`image_picker` + `path_provider`) com `pickImage(PhotoSource)` → `PickImageResult` (sealed) e
  `delete(path)`. Reduz para ≤ 1024 px no próprio picker e copia para `documentos/images/`.
- **Robustez** ([R1](research.md#r1-formato-dos-contratos-resultados-tipados-nunca-exceção)):
  nenhum serviço lança; toda falha vira um resultado tipado.
- **Plataforma** ([R9](research.md#r9-permissões-e-manifest)): `<queries>` do Android ganha
  `TTS_SERVICE` (sem ele a voz pareceria indisponível no Android 11+) e `VIEW http`.
- **Base para as trilhas** ([R10](research.md#r10-registro-e-testes)): registro no
  `CommonModule` e quatro fakes em `test/fakes/`.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes desde a F0.1: `flutter_tts` 4.2.5, `url_launcher` 6.3.2,
`share_plus` 13.3.0, `image_picker` 1.2.3, `path_provider` 2.1.6, além de `get_it`, `provider`.
Nenhuma dependência nova.

**Storage**: arquivos de foto em `<documentos do app>/images/` (sem backup, feature 001 R10).
Nada em `shared_preferences`/secure storage; a velocidade fica em memória (F0.6/B9 persiste).

**Testing**: `flutter_test`, testes de unidade offline. Dublês dos objetos dos pacotes
(`Fake implements FlutterTts/ImagePicker/SharePlus`), funções do `url_launcher` injetadas, pasta
temporária para as fotos; `ReadAloudController` com `FakeTextToSpeechService`.

**Target Platform**: Android e iOS (a voz no Chrome não é alvo).

**Project Type**: mobile-app

**Performance Goals**: leitura começa e para em até 1 s (SC-002).

**Constraints**: nenhum serviço lança (FR-017); sem permissão nova no Android; foto ≤ 1024 px;
sem `BuildContext` no controller; `common/` ainda é da Fase 0 (pode ser editado).

**Scale/Scope**: 4 serviços + 1 controller (5 arquivos em `lib/`), 1 ajuste de manifest, 1
registro no `CommonModule`, 4 fakes, cerca de 6 arquivos de teste e 1 tela de desenvolvimento
para validar no aparelho.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo no módulo `common` (`services/` e `presentation/controller/`), registrado em `CommonModule.registerServices`. As trilhas consomem pelo `GetIt` sem importar outros módulos. O `ReadAloudController` fala direto com o serviço, sem usecase: não há regra de negócio nem dados, e um usecase de repasse seria abstração vazia (mesmo critério do `requireAccount` na feature 005; plano do produto §5). | ✅ (justificado) |
| II. SOLID, DRY, KISS | Um contrato por capacidade; um único `pickImage(PhotoSource)` no lugar de dois métodos; redução da foto pelo próprio picker (sem pacote `image`); sem stream de estado no TTS. Tratamento de erro centralizado nos serviços, não repetido nas cinco telas. | ✅ |
| III. TDD | Testes antes do código: `ReadAloudController` (10 cenários da US1), cada implementação com dublês dos pacotes (caminho feliz, falha, borda), `normalizePhoneNumber` e `isOpenableWebUrl`. Tudo offline. | ✅ |
| IV. Stack e DI | Só pacotes já no `pubspec` (F0.1). Serviços registrados pelo tipo abstrato (`registerLazySingleton<T>`), o controller como factory. `ChangeNotifier` com getters somente leitura. | ✅ |
| V. Erros tipados, sem strings mágicas | Resultados por enum (`ShareOutcome`, `ReadingSpeed`, `SpeechLanguage`, `PhotoSource`) e sealed class (`PickImageResult`); códigos `photo_access_denied`/`camera_access_denied` e taxas de voz em constantes nomeadas. Sem `ApiException` aqui (não há API). | ✅ |
| Regras globais | Sem segredo; sem `dynamic` público (o retorno `dynamic` do `flutter_tts` é convertido na implementação); sem `!` especulativo; UI das trilhas usa GetIt só para obter o controller/serviço. | ✅ |

**Pós-design (Phase 1)**: reavaliado após o data-model e o contrato. Continua sem violação. A
tela de desenvolvimento (`lib/dev/`) não é importada pelo app, como o style guide.

## Project Structure

### Documentation (this feature)

```text
specs/007-servicos-plataforma-voz/
├── spec.md
├── plan.md                         # este arquivo
├── research.md                     # R1–R10
├── data-model.md                   # tipos de valor, foto guardada, estados do ReadAloudController
├── quickstart.md                   # testes + roteiro no aparelho
├── contracts/
│   └── platform-services-api.md    # API pública dos 4 serviços, do controller e dos fakes
├── checklists/requirements.md
└── tasks.md                        # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── dev/
│   └── platform_services_playground.dart        # NOVO: main próprio, só para validar no aparelho
└── modules/common/
    ├── common_module.dart                       # + 4 serviços (lazy singleton) + ReadAloudController (factory)
    ├── services/
    │   ├── text_to_speech_service.dart          # NOVO: ReadingSpeed, SpeechLanguage, contrato + FlutterTextToSpeechService
    │   ├── external_launcher_service.dart       # NOVO: contrato + UrlLauncherExternalLauncherService, normalizePhoneNumber, isOpenableWebUrl
    │   ├── share_service.dart                   # NOVO: ShareOutcome, contrato + SharePlusShareService
    │   └── image_storage_service.dart           # NOVO: PhotoSource, PickImageResult, contrato + PlatformImageStorageService
    └── presentation/controller/
        └── read_aloud_controller.dart           # NOVO
android/app/src/main/AndroidManifest.xml         # <queries>: + TTS_SERVICE, + VIEW http

test/
├── fakes/
│   ├── fake_text_to_speech_service.dart         # NOVO
│   ├── fake_external_launcher_service.dart      # NOVO
│   ├── fake_share_service.dart                  # NOVO
│   └── fake_image_storage_service.dart          # NOVO
└── modules/common/
    ├── services/
    │   ├── text_to_speech_service_test.dart     # NOVO
    │   ├── external_launcher_service_test.dart  # NOVO
    │   ├── share_service_test.dart              # NOVO
    │   └── image_storage_service_test.dart      # NOVO
    └── presentation/controller/
        └── read_aloud_controller_test.dart      # NOVO
```

**Structure Decision**: segue o §3.3 e o §5 do plano do produto: serviços em
`common/services/` (padrão contrato + implementação no mesmo arquivo, como
`secure_storage_service.dart`) e o controller de voz em `common/presentation/controller/`. O
`common` ganha a pasta `presentation/` pela primeira vez, seguindo o nome obrigatório da
constituição. A tela de validação fica em `lib/dev/`, fora dos módulos, com `main` próprio como o
`style_guide`. Sem textos traduzidos novos: os textos das telas ficam com A4/A5/B2/B6/B7. A tela
de desenvolvimento usa textos fixos por não ser parte do produto.

## Fora do código (documentos do produto)

- **Plano do produto §3.3**: atualizar a tabela de métodos. `TextToSpeechService` passa a ter
  `isAvailable(idioma)`, `speak(texto, idioma, velocidade)` → fim da leitura e `stop`, sem stream.
  `ImageStorageService` passa a ter `pickImage(origem)` → resultado tipado e `delete(path)`.
  `ShareService` passa a ter `shareText(texto, assunto?)` → `ShareOutcome`. Feito junto com este
  plano.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: manifest (`TTS_SERVICE`, `VIEW http`); pasta `common/presentation/controller/`.
2. **US1 (voz)**: `TextToSpeechService` + impl + fake + teste; `ReadAloudController` + teste
   (10 cenários); registro no `CommonModule`.
3. **US2 (abrir e ligar)**: `ExternalLauncherService` + funções puras + impl + fake + testes;
   registro.
4. **US3 (compartilhar)**: `ShareService` + impl + fake + teste; registro.
5. **US4 (fotos)**: `ImageStorageService` + impl + fake + teste com pasta temporária; registro.
6. **Polimento**: tela de desenvolvimento, analyze, suíte inteira, roteiro do quickstart no
   aparelho, marcar F0.5 no tasks do produto.

Um commit por história, como nas features anteriores.

## Complexity Tracking

Nenhuma violação a justificar. O `ReadAloudController` sem usecase está justificado no
Constitution Check (Princípio I).
