# Implementation Plan: Resposta e feedback das atividades

**Branch**: `018-resposta-feedback-atividades` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-resposta-feedback-atividades/spec.md`

**Base**: tarefa B3 do [tasks do produto](../../.specify/memory/tasks.md),
[especificação do produto](../../.specify/memory/specification.md) 2.3.0 (RF-025 a RF-028,
RF-040, RN-005, RN-006), [contrato da API](../../.specify/memory/api-contract.md) 1.0.10,
[constituição](../../.specify/memory/constitution.md), código das features 015 (B1) e 017 (B2).

## Summary

Tornar as perguntas da B2 respondíveis:

- **Dados** ([R0](research.md#r0-conferência-no-servidor-real), [R2](research.md#r2-entidades-novas-e-o-que-entra-agora),
  [R4](research.md#r4-gravar-a-resposta-do-visitante)): `POST …/answer` devolvendo
  `AnswerResultEntity`; sem conta, o repositório grava no `GuestProgressStore` (agora com
  `isCorrect`).
- **Pontuação** ([R3](research.md#r3-pontuação-depois-de-responder-sem-trocar-as-alternativas)):
  depois da resposta, o usecase pede o detalhe do módulo e usa **só** o `score` (cada `GET`
  embaralha as alternativas; a tela não troca as lições). Com conta, a do serviço; sem conta, a do
  registro.
- **Erros** ([R5](research.md#r5-erros-ao-responder)): alternativa recusada ou lição sumida →
  `AnswerRejectedFailure` → recarrega o módulo; outras falhas mantêm a escolha.
- **Tela** ([R1](research.md#r1-um-controller-só-lessoncontroller), [R6](research.md#r6-estado-da-pergunta-na-visita)–[R9](research.md#r9-voz-no-feedback)):
  o `LessonController` ganha escolha, confirmar, resultado por pergunta na visita e responder de
  novo; alternativas escolhíveis; rodapé com "Confirmar resposta"; painel de feedback que não fecha
  sem querer, com pontuação e voz.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes (`dio` via `ApiClient`, `fpdart`, `get_it`, `provider`,
`go_router`, `easy_localization`, `lucide_icons_flutter`, `flutter_tts` via
`TextToSpeechService`). Nenhuma nova.

**Storage**: nenhum. O registro do visitante continua só em memória (`GuestProgressStore`, B1).

**Testing**: `flutter_test`; `FakeHttpClientAdapter`; `FakeTextToSpeechService`; fakes de
datasource e repositório do `activities` (`test/modules/activities/fakes`) estendidos com
`answerLesson`; `UserSessionService` real no registro; widget tests com `pumpLocalized`.

**Target Platform**: Android e iOS · **Project Type**: mobile-app

**Performance Goals**: feedback em até 2 s depois de confirmar, com o servidor acordado (SC-001).

**Constraints**: alternativas nunca reordenadas nem trocadas (RF-027, R3); explicação só depois
da correção (FR-018); correta/errada com ícone e texto, não só cor; 48 dp/16 sp, semântica, letra
e alto contraste da B9 (RNF-003/004); visitante sem token; textos pt-BR/en-US; módulos não se
importam.

**Scale/Scope**: no `activities`, ~8 arquivos novos (3 entidades, model, usecase, extensão,
rodapé, painel) e ajustes em datasource, registro, `GuestAnswer`, model do detalhe, repositório,
falhas, controller, card de alternativa, página e módulo; ~13 chaves de i18n; ~5 arquivos de
teste novos e ~8 ajustados (inclusive os da B1 que chamam `recordAnswer`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo no `activities` nas três camadas; controller só com usecases (a voz pelo `ReadAloudController` do `common`, como na B2); gravar o visitante e calcular a pontuação dele ficam no repositório. | ✅ |
| II. SOLID, DRY, KISS | Um controller só (R1); `LessonOptionCard` estendido em vez de outro widget de alternativa (R8); `ListenButton` e `SlowRequestNotice` reaproveitados; só os campos usados (R2). | ✅ |
| III. TDD | Testes antes do código para models, datasource, registro, repositório, usecase, controller, card, rodapé, painel e página. | ✅ |
| IV. Stack e DI | Sem dependência nova; `AnswerLessonUseCase` e controller no `ActivitiesModule`. | ✅ |
| V. Erros tipados | `AnswerRejectedFailure` por códigos em constante; resultado do confirmar por enum (`AnswerAttempt`); textos por chave. | ✅ |
| Regras globais | Nada gravado em disco; nenhum outro módulo alterado. | ✅ |

**Pós-design (Phase 1)**: reavaliado; sem desvio novo. O único afastamento do `tasks.md` do
produto (sem `QuizController` nem `MultipleChoiceWidget` separados) está justificado no R1 e no R8
e não fere a constituição.

## Project Structure

### Documentation (this feature)

```text
specs/018-resposta-feedback-atividades/
├── spec.md · plan.md · research.md (R0–R10) · data-model.md · quickstart.md
├── contracts/lesson-answer.md
├── checklists/requirements.md
└── tasks.md                     # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                          # + activities_answer_*, activities_feedback_*, activities_option_*
└── modules/activities/
    ├── activities_module.dart                          # + AnswerLessonUseCase; controller com ele
    ├── data/datasources/activities_remote_data_source(_impl).dart   # answerLesson → AnswerResultModel
    ├── data/datasources/guest_progress_store.dart       # recordAnswer(isCorrect), correctCount
    ├── data/models/answer_result_model.dart             # NOVO
    ├── data/models/module_detail_model.dart             # + progress.score/totalScore
    ├── data/repositories/activities_repository_impl.dart # + answerLesson; score sem conta
    ├── domain/entities/answer_result_entity.dart        # NOVO
    ├── domain/entities/module_score_entity.dart         # NOVO
    ├── domain/entities/answer_outcome.dart              # NOVO
    ├── domain/entities/guest_answer.dart                # + isCorrect
    ├── domain/entities/module_detail_entity.dart        # + score
    ├── domain/failures/activities_failures.dart         # + AnswerRejectedFailure
    ├── domain/repositories/activities_repository.dart   # + answerLesson
    ├── domain/usecases/answer_lesson_usecase.dart       # NOVO
    └── presentation/
        ├── controller/lesson_controller.dart            # escolha, confirmar, resultado, responder de novo, score
        ├── extensions/answer_presentation.dart          # NOVO: texto falado do feedback, estado das alternativas
        ├── pages/lesson_page.dart                       # alternativas escolhíveis, painel, SnackBar, voz
        └── widgets/
            ├── lesson_option_card.dart                  # + state, onTap
            ├── confirm_answer_footer.dart               # NOVO (substitui o _NavigationBar da página)
            └── feedback_sheet.dart                      # NOVO
