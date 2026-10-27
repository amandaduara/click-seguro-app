---

description: "Task list for feature 020: conclusão do módulo e aviso de login"
---

# Tasks: Conclusão do módulo e aviso de login

**Input**: Design documents from `/specs/020-conclusao-modulo-atividades/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/completion-flow.md](contracts/completion-flow.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeShareService` (`app/test/fakes/`, com
`shared` e `outcome`), `FakeTextToSpeechService`, fakes do `activities`
(`tact/fakes/`), `UserSessionService(FakeSecureStorageService())` real; widget tests com
`pumpLocalized` e `GetIt.instance.reset()` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `act/` =
  `click_seguro_app/lib/modules/activities/`; `tact/` = `click_seguro_app/test/modules/activities/`;
  `auth/` = `click_seguro_app/lib/modules/authentication/`; `tauth/` =
  `click_seguro_app/test/modules/authentication/`.
- Tipos, faixas e chaves no [data-model](data-model.md); telas e rotas no
  [contrato](contracts/completion-flow.md); decisões no [research](research.md).
- Módulo de teste: `m1` "Golpes Digitais" com `l1`–`l3` (fixtures da B2/B3); a correta da `l1` é
  `l1-o1`.
- Visual: design system do app, cores por `context.colors`. Troféu `LucideIcons.trophy` 64 em
  `colors.success`; título 20/700 `colors.secondary`; pontuação 18/700; mensagem 16
  `colors.textForeground`.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, `git fetch` e conferir se a `develop` tem algo novo (se tiver, parar e avisar: o outro desenvolvedor pode mexer em `authentication`, `activities` ou nas traduções); rodar `flutter analyze` e `flutter test` e anotar a linha de base no fim desta tarefa. **Linha de base (2026-10-27):** `develop` sem novidades; aberto o PR #26 do Arthur (identidade Click Seguro: `AppIdentity.name` vira "Click Seguro" e mexe nas traduções), então os testes da B4 comparam com `AppIdentity.name`, não com "SafeNews"; `flutter test` 1642 verdes; `flutter analyze` 27 issues, todos `info`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, regra de "módulo concluído", faixas e textos da conclusão, e o botão "Ver resultado".

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Em `tact/presentation/controller/lesson_controller_test.dart`, grupo "módulo concluído": `isModuleCompleted` falso antes da carga; falso com `l3` não respondida; verdadeiro com as três `isCompleted` (serviço); falso → verdadeiro depois de responder a última (`confirm` com sucesso); módulo sem lições → falso
- [X] T003 [P] Criar `tact/presentation/extensions/completion_presentation_test.dart` (com `pumpLocalized` para as traduções): faixa "`score == total` → `perfect`; `score * 2 >= total` → `good`; senão `retry`; sem pontuação → `good`" (3/3, 2/3, 1/3, 2/4, `null`); `spokenText` = título + "Você acertou X de Y." + mensagem (sem pontuação: sem a linha); `shareText` com pontuação ("Concluí o módulo Golpes Digitais no SafeNews e acertei 3 de 3 perguntas! …") e sem pontuação; em inglês
- [X] T004 [P] Em `tact/presentation/widgets/feedback_sheet_test.dart`: com `isLast: true` e `completed: true` → botão "Ver resultado" que devolve `FeedbackAction.result`; com `isLast: true` e `completed: false` → "Voltar às atividades" (`finish`, como na B3)

### Implementação

