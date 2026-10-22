---

description: "Task list for feature 017: perguntas do módulo de atividades"
---

# Tasks: Perguntas do módulo de atividades

**Input**: Design documents from `/specs/017-perguntas-atividades/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/lesson-page.md](contracts/lesson-page.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeHttpClientAdapter` no datasource;
`FakeTextToSpeechService` (`app/test/fakes/fake_text_to_speech_service.dart`, com `spoken`,
`stopCalls`, `availableLanguages`) na voz; `UserSessionService(FakeSecureStorageService())` real no
registro e no repositório; fakes da B1 em `tact/fakes/` estendidos; widget tests com
`pumpLocalized` e `GetIt.instance.reset()` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `act/` =
  `click_seguro_app/lib/modules/activities/`; `tact/` = `click_seguro_app/test/modules/activities/`.
- Campos, regras e chaves no [data-model](data-model.md); tela no
  [contrato](contracts/lesson-page.md); decisões no [research](research.md).
- JSON de teste no formato do R0: lições `l1`, `l2`, `l3` (ordem 1–3) com alternativas `o1`… e
  `imageUrl`; módulo `m1` "Golpes Digitais".
- Visual: design system do app; cartões das alternativas como os do painel (`colors.card`, borda
  `colors.border`, raio `AppSpacing.radius2xl`), número da alternativa em círculo `colors.primary`
  a 10%, texto 16 `colors.textForeground`; enunciado 18/700 `colors.secondary`. Cores por
  `context.colors`.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, `git fetch` e conferir se a `develop` tem algo novo (se tiver, parar e avisar: o outro desenvolvedor pode mexer em `news` ou `core`); rodar `flutter analyze` e `flutter test` e anotar a linha de base no fim desta tarefa. **Linha de base (2026-10-21):** `develop` sem novidades (abertos só #20 e #21); `flutter test` 1427 verdes; `flutter analyze` 27 issues, todos `info`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, botão de ouvir compartilhado, domínio e dados do detalhe do módulo.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Criar `app/test/core/widgets/listen_button_test.dart`: `ListenButton(isSpeaking: false)` mostra "Ouvir" com ícone `volume2`; `isSpeaking: true` mostra "Parar" com ícone `square`; toque chama `onPressed`; semântica de botão com o rótulo; altura ≥ 48
- [X] T003 [P] Em `tact/fakes/activities_fixtures.dart`, acrescentar `lessonJson({id, order, question, imageUrl, options, isCompleted = false, explanation})` e `moduleDetailJson({id = 'm1', title = 'Golpes Digitais', lessons})` no formato do R0 (com `description`, `iconUrl`, `lessonsCount`, `explanation` e `progress`, que o app ignora). Criar `tact/data/models/module_detail_model_test.dart`: lições ordenadas por `order`; lição com 1 alternativa descartada ("`options.length >= 2`"); alternativa sem `id` ou `text` descartada antes da contagem; alternativas na ordem recebida; `imageUrl` vazio → `null`; `isCompleted` ausente → `false`; lição sem `id` ou `question` descartada
- [X] T004 [P] Em `tact/data/datasources/activities_remote_data_source_impl_test.dart`: `getModuleDetail('m1')` → `GET /app/educational/modules/m1`, com token com conta e sem token como visitante; 404 `EDUCATIONAL_MODULE_NOT_FOUND` sobe como `ApiException` com o código
- [X] T005 [P] Em `tact/data/datasources/guest_progress_store_test.dart`: `isAnswered('l1')` falso antes e verdadeiro depois de `recordAnswer` da `l1`; falso de novo depois de `logout()`
- [X] T006 [P] Em `tact/data/repositories/activities_repository_impl_test.dart`, grupo "detalhe do módulo": conta → `isCompleted` do serviço; visitante → `isCompleted` do registro (`l1` respondida no registro, serviço manda falso → verdadeiro); sessão expirada → como visitante; 404 `EDUCATIONAL_MODULE_NOT_FOUND` → `Left(ModuleNotFoundFailure)`; conexão → `Left(ConnectionFailure)`. Estender `tact/fakes/fake_activities_remote_data_source.dart` com `moduleDetail` (JSON), `moduleDetailError` e `moduleDetailCalls`

### Implementação

- [X] T007 Chaves de i18n em `app/lib/core/i18n/app_strings.dart` e nos dois JSON, conforme o [data-model §4](data-model.md#4-textos-i18n): `commonListen`, `commonStop` (bloco `// --- common ---`), `activitiesLessonPosition`, `activitiesLessonProgressSemantics`, `activitiesLessonPrevious`, `activitiesLessonNext`, `activitiesLessonOptionSpoken`. Remover `newsDetailListen`/`newsDetailStop` e `news_detail_listen`/`news_detail_stop` dos JSON (passam a ser `common_listen`/`common_stop`)
- [X] T008 Criar `app/lib/core/widgets/listen_button.dart`: `ListenButton({required bool isSpeaking, required VoidCallback onPressed})` com o `SafeButton` e o `Semantics` que hoje estão no `ReadAloudBar` (tom `secondary` lendo / `primary` parado, ícone `square`/`volume2`, textos `commonStop`/`commonListen`). Em `app/lib/modules/news/presentation/widgets/read_aloud_bar.dart`, trocar esse trecho pelo `ListenButton`, repassando a `listenKey` (os testes da notícia a usam para achar o botão). Faz a T002 passar; `app/test/modules/news/presentation/pages/news_detail_page_test.dart` continua verde sem mudança
- [X] T009 [P] Criar `act/domain/entities/lesson_entity.dart` (`LessonOptionEntity {id, text}`; `LessonEntity {id, order, question, imageUrl?, options, isCompleted}` com `withCompleted(bool)`) e `act/domain/entities/module_detail_entity.dart` (`{id, title, lessons}`, `isEmpty`); `act/domain/failures/activities_failures.dart` com `ModuleNotFoundFailure` (mensagem `AppStrings.activitiesModuleUnavailable`); em `act/domain/repositories/activities_repository.dart`, `getModuleDetail(String moduleId)`; `act/domain/usecases/get_module_detail_usecase.dart`
- [X] T010 [P] Criar `act/data/models/module_detail_model.dart` (`fromJson` → `toEntity()`, regras do [data-model §2](data-model.md#2-dados-activitiesdata); ignora `explanation`, `progress`, `description`, `iconUrl`). Faz a T003 passar
- [X] T011 Em `act/data/datasources/activities_remote_data_source.dart` + `_impl.dart`: `getModuleDetail(String moduleId)` com `static String moduleDetailPath(String id) => '$modulesPath/$id'` (e `answerPath` passa a usá-lo). Faz a T004 passar
- [X] T012 Em `act/data/datasources/guest_progress_store.dart`: `bool isAnswered(String lessonId) => _answers.containsKey(lessonId);`. Faz a T005 passar
- [X] T013 Em `act/data/repositories/activities_repository_impl.dart`: `getModuleDetail` (sem conta → `withCompleted(_store.isAnswered(id))` em cada lição; 404 com `errorCode == 'EDUCATIONAL_MODULE_NOT_FOUND'` (constante) → `ModuleNotFoundFailure`; demais → `toFailure()`). Atualizar `tact/fakes/fake_activities_repository.dart` com `getModuleDetail` (fila de resultados). Registrar `GetModuleDetailUseCase` em `act/activities_module.dart`. Faz a T006 passar

**Checkpoint**: `flutter analyze` limpo; testes de botão, model, datasource, registro e repositório verdes; suíte da notícia verde.

---

## Phase 3: User Story 1 - Ver as perguntas do módulo, uma por vez (Priority: P1) 🎯 MVP

**Goal**: a tela do módulo mostra a pergunta (posição, imagem, enunciado, alternativas), começando
na primeira não respondida (FR-001 a FR-004, FR-013 a FR-017).

**Independent Test**: passos 1, 9 e 10 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T014 [P] [US1] Criar `tact/presentation/controller/lesson_controller_test.dart` com o `FakeActivitiesRepository`: começa `loading`; `load('m1')` → `loaded` com o módulo; `currentIndex` 0 sem respostas; com `l1` respondida → 1; com todas respondidas → 0; módulo sem lições → `empty`; `ModuleNotFoundFailure` → `empty`; conexão → `error` com a falha; `load` de novo recupera; `dispose` durante a carga não lança
- [X] T015 [US1] Criar `tact/presentation/pages/lesson_page_test.dart` com helper que registra `GetModuleDetailUseCase` sobre o fake, o `LessonController` (factory), um `ReadAloudController` sobre `FakeTextToSpeechService` e o `AccessibilityPreferencesNotifier`, e um `GoRouter` com `/activities/:moduleId` (página real) e `/activities` identificado:
  - "Golpes Digitais" na barra, "Pergunta 1 de 3", enunciado da `l1` e as alternativas numeradas "1."…"4." na ordem do JSON;
  - com `l1` respondida, abre em "Pergunta 2 de 3";
  - `imageUrl` que falha (rede de teste) → sem exceção e sem espaço reservado; sem `imageUrl` → nada;
  - a `explanation` do JSON não aparece em lugar nenhum (FR-016);
  - celular 1080×2340, dpr 3, letra 2× → sem estouro, rolando até a última alternativa;
  - em inglês: "Question 1 of 3"

### Implementação

- [X] T016 [US1] Criar `act/presentation/controller/lesson_status.dart` (`enum LessonStatus { loading, loaded, empty, error }`) e `lesson_controller.dart` (`load(String moduleId)`, `module`, `failure`, `currentIndex`, `current`, regras do [data-model §3](data-model.md#lessoncontroller-changenotifier-factory), `_disposed`); registrar `registerFactory` em `act/activities_module.dart`. Faz a T014 passar
- [X] T017 [P] [US1] Criar `act/presentation/widgets/lesson_option_card.dart` (`LessonOptionCard({required int number, required String text})`: número em círculo + texto, cartão, `MergeSemantics`, altura mínima 48)
- [X] T018 [US1] Criar `act/presentation/pages/lesson_page.dart` (`LessonPage({required String moduleId})`, `ChangeNotifierProvider` do `LessonController` com `load`; `Scaffold` com `AppBar` (título do módulo quando carregado; antes, `activitiesModuleTitle`); "Pergunta X de Y" (`activitiesLessonPosition`); conteúdo rolável com imagem (`Image.network`, `ConstrainedBox(maxHeight: 220)`, `errorBuilder` → `SizedBox.shrink()`, `ExcludeSemantics`), enunciado e `LessonOptionCard`s; por enquanto `loading` → `SafeLoadingState` e `error`/`empty` → `SizedBox.shrink()` (US4)). Em `act/presentation/routes/activities_routes.dart` e `act/activities.dart`, trocar a `ActivityModulePage` pela `LessonPage` e apagar `act/presentation/pages/activity_module_page.dart`; em `app/test/core/routing/app_router_test.dart`, `'/activities/m1': LessonPage` e registrar o necessário (ampliar `registerActivitiesDependencies` em `app/test/helpers/activities_dependencies.dart`). Faz a T015 passar

**Checkpoint**: `flutter test` verde. Commit da Base + US1.

---

## Phase 4: User Story 2 - Avançar, voltar e saber o que já fez (Priority: P1)

**Goal**: anterior livre, próxima só com a atual respondida, marcas de progresso (FR-005, FR-006).

**Independent Test**: passos 2–4 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T019 [P] [US2] Em `tact/presentation/controller/lesson_controller_test.dart`, grupo "navegação": com as três respondidas, `goNext` até 2 e `goPrevious` até 0; `canGoPrevious` falso em 0; `canGoNext` falso na última; com só `l1` respondida, em 0 `canGoNext` verdadeiro e em 1 falso (`goNext` não muda o índice); `goPrevious` em 0 não muda; três `goNext` seguidos com as três respondidas → índice 2 (não passa do fim)
- [ ] T020 [US2] Em `tact/presentation/pages/lesson_page_test.dart`, grupo "navegação": "Próxima"/"Anterior" mudam a posição; "Próxima" desativado (sem `onPressed` e semântica `isEnabled` falso) numa pergunta não respondida; "Anterior" desativado na primeira; marcas: respondidas com `LucideIcons.check`, atual destacada; semântica do indicador "Pergunta 2 de 3, 1 concluídas"; sessão expira com a página aberta (`session.expire()`) → a mesma pergunta continua na tela, sem erro

### Implementação

- [ ] T021 [US2] Em `lesson_controller.dart`: `canGoPrevious`, `canGoNext`, `goPrevious()`, `goNext()` (ignoram quando não podem). Criar `act/presentation/widgets/lesson_progress_indicator.dart` (`Wrap` de marcas 28×28: concluída com check em `colors.success`, atual com borda `colors.primary`, demais vazias; `Semantics(label: activitiesLessonProgressSemantics)` com `ExcludeSemantics` nas marcas) e, na página, o rodapé fixo com dois `SafeButton` (`activitiesLessonPrevious`, `activitiesLessonNext`, `onPressed` nulo quando não pode). Faz a T019 e a T020 passar

**Checkpoint**: arquivos de teste da lição verdes. Commit da US2.

---

## Phase 5: User Story 3 - Ouvir a pergunta e as alternativas (Priority: P2)

**Goal**: "Ouvir"/"Parar", leitura automática uma vez por pergunta, parar ao trocar e ao sair
(FR-008 a FR-011).

**Independent Test**: passos 5–7 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T022 [US3] Em `tact/presentation/pages/lesson_page_test.dart`, grupo "ouvir": "Ouvir" lê "<enunciado>. Alternativa 1: <texto>. Alternativa 2: …" (`FakeTextToSpeechService.spoken.last.text`) com a velocidade das preferências; vira "Parar"; "Parar" chama `stop`; sem voz no idioma (`availableLanguages: {}`) → sem "Ouvir" e nada lido; leitura automática ligada → lê a primeira pergunta sozinha uma vez (recompor a página não lê de novo); "Anterior"/"Próxima" param a leitura e a automática lê a nova uma vez; voltar para uma pergunta já lida sozinha não lê de novo; sair da tela chama `stop` se estava lendo

### Implementação

- [ ] T023 [US3] Na `LessonPage` (estado): `ReadAloudController` do `GetIt` (`prepare(context.locale)` no `didChangeDependencies`, `dispose` ao sair), texto lido montado num getter da lição na camada de apresentação (`act/presentation/extensions/lesson_presentation.dart`: `spokenText` com `activitiesLessonOptionSpoken`), `ListenButton` abaixo das alternativas (só com `isAvailable`), `_maybeAutoRead` como na notícia com `Set<int>` dos índices já lidos sozinhos, e `stop()` antes de trocar de pergunta. Faz a T022 passar

**Checkpoint**: arquivos de teste da lição verdes. Commit da US3.

---

## Phase 6: User Story 4 - Carregando, erro e lições sem alternativas (Priority: P2)

**Goal**: estados claros e lições inválidas fora (FR-007, FR-012).

**Independent Test**: passo 8 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T024 [US4] Em `tact/presentation/pages/lesson_page_test.dart`, grupo "estados": carregando com `SafeLoadingState` e, depois de `SlowRequestNotice.delay`, "O serviço está acordando"; falha → "Não foi possível carregar as atividades" e "Tentar novamente", que recarrega; `ModuleNotFoundFailure` ou módulo sem lições válidas → "Este módulo ainda não tem atividades" (`SafeEmptyState`); módulo com uma lição de 1 alternativa e duas válidas → "Pergunta 1 de 2"

### Implementação

- [ ] T025 [US4] Na `LessonPage`: `loading` → `SlowRequestNotice(active: true, message: activitiesSlow)` + `SafeLoadingState`; `error` → `SafeErrorState(message: activitiesErrorTitle, onRetry: load)`; `empty` → `SafeEmptyState(icon: graduationCap, message: activitiesModuleUnavailable)`. Faz a T024 passar

**Checkpoint**: `flutter test` verde. Commit da US4.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T026 Rodar `/revisar-pr` sobre a branch (antes de abrir o PR: revisar o diff `develop...017-perguntas-atividades` com o mesmo roteiro da skill) e corrigir os achados Alta/Média, anotando aqui o que ficou aceito
- [ ] T027 `flutter analyze` sem novos avisos em relação à linha de base da T001 e `flutter test` inteiro verde; anotar os números aqui
- [ ] T028 Validação no aparelho: os 12 passos do [quickstart](quickstart.md) (a usuária valida); anotar o que falhar como tarefa nova
- [ ] T029 Fechar a feature: marcar a B2 em `.specify/memory/tasks.md` (anotando que `explanation` e `progress` ficaram para a B3/B4, e que a B3 libera o "Próxima" ao responder); marcar as tarefas deste arquivo; commit de docs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depende da T001; bloqueia todas as histórias.
- **US1 (Phase 3)**: depende da Phase 2. É o MVP.
- **US2, US3 e US4**: dependem da US1 (página e controller); mexem na mesma página, então seguem
  em sequência (US2 → US3 → US4), mas os testes de controller da US2 (T019) podem ser escritos em
  paralelo com a US1.
- **Polish (Phase 7)**: depois de todas as histórias.

### Within Each User Story

- Teste escrito e visto falhar antes da implementação.
- Domínio e dados antes do controller; controller antes da página.
- Um commit ao fim de cada história.

### Parallel Opportunities

- Phase 2: T002–T006 juntos; T009 e T010 juntos; T011 → T012 → T013 em sequência.
- US1: T014 e T017 juntos.

## Parallel Example: Foundational

```bash
Task: "T002 ListenButton em app/test/core/widgets/listen_button_test.dart"
Task: "T003 module_detail_model_test.dart"
Task: "T004 getModuleDetail no teste do datasource"
Task: "T005 isAnswered no teste do registro"
Task: "T006 grupo detalhe do módulo no teste do repositório"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 e Phase 2.
2. Phase 3 (US1): a pergunta na tela, começando na primeira não respondida.
3. **Parar e validar**: passos 1, 9 e 10 do quickstart. Commit da Base + US1.

### Incremental Delivery

1. Base + US1 → ver as perguntas (MVP).
2. US2 → navegar com a regra guiada.
3. US3 → ouvir e leitura automática.
4. US4 → estados.
5. Polish → `/revisar-pr` na branch, suíte, aparelho, B2 marcada.

Cada história é um commit; o PR para a `develop` sai depois da validação no aparelho (T028).