assets/translations/{pt-BR,en-US}.json

test/modules/activities/{data,domain,presentation} · test/modules/activities/fakes ·
test/helpers/activities_dependencies.dart (+ AnswerLessonUseCase)
```

**Structure Decision**: continua no `activities`, como a B1 e a B2. Nada sobe para o `core`: o
painel e o rodapé só têm um uso.

## Fora do código

- **Tasks do produto**: ao fechar, marcar a B3 e anotar para a B4: `ModuleDetailEntity.score` já
  existe; o destino "Voltar às atividades" da última pergunta é o que a B4 troca pela conclusão (e
  pelo aviso de login do visitante); `progress.isCompleted` continua fora.
- **Contrato da API**: anotar no 1.0.11 o R0 (embaralha a cada `GET`; `EDUCATIONAL_INVALID_OPTION`
  e `EDUCATIONAL_LESSON_NOT_FOUND` conferidos).
- **Outro desenvolvedor**: nada compartilhado muda (só o `activities`).

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; entidades (`AnswerResultEntity`, `ModuleScoreEntity`, `AnswerOutcome`,
   `GuestAnswer.isCorrect`, `ModuleDetailEntity.score`); models; datasource; registro;
   `AnswerRejectedFailure`; repositório; usecase; módulo e fakes.
2. **US1 (escolher e confirmar)**: controller (`select`, `confirm`, `isSubmitting`); card
   escolhível; rodapé com "Confirmar resposta".
3. **US2 (feedback)**: resultado na visita, lição concluída, `canGoNext`; painel (não fecha sem
   querer, próxima/última); estados correta/errada nas alternativas.
4. **US3 (pontuação e progresso)**: `score` no controller e no painel; visitante gravado; painel
   de atividades atualizado na volta.
5. **US4 (responder de novo)**: `answerAgain`; pergunta respondida antes da visita.
6. **US6 (erros)**: falha comum, rejeitada (recarrega), envio demorado, sair no meio.
7. **US5 (voz no feedback)**: "Ouvir" no painel, leitura automática, parar ao confirmar/fechar.
8. **Polimento**: `/revisar-pr` na própria branch antes do PR, analyze, suíte, quickstart no
   aparelho, contrato 1.0.11 e marcar a B3.

Um commit por história.

## Complexity Tracking

Sem violações da constituição.
