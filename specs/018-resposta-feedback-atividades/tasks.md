---

description: "Task list for feature 018: resposta e feedback das atividades"
---

# Tasks: Resposta e feedback das atividades

**Input**: Design documents from `/specs/018-resposta-feedback-atividades/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/lesson-answer.md](contracts/lesson-answer.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeHttpClientAdapter` no datasource;
`FakeTextToSpeechService` (`app/test/fakes/fake_text_to_speech_service.dart`, com `spoken` e
`stopCalls`) na voz; `UserSessionService(FakeSecureStorageService())` real no registro e no
repositório; fakes em `tact/fakes/` estendidos; widget tests com `pumpLocalized` e
`GetIt.instance.reset()` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `act/` =
  `click_seguro_app/lib/modules/activities/`; `tact/` = `click_seguro_app/test/modules/activities/`.
- Campos, regras e chaves no [data-model](data-model.md); tela e serviço no
  [contrato](contracts/lesson-answer.md); decisões no [research](research.md).
- JSON de teste no formato do R0: módulo `m1` "Golpes Digitais", lições `l1`, `l2`, `l3`,
  alternativas `o1`… (na `l1`, `o1` é a correta); resposta
  `answerJson({isCorrect, correctOptionId = 'o1', explanation})`.
- Visual: design system do app, cores por `context.colors`. Marcada: borda 2 `colors.primary` e
  ícone `LucideIcons.circleDot`; correta: borda e ícone `LucideIcons.circleCheck` em
  `colors.success`; errada: borda e ícone `LucideIcons.circleX` em `colors.destructive`. Painel:
  fundo `colors.card`, título 20/700 com o ícone da cor do resultado, explicação 16
  `colors.textForeground`.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, `git fetch` e conferir se a `develop` tem algo novo (se tiver, parar e avisar: o outro desenvolvedor pode mexer em `activities`, `core` ou nas traduções); rodar `flutter analyze` e `flutter test` e anotar a linha de base no fim desta tarefa. **Linha de base (2026-10-22):** `develop` sem novidades (abertos só #20 e #21); `flutter test` 1479 verdes; `flutter analyze` 27 issues, todos `info`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, entidades, dados e usecase da resposta.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Em `tact/fakes/activities_fixtures.dart`, acrescentar `answerJson({bool isCorrect = true, String correctOptionId = 'o1', String? explanation = 'Explicação da l1'})` e permitir `progress` no `moduleDetailJson` (`score`, `totalScore`). Criar `tact/data/models/answer_result_model_test.dart`: lê `isCorrect`, `correctOptionId` e `explanation`; `explanation` ausente ou vazia → `null`. Em `tact/data/models/module_detail_model_test.dart`: `progress {score: 2, totalScore: 3}` → `score` (2, 3); `totalScore` 0 → `score` `null` ("nunca 0 de 0"); `progress` ausente → `null`
- [X] T003 [P] Em `tact/data/datasources/activities_remote_data_source_impl_test.dart`: `answerLesson(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o2')` → `POST /app/educational/modules/m1/lessons/l1/answer` com corpo `{selectedOptionId: 'o2'}`, com token (conta) e sem token (visitante), devolvendo o `AnswerResultModel`; 400 `EDUCATIONAL_INVALID_OPTION` sobe como `ApiException` com o código
- [X] T004 [P] Em `tact/data/datasources/guest_progress_store_test.dart`: `recordAnswer(..., isCorrect: true)` guarda o acerto; `correctCount('m1')` conta só as certas do módulo; a mesma lição respondida errada depois → `correctCount` diminui (vale a mais recente); outro módulo não conta; a transferência (`pendingTransfer`) continua com a alternativa escolhida. Ajustar as chamadas existentes de `recordAnswer` neste arquivo e em `tact/data/repositories/activities_repository_impl_test.dart` para passar `isCorrect`
- [X] T005 [P] Em `tact/data/repositories/activities_repository_impl_test.dart`, grupo "responder": conta → `Right(AnswerResultEntity)` e **nada** no registro; visitante → `Right` e `recordAnswer` com o `isCorrect` do serviço (`correctCount` 1); sessão expirada → como visitante; 400 `EDUCATIONAL_INVALID_OPTION`, 400 `VALIDATION_ERROR`, 404 `EDUCATIONAL_LESSON_NOT_FOUND` e 404 `EDUCATIONAL_MODULE_NOT_FOUND` → `Left(AnswerRejectedFailure)` e nada gravado; conexão → `Left(ConnectionFailure)` e nada gravado. Grupo "detalhe do módulo": conta → `score` do `progress`; visitante sem respostas → `score` `null`; visitante com `l1` certa e `l2` errada → `score` (1, número de lições válidas). Em `tact/fakes/fake_activities_remote_data_source.dart`, `answerLesson` passa a devolver `answerJson` configurável por lição (`answerResults`) e continua usando `answerErrors`
- [X] T006 [P] Criar `tact/domain/usecases/answer_lesson_usecase_test.dart` com o `FakeActivitiesRepository`: sucesso → `Right(AnswerOutcome)` com o resultado e o `score` do `getModuleDetail` seguinte; `getModuleDetail` falha → `Right` com `score` `null`; `answerLesson` falha → `Left` com a mesma falha e **sem** chamar `getModuleDetail`

### Implementação

- [X] T007 Chaves de i18n em `app/lib/core/i18n/app_strings.dart` (bloco das atividades) e em `app/assets/translations/pt-BR.json` e `en-US.json`, conforme o [data-model §4](data-model.md#4-i18n-pt-br--en-us): `activitiesAnswerConfirm`, `activitiesAnswerAgain`, `activitiesAnswerFailed`, `activitiesAnswerRejected`, `activitiesFeedbackCorrect`, `activitiesFeedbackWrong`, `activitiesFeedbackCorrectOption`, `activitiesFeedbackExplanation`, `activitiesFeedbackScore`, `activitiesFeedbackNext`, `activitiesFeedbackFinish`, `activitiesOptionCorrect`, `activitiesOptionWrong` (en-US: "Confirm answer", "Answer again", "Could not send your answer. Try again.", "This question was updated. We reloaded the activities.", "You got it right!", "Not this time", "Correct answer: {}", "Why?", "You have {} of {} right", "Next question", "Back to activities", "correct", "your answer, wrong")
- [X] T008 [P] Criar em `act/domain/entities/`: `answer_result_entity.dart` (`AnswerResultEntity {isCorrect, correctOptionId, explanation?}`), `module_score_entity.dart` (`ModuleScoreEntity {score, total}`, "`total > 0` sempre") e `answer_outcome.dart` (`AnswerOutcome {result, score?}`); em `guest_answer.dart`, `+ isCorrect`; em `module_detail_entity.dart`, `+ ModuleScoreEntity? score`. Em `act/domain/failures/activities_failures.dart`, `AnswerRejectedFailure` (mensagem `AppStrings.activitiesAnswerRejected`). Em `act/domain/repositories/activities_repository.dart`, `answerLesson({moduleId, lessonId, selectedOptionId})` → `Either<Failure, AnswerResultEntity>`
- [X] T009 [P] Criar `act/data/models/answer_result_model.dart` (`fromJson` → `toEntity()`); em `act/data/models/module_detail_model.dart`, ler `progress.score`/`progress.totalScore` (`totalScore` ausente ou 0 → `null`) e atualizar o comentário do topo (só `explanation`, `description`, `iconUrl` e `progress.isCompleted` ignorados). Faz a T002 passar
- [X] T010 Em `act/data/datasources/activities_remote_data_source.dart` + `_impl.dart`: `answerLesson` devolve `Future<AnswerResultModel>` (atualizar o comentário: usado pela B3 e pela transferência). Em `act/data/datasources/guest_progress_store.dart`: `recordAnswer(..., required bool isCorrect)` e `int correctCount(String moduleId)`. Faz a T003 e a T004 passar
- [X] T011 Em `act/data/repositories/activities_repository_impl.dart`: `answerLesson` (sem conta → `_store.recordAnswer` com o `isCorrect`; códigos do [R5](research.md#r5-erros-ao-responder) em constante → `AnswerRejectedFailure`; demais → `toFailure()`); em `getModuleDetail`, sem conta, `score = ModuleScoreEntity(_store.correctCount(moduleId), lessons.length)` quando `_store.answeredCount(moduleId) > 0`, senão `null`; a transferência (`_sendPending`) ignora o retorno. Faz a T005 passar
- [X] T012 Criar `act/domain/usecases/answer_lesson_usecase.dart` (`AnswerLessonUseCase(repository).call({moduleId, lessonId, selectedOptionId})`, [R3](research.md#r3-pontuação-depois-de-responder-sem-trocar-as-alternativas)); em `tact/fakes/fake_activities_repository.dart`, `answerLesson` com fila `answerResults`, `answerCalls` (lista dos pedidos) e `answerGate`; registrar o usecase em `act/activities_module.dart` e passá-lo ao `LessonController` (`answerLesson:`), e em `app/test/helpers/activities_dependencies.dart`. Faz a T006 passar

**Checkpoint**: `flutter analyze` limpo; testes de models, datasource, registro, repositório e usecase verdes; testes da B1 (painel, transferência) verdes.

---

## Phase 3: User Story 1 - Escolher e confirmar a resposta (Priority: P1) 🎯 MVP

**Goal**: alternativas escolhíveis e "Confirmar resposta" no rodapé, enviando uma vez
(FR-001 a FR-004, FR-021).

**Independent Test**: passo 1 do [quickstart](quickstart.md) e o envio da alternativa certa.

### Testes (escrever primeiro e ver falhar)

- [X] T013 [P] [US1] Em `tact/presentation/controller/lesson_controller_test.dart`, grupo "escolher e confirmar": `selectedOptionId` `null` e `canConfirm` falso no início; `select('o2')` → marcada e `canConfirm`; `select('o3')` troca; `confirm()` chama o usecase com `m1`/`l1`/`o3`, `isSubmitting` verdadeiro durante (`answerGate`) e falso depois; dois `confirm()` seguidos → um envio só (o segundo devolve `AnswerAttempt.ignored`); `select` durante o envio não muda nada; `confirm()` sem escolha → `ignored` e nenhum envio; `dispose` durante o envio não lança
- [X] T014 [P] [US1] Criar `tact/presentation/widgets/lesson_option_card_test.dart`: `state: idle` sem marcação; `selected` com ícone `circleDot` e semântica `checked` + `inMutuallyExclusiveGroup`; toque chama `onTap`; `onTap` nulo → sem toque e semântica desativada; altura ≥ 48; texto longo quebra linha com letra 2×
- [X] T015 [US1] Em `tact/presentation/pages/lesson_page_test.dart` (helper com `AnswerLessonUseCase` sobre o fake), grupo "responder": "Confirmar resposta" desativado sem escolha; tocar na alternativa 2 marca e ativa; trocar para a 3; confirmar → o fake recebe `o3` uma vez, mesmo com dois toques; durante o envio o botão mostra `loading` e as alternativas não respondem a toque; as alternativas continuam na ordem do JSON antes e depois (RF-027); visitante consegue confirmar

### Implementação

- [X] T016 [US1] Em `act/presentation/controller/lesson_controller.dart`: dependência `AnswerLessonUseCase`; mapa privado `LessonAnswerState` por `lessonId`; `selectedOptionId`, `isSubmitting`, `canSelect`, `canConfirm`, `select()`, `Future<AnswerAttempt> confirm()` com `enum AnswerAttempt { answered, failed, rejected, ignored }` (por enquanto só `answered`/`ignored`; guardar o resultado é da US2), conforme o [data-model §3](data-model.md#lessoncontroller-b2-estendido-factory). Faz a T013 passar
- [X] T017 [P] [US1] Em `act/presentation/widgets/lesson_option_card.dart`: `enum LessonOptionState { idle, selected, correct, wrong }`, parâmetros `state` (padrão `idle`) e `onTap`; `InkWell` com o raio do cartão; visual "marcada" do topo deste arquivo; `Semantics(inMutuallyExclusiveGroup: true, checked: state == selected, enabled: onTap != null)`; remover o comentário "Só leitura nesta feature". Faz a T014 passar
- [X] T018 [US1] Criar `act/presentation/widgets/confirm_answer_footer.dart` (`ConfirmAnswerFooter`: `SafeButton` "Confirmar resposta" com `loading: controller.isSubmitting` e `onPressed` nulo sem `canConfirm`, e abaixo a linha "Anterior"/"Próxima" que hoje é o `_NavigationBar` de `act/presentation/pages/lesson_page.dart`, que sai). Na página: cada `LessonOptionCard` com `state: selected` para a escolhida e `onTap: controller.canSelect ? () => controller.select(id) : null`; o botão chama `_confirm()`, que para a leitura em andamento e chama `controller.confirm()`. Faz a T015 passar

**Checkpoint**: testes da lição verdes. Commit da Base + US1.

---

## Phase 4: User Story 2 - Ver se acertou, a correta e a explicação (Priority: P1)

**Goal**: resultado guardado, lição concluída, "Próxima" liberado e painel de feedback que não
fecha sem querer (FR-005 a FR-008, FR-018).

**Independent Test**: passos 2, 3 e 5 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T019 [P] [US2] Em `lesson_controller_test.dart`, grupo "resultado": `confirm()` com sucesso → `answered`; `currentResult` com o resultado; a lição atual `isCompleted` (lista do módulo trocada com `withCompleted(true)`, **mesmas alternativas na mesma ordem**); `canGoNext` verdadeiro (exceto na última); `canSelect` falso com resultado; `goNext` → próxima sem escolha; `goPrevious` → volta e `currentResult` reaparece; `isLastLesson` na última
- [X] T020 [P] [US2] Criar `tact/presentation/widgets/feedback_sheet_test.dart` (abrindo pelo `showFeedbackSheet` num botão de teste): acerto → `activitiesFeedbackCorrect` com ícone `circleCheck`; erro → `activitiesFeedbackWrong` com `circleX`; "Resposta correta: <texto da o1>"; explicação sob "Por quê?"; sem explicação → nem título nem espaço; `correctOptionId` fora das alternativas → sem a linha da correta e sem erro; tocar fora (`tapAt` acima do painel) e arrastar para baixo → continua aberto; voltar (`handlePopRoute`) → fecha devolvendo `null`; "Próxima pergunta" → `FeedbackAction.next`; com `isLast` → "Voltar às atividades" → `FeedbackAction.finish`; **dois toques rápidos no botão de seguir → o painel fecha uma vez só e a rota de baixo continua aberta** (sem `pop` duplo, achado U1 da análise); título anunciado (`liveRegion`); explicação longa com letra 2× rola sem estouro
- [X] T021 [US2] Em `lesson_page_test.dart`, grupo "feedback": confirmar a errada `o2` → painel com "Não foi dessa vez"; fechar pelo voltar → alternativas com `o2` `wrong` ("sua resposta, errada") e `o1` `correct` ("correta"), demais sem toque; "Próxima" ativo; indicador com a `l1` concluída. Confirmar a certa → "Você acertou!"; "Próxima pergunta" → "Pergunta 2 de 3" sem marcação. Na última, "Voltar às atividades" → rota `/activities`. A explicação não aparece antes de confirmar (FR-018)

### Implementação

- [X] T022 [US2] Em `lesson_controller.dart`: no sucesso, guardar o resultado no `LessonAnswerState`, trocar a lição atual por `withCompleted(true)` num novo `ModuleDetailEntity` (mesma lista, mesmo título, mesmo `score`), `currentResult`, `resultFor(lessonId)`, `isLastLesson`. Faz a T019 passar
- [X] T023 [P] [US2] Criar `act/presentation/extensions/answer_presentation.dart`: `LessonOptionState optionState(LessonOptionEntity option, {String? selectedOptionId, AnswerResultEntity? result})` (sem resultado: `selected`/`idle`; com resultado: correta → `correct`, escolhida errada → `wrong`, demais `idle`) e `LessonOptionEntity? correctOption` na lição. Em `lesson_option_card.dart`, os visuais `correct`/`wrong` do topo deste arquivo, com o texto `activitiesOptionCorrect`/`activitiesOptionWrong` visível abaixo da alternativa e na semântica
- [X] T024 [US2] Criar `act/presentation/widgets/feedback_sheet.dart`: `enum FeedbackAction { next, finish }`; `Future<FeedbackAction?> showFeedbackSheet(BuildContext, {required LessonEntity lesson, required AnswerResultEntity result, required bool isLast, ModuleScoreEntity? score, Widget? listen})` com `showModalBottomSheet(isDismissible: false, enableDrag: false, isScrollControlled: true, useSafeArea: true)`; conteúdo rolável conforme o [contrato](contracts/lesson-answer.md#2-tela-de-perguntas) (pontuação e `listen` entram na US3/US5) e o botão de seguir (`SafeButton`), que ignora o segundo toque (o primeiro desativa o botão antes do `Navigator.pop`, para um toque duplo não fechar também a tela de perguntas). Faz a T020 passar
- [X] T025 [US2] Em `lesson_page.dart`: estados das alternativas pela extensão; `_confirm()` com `answered` → `showFeedbackSheet`; `next` → `controller.goNext()`; `finish` → `context.pop()` (o painel recarrega pelo `RefreshOnReturnMixin` da B1); `null` → fica. Faz a T021 passar

**Checkpoint**: testes da lição e do painel verdes. Commit da US2. **Nota (2026-10-22):** a T021 achou que, ao seguir para a próxima pergunta, a lista continuava rolada para baixo (o enunciado ficava fora da tela); a `ListView` da pergunta ganhou `PageStorageKey(lesson.id)`, e cada pergunta começa no topo.

---

## Phase 5: User Story 3 - A pontuação e o progresso acompanham as respostas (Priority: P2)

**Goal**: pontuação do serviço (conta) ou do registro (visitante) no painel de feedback; painel de
atividades atualizado (FR-009 a FR-011).

**Independent Test**: passos 4, 5, 7 e 8 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T026 [P] [US3] Em `lesson_controller_test.dart`, grupo "pontuação": `score` do `load` (do módulo); depois de `confirm()` com `AnswerOutcome.score` (2, 3) → `score` (2, 3); com `score` `null` no resultado → mantém o anterior
- [ ] T027 [US3] Em `feedback_sheet_test.dart`: com `score` (1, 3) → "Você está com 1 de 3 acertos"; sem `score` → nenhuma pontuação. Em `lesson_page_test.dart`, grupo "pontuação": nenhuma pontuação na tela das perguntas antes ou depois de responder (só no painel); visitante com o `ActivitiesRepositoryImpl` real sobre o datasource falso: responder `l1` certa → painel "1 de 3" e o `GuestProgressStore` com `correctCount('m1') == 1` e `answeredCount('m1') == 1` (o número que a tela de atividades da B1 lê na volta, SC-007; o recarregar na volta já é testado na B1)

### Implementação

- [ ] T028 [US3] Em `lesson_controller.dart`: `score` inicial do módulo carregado; no sucesso, `score = outcome.score ?? score`. Em `feedback_sheet.dart`, a linha `activitiesFeedbackScore` quando há `score`; a página passa `controller.score`. Faz a T026 e a T027 passar

**Checkpoint**: testes verdes. Commit da US3.

---

## Phase 6: User Story 4 - Responder de novo uma pergunta já respondida (Priority: P2)

**Goal**: "Responder de novo" e pergunta respondida antes da visita respondível (FR-012).

**Independent Test**: passos 3, 4 e 6 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T029 [P] [US4] Em `lesson_controller_test.dart`, grupo "responder de novo": `answerAgain()` apaga `currentResult` e a escolha, mantém a lição concluída e `canGoNext`; depois, `select`/`confirm` enviam de novo e o novo resultado substitui o anterior; lição concluída antes da visita (`isCompleted` do serviço) → sem escolha, `canSelect` verdadeiro, `canGoNext` verdadeiro
- [ ] T030 [US4] Em `lesson_page_test.dart`, grupo "responder de novo": depois do feedback fechado pelo voltar, o rodapé mostra "Responder de novo" no lugar de "Confirmar resposta"; tocar → alternativas sem marcação e tocáveis; escolher e confirmar → novo painel; módulo com `l1` concluída pelo serviço → "Confirmar resposta" e alternativas tocáveis

### Implementação

- [ ] T031 [US4] Em `lesson_controller.dart`: `answerAgain()`. Em `confirm_answer_footer.dart`: com `currentResult`, o botão vira "Responder de novo" (`SafeButtonTone.secondary`) chamando `answerAgain`. Faz a T029 e a T030 passar

**Checkpoint**: testes verdes. Commit da US4.

---

## Phase 7: User Story 6 - Erros ao enviar a resposta (Priority: P2)

**Goal**: falha comum mantém a escolha; recusa recarrega; envio demorado avisa; sair no meio não
quebra (FR-013 a FR-015).

**Independent Test**: passo 10 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T032 [P] [US6] Em `lesson_controller_test.dart`, grupo "erros": `ConnectionFailure` → `failed`, escolha mantida, lição **não** concluída, `canConfirm` de novo; `AnswerRejectedFailure` → `rejected`, `getModuleDetail` chamado de novo, mapa de resultados vazio, índice na primeira não respondida; `AnswerRejectedFailure` seguida de `ModuleNotFoundFailure` no recarregar → `LessonStatus.empty` (US6 cenário 4, achado C1 da análise); `dispose` durante o envio → nenhuma notificação depois
- [ ] T033 [US6] Em `lesson_page_test.dart`, grupo "erros": conexão → `SnackBar` "Não foi possível enviar sua resposta. Tente de novo." e a alternativa continua marcada; recusa → `SnackBar` "Esta pergunta foi atualizada…" e módulo recarregado; envio segurado pelo `answerGate` por mais de alguns segundos → `SlowRequestNotice` com `activitiesSlow` acima do rodapé; sair da página (pop) com o envio segurado e depois liberar → sem exceção

### Implementação

- [ ] T034 [US6] Em `lesson_controller.dart`: `failed` e `rejected` (recarrega com `load(moduleId)` guardado do último `load`, esvaziando o mapa). Em `lesson_page.dart`: `SnackBar` por resultado (padrão de `change_password_page.dart`: `ScaffoldMessenger` guardado antes do `await`, `hideCurrentSnackBar` + `showSnackBar`) e `SlowRequestNotice(active: controller.isSubmitting, message: activitiesSlow)` acima do `ConfirmAnswerFooter`. Faz a T032 e a T033 passar

**Checkpoint**: testes verdes. Commit da US6.

---

## Phase 8: User Story 5 - Ouvir o resultado e a explicação (Priority: P3)

**Goal**: "Ouvir" no painel e leitura automática do feedback; leitura para ao confirmar, seguir e
fechar (FR-016, FR-017).

**Independent Test**: passo 9 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T035 [P] [US5] Em `tact/presentation/extensions/` (arquivo novo `answer_presentation_test.dart`): texto falado = resultado + "Resposta correta: …" + explicação + pontuação, nessa ordem; sem explicação ou sem pontuação → partes omitidas; correta ausente → sem a parte da correta
- [ ] T036 [US5] Em `lesson_page_test.dart`, grupo "voz no feedback" (`FakeTextToSpeechService`): confirmar com leitura em andamento → `stopCalls` aumenta antes do envio; no painel, "Ouvir" lê o texto da T035 e vira "Parar"; leitura automática ligada → o texto do feedback é falado uma vez ao abrir o painel, e a pergunta **não** é lida de novo ao ser marcada concluída; "Próxima pergunta" → para o feedback e lê a pergunta 2; fechar pelo voltar → para; sem voz no idioma → sem "Ouvir" no painel e nada falado

### Implementação

- [ ] T037 [US5] Em `answer_presentation.dart`, `String spokenFeedback(...)` (chaves do data-model §4). Em `lesson_page.dart`: o `ListenButton` do painel com o `ReadAloudController` da página (em `ListenableBuilder`, como o da pergunta), leitura automática do feedback ao abrir (mesma condição do `_maybeAutoRead`: voz disponível e `autoReadAloud` ligado), `stop()` ao fechar com `null` e antes do `goNext`. Faz a T035 e a T036 passar

**Checkpoint**: testes verdes. Commit da US5.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T038 Em `lesson_page_test.dart`, conferir o fluxo inteiro com letra 2× e alto contraste num celular 1080×2340, dpr 3 (alternativas com resultado, rodapé com duas linhas e o painel sem estouro) e em inglês ("Confirm answer", "You got it right!", "Next question")
- [ ] T039 Rodar `/revisar-pr` sobre a branch (antes de abrir o PR: revisar o diff `develop...018-resposta-feedback-atividades` com o mesmo roteiro da skill) e corrigir os achados Alta/Média, anotando aqui o que ficou aceito
- [ ] T040 `flutter analyze` sem novos avisos em relação à linha de base da T001 e `flutter test` inteiro verde; anotar os números aqui
- [ ] T041 Validação no aparelho: os 12 passos do [quickstart](quickstart.md) (a usuária valida); anotar o que falhar como tarefa nova
- [ ] T042 Fechar a feature: marcar a B3 em `.specify/memory/tasks.md` (anotando para a B4: `ModuleDetailEntity.score` pronto; "Voltar às atividades" é o destino que a B4 troca pela conclusão e pelo aviso de login; `progress.isCompleted` ainda fora; sem `QuizController`/`MultipleChoiceWidget`, R1/R8); anotar o R0 no contrato da API como 1.0.11 (`.specify/memory/api-contract.md`: embaralha a cada `GET`; `EDUCATIONAL_INVALID_OPTION` e `EDUCATIONAL_LESSON_NOT_FOUND` conferidos); atualizar as Notes de `checklists/requirements.md` (as decisões já foram clarificadas); marcar as tarefas deste arquivo; commit de docs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depende da T001; bloqueia todas as histórias.
- **US1 (Phase 3)**: depende da Phase 2. É o MVP.
- **US2**: depende da US1 (escolher e confirmar). **US3, US4, US6 e US5** dependem da US2 (resultado
  e painel). Todas mexem no controller e na página, então seguem em sequência
  (US1 → US2 → US3 → US4 → US6 → US5); os testes de controller e de widget marcados [P] podem ser
  escritos antes, em paralelo.
- **Polish (Phase 9)**: depois de todas as histórias.

### Within Each User Story

- Teste escrito e visto falhar antes da implementação.
- Domínio e dados antes do controller; controller antes dos widgets e da página.
- Um commit ao fim de cada história.

### Parallel Opportunities

- Phase 2: T002–T006 juntos; T008 e T009 juntos; T010 → T011 → T012 em sequência.
- US1: T013 e T014 juntos; T017 em paralelo com a T016.
- US2: T019 e T020 juntos; T023 em paralelo com a T022.

## Parallel Example: Foundational

```bash
Task: "T002 answer_result_model_test.dart e progress no module_detail_model_test.dart"
Task: "T003 answerLesson no teste do datasource"
Task: "T004 isCorrect e correctCount no teste do registro"
Task: "T005 grupos responder e detalhe no teste do repositório"
Task: "T006 answer_lesson_usecase_test.dart"
```

## Parallel Example: User Story 2

```bash
Task: "T019 grupo resultado em lesson_controller_test.dart"
Task: "T020 feedback_sheet_test.dart"
```

## Implementation Strategy

### MVP First (User Story 1 + 2)

A US1 sozinha envia a resposta mas não mostra o resultado; o primeiro ponto útil para a pessoa é
US1 + US2 (as duas P1).

1. Phase 1 e Phase 2.
2. Phase 3 (US1): escolher e confirmar. Commit da Base + US1.
3. Phase 4 (US2): painel de feedback e avanço liberado.
4. **Parar e validar**: passos 1–3 e 5 do quickstart.

### Incremental Delivery

1. Base + US1 → escolher e enviar.
2. US2 → feedback (MVP utilizável).
3. US3 → pontuação.
4. US4 → responder de novo.
5. US6 → erros.
6. US5 → voz no feedback.
7. Polish → `/revisar-pr` na branch, suíte, aparelho, B3 marcada.

Cada história é um commit; o PR para a `develop` sai depois da validação no aparelho (T041).
