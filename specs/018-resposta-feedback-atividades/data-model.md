# Data Model: Resposta e feedback das atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Research**: [research.md](research.md)

## 1. Domínio (`activities/domain`)

| Entidade | Campos | Regras |
|---|---|---|
| `AnswerResultEntity` (nova) | `isCorrect`, `correctOptionId`, `explanation?` | como o serviço devolveu; `explanation` vazia → `null` |
| `ModuleScoreEntity` (nova) | `score`, `total` | `total > 0` sempre (sem pontuação → a entidade não existe, FR-011) |
| `AnswerOutcome` (nova) | `result: AnswerResultEntity`, `score: ModuleScoreEntity?` | `score` nulo quando a busca falhou ou ainda não há pontuação (R3) |
| `ModuleDetailEntity` (B2) | + `score: ModuleScoreEntity?` | com conta: `progress.score/totalScore` (`totalScore` 0 → `null`); sem conta: do registro (R3) |
| `LessonEntity` (B2) | sem mudança | `withCompleted(true)` marca a lição respondida na tela |
| `GuestAnswer` (B1) | + `isCorrect` | a mais recente de cada lição |

Falha nova (`activities_failures.dart`): `AnswerRejectedFailure`, mensagem
`activities_answer_rejected`, para 400 `EDUCATIONAL_INVALID_OPTION`, 400 `VALIDATION_ERROR`, 404
`EDUCATIONAL_LESSON_NOT_FOUND` e 404 `EDUCATIONAL_MODULE_NOT_FOUND` **no envio da resposta** (R5).

Repositório (`ActivitiesRepository`), novo método:

```text
Future<Either<Failure, AnswerResultEntity>> answerLesson({moduleId, lessonId, selectedOptionId})
```

Usecase novo `AnswerLessonUseCase(repository)`:
`call({moduleId, lessonId, selectedOptionId}) → Either<Failure, AnswerOutcome>`:
`answerLesson`; se `Right`, `getModuleDetail(moduleId)` e usa só o `score` (falha → `score: null`).

## 2. Dados (`activities/data`)

- `AnswerResultModel.fromJson({isCorrect, correctOptionId, explanation?})` → `toEntity()`.
- `ActivitiesRemoteDataSource.answerLesson(...)` passa a devolver `Future<AnswerResultModel>`
  (mesmo `POST answerPath`, corpo `{selectedOptionId}`). A transferência da B1 ignora o retorno.
- `ModuleDetailModel` lê `progress.score` e `progress.totalScore` (ausentes → sem pontuação);
  continua ignorando `explanation`, `description`, `iconUrl` e `progress.isCompleted`.
- `GuestProgressStore`:
  - `recordAnswer({moduleId, lessonId, selectedOptionId, required isCorrect})`;
  - `int correctCount(String moduleId)`: respostas certas (a mais recente de cada lição);
  - `answeredCount`, `isAnswered`, transferência e limpeza: como na B1/B2.
- `ActivitiesRepositoryImpl`:
  - `answerLesson`: `POST`; sem conta (`!isAuthenticated`) → `store.recordAnswer(..., isCorrect)`;
    códigos do R5 → `AnswerRejectedFailure`; demais `ApiException` → `toFailure()`.
  - `getModuleDetail`: sem conta, além do `withCompleted` da B2, `score` =
    `ModuleScoreEntity(store.correctCount(id), lessons.length)` se houver resposta do módulo no
    registro, senão `null`.

## 3. Apresentação (`activities/presentation`)

### `LessonController` (B2, estendido; factory)

Dependências: `GetModuleDetailUseCase`, `AnswerLessonUseCase` (nova).

| Membro | Regra |
|---|---|
| `selectedOptionId` | da pergunta atual nesta visita; `null` sem escolha |
| `resultFor(lessonId)` / `currentResult` | `AnswerResultEntity?` recebido nesta visita |
| `isSubmitting` | envio em andamento |
| `canSelect` | `!isSubmitting && currentResult == null` |
| `canConfirm` | `canSelect && selectedOptionId != null` |
| `score` | última `ModuleScoreEntity` conhecida (do `load` ou da resposta) |
| `isLastLesson` | índice atual é o último |
| `select(optionId)` | só com `canSelect`; troca a escolha |
| `Future<AnswerAttempt> confirm()` | só com `canConfirm`; ver abaixo |
| `answerAgain()` | apaga o resultado da atual (continua concluída) |
| `canGoNext` / `goNext` / `goPrevious` | como na B2 (avançar exige a atual concluída) |

`AnswerAttempt` (enum do controller): `answered`, `failed`, `rejected`, `ignored`.

Transições de `confirm()`:

```text
canConfirm=false ─────────────────────────────────────────► ignored
envio ─ Right(outcome) ─► resultado guardado, lição withCompleted(true),
       │                  score = outcome.score ?? score      ► answered
       ├─ Left(AnswerRejectedFailure) ─► load(moduleId) (esvazia o mapa)  ► rejected
       └─ Left(outra) ─► escolha mantida, lição não muda      ► failed
(disposed no meio) ─► nada notificado
```

`LessonAnswerState` (privado do controller, por `lessonId`): `selectedOptionId?`, `result?`.

### Widgets

| Widget | Papel |
|---|---|
| `LessonOptionCard` (B2, estendido) | + `state: LessonOptionState {idle, selected, correct, wrong}` e `onTap?`; semântica de opção única; ícone e texto além da cor (R8) |
| `ConfirmAnswerFooter` (novo) | rodapé fixo: "Confirmar resposta" (`loading` no envio) ou "Responder de novo", e a linha "Anterior"/"Próxima" da B2 |
| `FeedbackSheet` (novo) | painel: resultado, correta, explicação, pontuação, `ListenButton`, botão de seguir; devolve `FeedbackAction {next, finish}` ou `null` (fechado pelo voltar) |

Extensão de apresentação (`answer_presentation.dart`, nova): texto falado do feedback (R9) e
estado de cada alternativa a partir da escolha e do resultado.

## 4. i18n (pt-BR / en-US)

| Chave | pt-BR |
|---|---|
| `activities_answer_confirm` | Confirmar resposta |
| `activities_answer_again` | Responder de novo |
| `activities_answer_failed` | Não foi possível enviar sua resposta. Tente de novo. |
| `activities_answer_rejected` | Esta pergunta foi atualizada. Carregamos as atividades de novo. |
| `activities_feedback_correct` | Você acertou! |
| `activities_feedback_wrong` | Não foi dessa vez |
| `activities_feedback_correct_option` | Resposta correta: {} |
| `activities_feedback_explanation` | Por quê? |
| `activities_feedback_score` | Você está com {} de {} acertos |
| `activities_feedback_next` | Próxima pergunta |
| `activities_feedback_finish` | Voltar às atividades |
| `activities_option_correct` | correta |
| `activities_option_wrong` | sua resposta, errada |

`activities_slow` (B1) é reaproveitada no envio demorado.