- [X] T005 Chaves de i18n em `app/lib/core/i18n/app_strings.dart` (bloco das atividades) e em `app/assets/translations/pt-BR.json` e `en-US.json`, conforme o [data-model §3](data-model.md#3-i18n-pt-br--en-us). en-US: "See result", "Module completed!", "You got {} of {} right", "Congratulations! You got them all and are ready to spot these scams.", "Well done! You already know how to protect yourself from these scams.", "Good start! Redo the module to practice what you learned.", "Share", "Redo the module", "I completed the {} module on {} and got {} of {} questions right! Learn to protect yourself from scams too.", "I completed the {} module on {}! Learn to protect yourself from scams too.", "Keep your progress", "Without an account, your progress lasts only until you close the app. Create an account now to keep it.", "Create account", "Continue without an account"
- [X] T006 [P] Em `act/presentation/controller/lesson_controller.dart`: `bool get isModuleCompleted` ("módulo carregado, com lições, e todas `isCompleted`"). Faz a T002 passar
- [X] T007 [P] Criar `act/presentation/pages/completion_page.dart` só com os tipos por enquanto: `class ModuleCompletion {title, ModuleScoreEntity? score}` e `enum CompletionAction { finish, redo }`; criar `act/presentation/extensions/completion_presentation.dart` com `enum ModuleCompletionTier { perfect, good, retry }` e a extensão `ModuleCompletionPresentation` (`tier`, `messageKey`, `spokenText`, `shareText`, usando `AppIdentity.name` de `app/lib/core/constants/app_identity.dart`). Faz a T003 passar
- [X] T008 [P] Em `act/presentation/widgets/feedback_sheet.dart`: `FeedbackAction.result` e parâmetro `completed` em `showFeedbackSheet`/`FeedbackSheet` (padrão `false`): na última pergunta, `completed` → "Ver resultado" (`activitiesFeedbackResult`) devolvendo `result`; mantém o bloqueio de toque duplo da B3. Faz a T004 passar

**Checkpoint**: `flutter analyze` limpo; testes do controller, da extensão e do painel verdes.

---

## Phase 3: User Story 1 - Ver a conclusão ao terminar o módulo (Priority: P1) 🎯 MVP

**Goal**: quem tem conta termina o módulo e vê a conclusão com a pontuação, a mensagem e a voz;
voltar leva ao painel (FR-001 a FR-005, FR-011 a FR-013).

**Independent Test**: passos 9, 10 e 6 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T009 [P] [US1] Criar `tact/presentation/pages/completion_page_test.dart` com um `GoRouter` de teste que abre `/done` por `push` a partir de uma página que guarda o `CompletionAction?` devolvido, e com `ReadAloudController` sobre `FakeTextToSpeechService` e `AccessibilityPreferencesNotifier` no `GetIt`: título do módulo na barra, troféu, "Módulo concluído!" (`liveRegion`), "Você acertou 2 de 3" e a mensagem `good`; sem pontuação → sem "acertou" e sem "0 de 0"; "Voltar às atividades" → `finish`; voltar do aparelho → `null`; "Refazer o módulo" → `redo`; sem `extra` → volta (pop) sem erro; leitura automática ligada → lê `spokenText` uma vez; "Ouvir" lê e vira "Parar"; sem voz → sem "Ouvir" e nada lido; sair da tela → `stopCalls` aumenta; letra 2× num celular 1080×2340, dpr 3 → sem estouro e botões alcançáveis rolando; em inglês
- [X] T010 [US1] Em `tact/presentation/pages/lesson_page_test.dart`, grupo "conclusão (specs/020 US1)" (o `GoRouter` de teste ganha a rota `/activities/:moduleId/done` com a `CompletionPage`): com conta e `l1`, `l2` respondidas → abre na `l3`; responder → "Ver resultado" → conclusão com a pontuação do controller, **sem** aviso; "Voltar às atividades" → `page:/activities`; voltar do aparelho na conclusão → `page:/activities`; com só `l1` respondida no serviço, responder a `l2` → o painel mostra "Próxima pergunta" (não é a última) e, na `l3`, só "Ver resultado" depois de responder

### Implementação

- [X] T011 [US1] Completar `act/presentation/pages/completion_page.dart`: `CompletionPage({ModuleCompletion? completion})` conforme o [contrato §4](contracts/completion-flow.md#4-conclusão-completionpage) e o layout do [R8](research.md#r8-layout); `PopScope` não é necessário (o `null` do voltar = `finish`); sem `completion` → `context.pop()` no primeiro quadro; voz como no [R7](research.md#r7-voz-na-conclusão) (um `ReadAloudController` do `GetIt`, `prepare(locale)` em `didChangeDependencies`, leitura automática uma vez, `ListenButton` em `ListenableBuilder`, `dispose`). O botão "Compartilhar" só entra na US3. Faz a T009 passar
- [X] T012 [US1] Em `act/presentation/routes/activities_routes.dart`: rota filha `done` de `:moduleId` (`parentNavigatorKey: rootNavigatorKey`, `CompletionPage(completion: state.extra as ModuleCompletion?)`); em `app/test/core/routing/app_router_test.dart`, `'/activities/m1/done': CompletionPage`. Em `act/presentation/pages/lesson_page.dart`: `showFeedbackSheet(…, completed: _controller.isModuleCompleted)`; `FeedbackAction.result` → `_finishModule()`: com conta, `push<CompletionAction>('/activities/$moduleId/done', extra: ModuleCompletion(title, score))`; `redo` → `_controller.load(moduleId)` (US4); `finish`/`null` → `context.pop()`. Faz a T010 passar

**Checkpoint**: testes da conclusão e das perguntas verdes. Commit da Base + US1. **Nota (2026-10-27):** o teste da B3 "na última, 'Voltar às atividades' volta ao painel" saiu: com a última respondida o módulo fica concluído e o botão passa a ser "Ver resultado" (FR-001), coberto pelos testes novos; `/activities/m1/done` sem dados tem teste próprio no roteador (volta, sem erro).

---

## Phase 4: User Story 2 - Aviso para o visitante antes da conclusão (Priority: P1)

**Goal**: o visitante vê o aviso antes da conclusão; "Criar conta" abre o login em modo cadastro e
leva a Atividades ao entrar; continuar ou voltar segue para a conclusão (FR-007 a FR-009).

**Independent Test**: passos 1–3, 7 e 8 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T013 [P] [US2] Criar `tact/presentation/widgets/guest_progress_alert_test.dart` (abrindo `showGuestProgressAlert` num botão de teste): título "Guarde seu progresso" anunciado (`header`), texto, "Criar conta" → `GuestAlertAction.createAccount`, "Continuar sem conta" → `continueWithoutAccount`, voltar do aparelho → `null`; botões ≥ 48; letra 2× rola sem estouro; em inglês
- [X] T014 [P] [US2] Em `tauth/presentation/pages/login_page_test.dart`: `LoginPage(initialMode: AuthMode.register)` abre com o campo de nome e "Criar conta"; cadastro com `next: '/activities'` → vai para `/activities` (rota de teste `page:/activities`); login com `next` → também `/activities`; sem `next` → `/home` (como antes). Criar `tauth/presentation/routes/authentication_routes_test.dart`: `loginPageFor(Uri.parse('/login?mode=register&next=/activities'))` → `initialMode` cadastro e `next` `/activities`; `next=https://x.com`, `next=//x.com` ou ausente → `null`; `mode` ausente ou outro valor → login
- [X] T015 [US2] Em `tact/presentation/pages/lesson_page_test.dart`, grupo "visitante (specs/020 US2)" (sessão de visitante; o `GoRouter` de teste ganha `/login` como `page:/login?<query>` mostrando `state.uri.toString()`): terminar o módulo → "Ver resultado" → aviso; "Continuar sem conta" → conclusão com a pontuação do controller; voltar no aviso → conclusão; "Criar conta" → abre `/login` com `queryParameters` `mode == 'register'` e `next == '/activities'` (conferir pelos parâmetros, não pelo texto da URL; achado A1 da análise); voltar do login sem entrar → conclusão; conta (US1) → nunca o aviso; sessão que expira antes de "Ver resultado" (`session.expire()` com a última pergunta respondida) → aviso de visitante (achado C1 da análise)

### Implementação

- [X] T016 [P] [US2] Criar `act/presentation/widgets/guest_progress_alert.dart`: `enum GuestAlertAction { createAccount, continueWithoutAccount }` e `Future<GuestAlertAction?> showGuestProgressAlert(BuildContext)` (`showModalBottomSheet`, `isScrollControlled`, `useSafeArea`, fundo `colors.card`), conforme o [contrato §3](contracts/completion-flow.md#3-aviso-do-visitante-showguestprogressalert) e o [R8](research.md#r8-layout). Faz a T013 passar
- [X] T017 [P] [US2] Em `auth/presentation/routes/authentication_routes.dart`: `LoginPage loginPageFor(Uri uri)` (top-level, testável) lendo `mode` e `next` ("`next` só se começar com `/` e não com `//`") e a rota `/login` usando-a. Em `auth/presentation/pages/login_page.dart`: `LoginPage({super.key, this.initialMode = AuthMode.login, this.next})`; no primeiro quadro, depois do `reset()`, `setMode(initialMode)` se for cadastro; em `_onControllerChanged`, `context.go(widget.next ?? '/home')`. Faz a T014 passar sem mudar os outros testes do login
- [X] T018 [US2] Em `act/presentation/pages/lesson_page.dart`, `_finishModule()`: sem conta (`!GetIt.instance<UserSessionService>().isAuthenticated`, como o resto das atividades) → `showGuestProgressAlert`; `createAccount` → `await context.push('/login?mode=register&next=/activities')` e, se a página ainda existir (voltou sem entrar), segue para a conclusão; `continueWithoutAccount`/`null` → conclusão. Faz a T015 passar

**Checkpoint**: testes do aviso, do login e das perguntas verdes. Commit da US2.

---

## Phase 5: User Story 3 - Compartilhar a conquista (Priority: P2)

**Goal**: "Compartilhar" abre o menu do aparelho com o texto pronto (FR-006).

**Independent Test**: passo 4 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T019 [US3] Em `tact/presentation/pages/completion_page_test.dart`, grupo "compartilhar" (`FakeShareService` no `GetIt` como `ShareService`): toque → `shared.single.text` igual ao `shareText` e `subject` = título; sem pontuação → texto sem números; `outcome = failed` ou `dismissed` → nenhuma mensagem na tela; dois toques rápidos → um `shareText`

### Implementação

- [X] T020 [US3] Em `act/presentation/pages/completion_page.dart`: botão "Compartilhar" (`SafeButtonTone.secondary`, ícone `LucideIcons.share2`) chamando `GetIt.instance<ShareService>().shareText(shareText, subject: title)` com a trava `_sharing` (padrão do detalhe da notícia, [R6](research.md#r6-compartilhar)). Faz a T019 passar

**Checkpoint**: testes verdes. Commit da US3. **Nota:** o `FakeShareService` (`app/test/fakes/`) ganhou um `gate` opcional para provar o toque duplo; a subclasse `_GatedShareService` do teste do detalhe da notícia, que fazia o mesmo, saiu (o teste usa o fake direto).

---

## Phase 6: User Story 4 - Refazer o módulo (Priority: P3)

**Goal**: "Refazer o módulo" volta à primeira pergunta (FR-010).

**Independent Test**: passo 5 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T021 [US4] Em `tact/presentation/pages/lesson_page_test.dart`, grupo "refazer (specs/020 US4)": da conclusão, "Refazer o módulo" → "Pergunta 1 de 3", sem alternativa marcada, `moduleDetailCalls` aumentou; responder as três de novo → "Ver resultado" → conclusão com a pontuação nova

### Implementação

- [X] T022 [US4] Em `act/presentation/pages/lesson_page.dart`: `CompletionAction.redo` → `_controller.load(moduleId)` (a B2 abre na primeira pergunta quando todas estão respondidas). Faz a T021 passar

**Checkpoint**: testes verdes. Commit da US4. **Nota:** o `redo` → `load` já tinha entrado na T012 (o `switch` da conclusão precisava cobrir as duas ações), então a T021 passou sem ter falhado antes; ela fica como teste do comportamento.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T023 Em `tact/presentation/pages/lesson_page_test.dart`, conferir o fluxo do visitante inteiro (aviso → conclusão) com letra 2× e alto contraste (`AppTheme.highContrastTheme`) num celular 1080×2340, dpr 3, e em inglês ("See result", "Keep your progress", "Module completed!")
- [ ] T024 Rodar `/revisar-pr` sobre a branch (antes de abrir o PR: revisar o diff `develop...020-conclusao-modulo-atividades` com o mesmo roteiro da skill) e corrigir os achados Alta/Média, anotando aqui o que ficou aceito
- [ ] T025 `flutter analyze` sem novos avisos em relação à linha de base da T001 e `flutter test` inteiro verde; anotar os números aqui
- [ ] T026 Validação no aparelho: os 12 passos do [quickstart](quickstart.md) (a usuária valida; o passo 8 cria uma conta, só com a permissão dela); anotar o que falhar como tarefa nova
- [ ] T027 Fechar a feature: marcar a B4 em `.specify/memory/tasks.md` (anotando: `/login?mode=register&next=…` opcionais no `authentication`; a conclusão usa a pontuação da B3, sem pedido novo; o aviso aparece a cada módulo concluído pelo visitante) e as tarefas deste arquivo; commit de docs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depende da T001; bloqueia todas as histórias.
- **US1 (Phase 3)**: depende da Phase 2. É o MVP.
- **US2**: depende da US1 (a conclusão é o destino do aviso); a T013, a T014, a T016 e a T017
  (aviso e login) não dependem da US1 e podem ser feitas em paralelo com ela.
- **US3 e US4**: dependem da US1 (tela de conclusão); mexem em arquivos diferentes (US3 na
  conclusão, US4 nas perguntas) e podem andar em paralelo.
- **Polish (Phase 7)**: depois de todas as histórias.

### Within Each User Story

- Teste escrito e visto falhar antes da implementação.
- Tipos e regras antes das telas; telas antes do fluxo da `LessonPage`.
- Um commit ao fim de cada história.

### Parallel Opportunities

- Phase 2: T002, T003 e T004 juntos; T006, T007 e T008 juntos (arquivos diferentes).
- US1: T009 em paralelo com a T013/T014 da US2.
- US2: T013 e T014 juntos; T016 e T017 juntos.

## Parallel Example: Foundational

```bash
Task: "T002 isModuleCompleted em lesson_controller_test.dart"
Task: "T003 completion_presentation_test.dart"
Task: "T004 'Ver resultado' em feedback_sheet_test.dart"
```

## Parallel Example: User Story 2

```bash
Task: "T013 guest_progress_alert_test.dart"
Task: "T014 login com mode e next"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 e Phase 2.
2. Phase 3 (US1): conclusão para quem tem conta.
3. **Parar e validar**: passos 6, 9 e 10 do quickstart. Commit da Base + US1.

### Incremental Delivery

1. Base + US1 → conclusão (MVP).
2. US2 → aviso do visitante e login para Atividades.
3. US3 → compartilhar.
4. US4 → refazer.
5. Polish → `/revisar-pr` na branch, suíte, aparelho, B4 marcada.

Cada história é um commit; o PR para a `develop` sai depois da validação no aparelho (T026).
