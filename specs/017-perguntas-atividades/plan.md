# Implementation Plan: Perguntas do módulo de atividades

**Branch**: `017-perguntas-atividades` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-perguntas-atividades/spec.md`

**Base**: tarefa B2 do [tasks do produto](../../.specify/memory/tasks.md),
[especificação do produto](../../.specify/memory/specification.md) 2.3.0 (RF-024, RF-027, RF-040,
CB-012, RN-006), [contrato da API](../../.specify/memory/api-contract.md) 1.0.10,
[constituição](../../.specify/memory/constitution.md), código das features 007, 009, 010, 014 e
015.

## Summary

Trocar a tela provisória do módulo (`/activities/:moduleId`) pela tela das perguntas:

- **Dados** ([R0](research.md#r0-conferência-no-servidor-real), [R2](research.md#r2-entidades-só-com-o-que-a-b2-usa),
  [R3](research.md#r3-respondida-para-conta-e-para-visitante)): `GET /app/educational/modules/{id}`
  no datasource da B1; lições válidas (≥ 2 alternativas), na ordem; "respondida" do serviço com
  conta e do registro da sessão sem conta (`GuestProgressStore.isAnswered`). Sem `explanation` nem
  pontuação (B3/B4).
- **Navegação** ([R4](research.md#r4-navegação-guiada)): `LessonController` começa na primeira não
  respondida; voltar é livre; avançar só com a atual respondida.
- **Voz** ([R5](research.md#r5-leitura-em-voz-alta-botão-compartilhado),
  [R6](research.md#r6-leitura-automática)): "Ouvir" com o `ReadAloudController` do `common`; botão
  extraído do `ReadAloudBar` da notícia para `core/widgets/listen_button.dart`; leitura automática
  a cada vez que a pergunta aparece na tela.
- **Tela** ([R7](research.md#r7-estados), [R8](research.md#r8-layout)): posição e marcas, imagem,
  enunciado, alternativas numeradas, rodapé com Anterior/Próxima; carregando, erro e "sem
  atividades".

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes (`dio` via `ApiClient`, `fpdart`, `get_it`, `provider`,
`go_router`, `easy_localization`, `lucide_icons_flutter`, `flutter_tts` via
`TextToSpeechService`). Nenhuma nova.

**Storage**: nenhum. O "respondida" do visitante vem do `GuestProgressStore` (memória, B1).

**Testing**: `flutter_test`; `FakeHttpClientAdapter`; `FakeTextToSpeechService`
(`test/fakes/`); `UserSessionService` real no registro; fakes de datasource e repositório da B1
estendidos; widget tests com `pumpLocalized`.

**Target Platform**: Android e iOS · **Project Type**: mobile-app

**Performance Goals**: primeira pergunta em até 2 s com o servidor acordado (SC-001).

**Constraints**: 48 dp/16 sp, semântica, letra e alto contraste da B9 (RNF-003/004); visitante
sem token; textos pt-BR/en-US; módulos não se importam; a `explanation` nunca aparece antes da
resposta (FR-016).

**Scale/Scope**: no `activities`, ~10 arquivos novos (entidades, model, falha, usecase,
controller, página, 2 widgets) e ajustes no datasource, repositório, registro, rotas e módulo;
`core/widgets/listen_button.dart` novo e `ReadAloudBar` (news) passando a usá-lo; ~7 chaves de i18n
novas e 2 removidas; ~6 arquivos de teste novos e 4 ajustados.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo no `activities` nas três camadas; controller só com usecase (a voz pelo `ReadAloudController` do `common`, como na notícia, permitido pela constituição 1.2.0); nada importa o `news`: o botão compartilhado vai para o `core`. | ✅ |
| II. SOLID, DRY, KISS | Botão "Ouvir" extraído em vez de copiado (R5); entidades só com o que é usado (R2); regra "sem conta = registro" no repositório, como na B1. | ✅ |
| III. TDD | Testes antes do código para model, datasource, registro, repositório, controller, `ListenButton` e página. | ✅ |
| IV. Stack e DI | Sem dependência nova; usecase e controller no `ActivitiesModule`. | ✅ |
| V. Erros tipados | `ModuleNotFoundFailure` por código em constante; estados por enum; textos por chave. | ✅ |
| Regras globais | Nada gravado; mudança em `news` (feature 010) e `core` justificada (R5) e coberta pelos testes da notícia. | ✅ |

**Pós-design (Phase 1)**: reavaliado; sem desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/017-perguntas-atividades/
├── spec.md · plan.md · research.md (R0–R9) · data-model.md · quickstart.md
├── contracts/lesson-page.md
├── checklists/requirements.md
└── tasks.md                     # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                         # + common_listen/stop, activities_lesson_*; − news_detail_listen/stop
├── core/widgets/listen_button.dart                    # NOVO (R5)
├── modules/news/presentation/widgets/read_aloud_bar.dart   # usa o ListenButton
└── modules/activities/
    ├── activities_module.dart · activities.dart       # usecase/controller; barrel com LessonPage
    ├── data/datasources/activities_remote_data_source(_impl).dart   # + getModuleDetail
    ├── data/datasources/guest_progress_store.dart      # + isAnswered
    ├── data/models/module_detail_model.dart            # NOVO
    ├── data/repositories/activities_repository_impl.dart # + getModuleDetail
    ├── domain/entities/module_detail_entity.dart · lesson_entity.dart   # NOVOS
    ├── domain/failures/activities_failures.dart        # NOVO (ModuleNotFoundFailure)
    ├── domain/repositories/activities_repository.dart  # + getModuleDetail
    ├── domain/usecases/get_module_detail_usecase.dart   # NOVO
    └── presentation/
        ├── controller/lesson_controller.dart · lesson_status.dart       # NOVOS
        ├── extensions/lesson_presentation.dart         # NOVO: texto lido em voz alta (US3)
        ├── pages/lesson_page.dart                      # NOVO; activity_module_page.dart REMOVIDO
        ├── widgets/lesson_progress_indicator.dart · lesson_option_card.dart  # NOVOS
        └── routes/activities_routes.dart               # :moduleId → LessonPage
assets/translations/{pt-BR,en-US}.json

test/modules/activities/{data,domain,presentation} · test/core/widgets/listen_button_test.dart ·
test/helpers/activities_dependencies.dart (+ controller da lição) · test/core/routing/app_router_test.dart
```

**Structure Decision**: continua no `activities`, como a B1; só o botão de ouvir sobe para o
`core`, porque passa a ter dois usos (notícia e perguntas).

## Fora do código

- **Avisar o outro desenvolvedor**: `ReadAloudBar` (feature 010) passa a usar o `ListenButton`, e
  as chaves `news_detail_listen/stop` viram `common_listen/stop`.
- **B3**: marcar a lição atual como respondida depois da resposta (libera "Próxima"), tornar as
  alternativas escolhíveis, gravar a resposta do visitante (`recordAnswer`) e mostrar a explicação.
- **Tasks do produto**: ao fechar, marcar a B2 e anotar que `explanation` e `progress` ficaram
  para a B3/B4 (R2).

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; `ListenButton` com o `ReadAloudBar` migrado (testes da notícia verdes);
   entidades, model, falha, datasource, `isAnswered`, repositório, usecase, módulo.
2. **US1 (ver as perguntas)**: controller (carga, início na não respondida), página com posição,
   imagem, enunciado e alternativas; rota.
3. **US2 (navegar)**: anterior/próxima com a regra da clarificação; marcas de progresso.
4. **US3 (ouvir)**: "Ouvir"/"Parar", leitura automática a cada pergunta que aparece, parar ao trocar e ao
   sair, sem voz.
5. **US4 (estados)**: carregando com aviso, erro, "sem atividades".
6. **Polimento**: `/revisar-pr` na própria branch antes do PR, analyze, suíte, quickstart no
   aparelho, marcar a B2.

Um commit por história.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Mudar o `news` (feature 010) | O botão "Ouvir" passa a ter dois usos e sobe para o `core` | Copiar viola o Princípio II; importar o `news` viola o Princípio I |
