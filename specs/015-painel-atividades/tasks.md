---

description: "Task list for feature 015: painel de atividades"
---

# Tasks: Painel de atividades

**Input**: Design documents from `/specs/015-painel-atividades/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/activities-dashboard.md](contracts/activities-dashboard.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeHttpClientAdapter`
(`app/test/modules/common/api_client/fake_http_client_adapter.dart`) no datasource;
`UserSessionService(FakeSecureStorageService())` de verdade no registro do visitante e no
repositório; fakes de datasource e repositório em `tact/fakes/`; widget tests com `pumpLocalized`
(`app/test/helpers/localized_app.dart`) e `GetIt.instance.reset()` no `tearDown`. JSON de teste no
formato real do [R0](research.md#r0-conferência-no-servidor-real-portão-de-api).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `act/` =
  `click_seguro_app/lib/modules/activities/`; `tact/` = `click_seguro_app/test/modules/activities/`.
- Campos, regras e chaves exatas no [data-model](data-model.md); endpoints, rotas e tela no
  [contrato](contracts/activities-dashboard.md); o porquê de cada decisão no [research](research.md).
- Visual: design system do app. Cartões com `SafeCard` (ou o mesmo visual: `colors.card`, borda
  `colors.border`, raio `AppSpacing.radius2xl`), título 18/700 `colors.secondary`, descrição 16
  `colors.textForeground`, "X de Y lições" 14 `colors.textMutedForeground`, selo `SafeBadge` com o
  tom do status, barra `LinearProgressIndicator` (`colors.primary` sobre `colors.input`, altura 8,
  raio cheio). Cores sempre por `context.colors`.
- Valores fictícios nos testes: módulos `m1` "Golpes Digitais" (ordem 1), `m2` "Golpes no WhatsApp"
  (ordem 2), `m3` "Fake News" (ordem 3), 3 lições cada; lições `l1`…; opções `o1`….

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, `git fetch` e conferir se a `develop` tem algo novo (se tiver, parar e avisar: o outro desenvolvedor pode mexer em `common`, `authentication` ou `profile`); rodar `flutter analyze` e `flutter test` e anotar a linha de base (testes, erros, warnings, infos) no fim desta tarefa. **Linha de base (2026-10-19):** `develop` sem novidades e nenhum PR aberto; `flutter test` 1344 verdes; `flutter analyze` 28 issues, todos `info`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, domínio, dados (leitura), registro do visitante sem a transferência, o módulo
registrado e o mixin de recarregar ao voltar.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Criar `tact/fakes/activities_fixtures.dart` (`moduleJson({id, title, order, lessonsCount = 3, completedCount = 0, iconUrl})` e `dashboardJson({modules, totalLessonsCompleted, totalLessonsAvailable})` no formato do R0, com `description` e `progressPercent`) e `tact/domain/module_summary_entity_test.dart`: status `unavailable` com `lessonsCount == 0`, `notStarted` com 0 concluídas, `inProgress` com 1 ou 2 de 3, `completed` com 3 de 3; `completedCount` 5 de 3 → limitado a 3 e `completed`; `completedCount` negativo → 0; `progress` (0 sem lições, 2/3); `withCompletedCount` devolve cópia; `ActivitiesDashboardEntity`: `isEmpty`, `hasOverallProgress` (falso com `totalAvailable 0`), `overallProgress`, `totalCompleted` limitado a `totalAvailable`
- [X] T003 [P] Criar `tact/data/models/activities_dashboard_model_test.dart`: JSON do R0 → entidade com os três módulos na ordem de `order` (mesmo vindo fora de ordem), `iconUrl` vazio ou ausente → `null`, `lessonsCount`/`completedCount` ausentes → 0, módulo sem `id` ou `title` descartado, `progressPercent` ignorado, totais lidos
- [X] T004 [P] Criar `tact/data/datasources/activities_remote_data_source_impl_test.dart` (padrão de `app/test/modules/news/data/datasources/` com `FakeHttpClientAdapter`): `getModules()` → `GET /app/educational/modules`, com `Authorization` quando a sessão tem token e **sem** quando é visitante; `answerLesson(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')` → `POST /app/educational/modules/m1/lessons/l1/answer` com `{'selectedOptionId': 'o1'}`; erros sobem como `ApiException` com o `errorCode`
- [X] T005 [P] Criar `tact/data/datasources/guest_progress_store_test.dart` (sem a transferência; ela entra na US3) com `UserSessionService(FakeSecureStorageService())` em sessão de visitante: `recordAnswer` grava; a mesma lição de novo substitui a opção (continua contando 1); `answeredCount('m1')` conta só as lições de `m1` (sem lista pública das respostas: verificar por `answeredCount`); visitante → `logout()` apaga; visitante → `saveSession` (login) apaga
- [X] T006 [P] Criar `app/test/core/widgets/refresh_on_return_test.dart`: um `StatefulWidget` de teste com o `RefreshOnReturnMixin` numa aba de um `StatefulShellRoute` de teste chama `onReturn` ao trocar de aba e voltar (uma vez), e `pushAndRefresh('/x')` chama `onReturn` uma vez na volta do `pop`; sem chamada na primeira montagem

### Implementação

- [X] T007 Chaves de i18n: em `app/lib/core/i18n/app_strings.dart`, bloco `// --- activities ---`, as constantes da tabela do [data-model §5](data-model.md#5-textos-novos-i18n-prefixo-activities_) (`activitiesOverallTitle`, `activitiesOverallCount`, `activitiesModuleCount`, `activitiesModuleUnavailable`, `activitiesStatusNotStarted`/`InProgress`/`Completed`/`Unavailable`, `activitiesGuestNotice`, `activitiesGuestAction`, `activitiesEmptyTitle`, `activitiesEmptyBody`, `activitiesErrorTitle`, `activitiesSlow`, `activitiesOpenModule`) com os textos pt-BR e en-US em `app/assets/translations/pt-BR.json` e `en-US.json` (`{}` como argumento posicional, como `settings_version`). Conferir que `app/test/modules/shell/i18n_keys_test.dart` cobre o prefixo `activities_` (acrescentar à expressão se não cobrir)
- [X] T008 [P] Criar em `act/domain/`: `entities/module_status.dart` (`enum ModuleStatus { notStarted, inProgress, completed, unavailable }`), `entities/module_summary_entity.dart` (campos e regras do [data-model §1](data-model.md#modulesummaryentity): `completedCount` "limitado a `0…lessonsCount`", `status`, `isAvailable`, `progress`, `withCompletedCount`, `==`/`hashCode`), `entities/activities_dashboard_entity.dart` (`totalCompleted` "limitado a `0…totalAvailable`", `isEmpty`, `hasOverallProgress`, `overallProgress`), `entities/guest_answer.dart` (`moduleId`, `lessonId`, `selectedOptionId`), `repositories/activities_repository.dart` (`Future<Either<Failure, ActivitiesDashboardEntity>> getDashboard()`) e `usecases/get_activities_dashboard_usecase.dart`. Faz a T002 passar
- [X] T009 [P] Criar `act/data/models/module_summary_model.dart` e `activities_dashboard_model.dart` (`fromJson` → `toEntity()`, regras do [data-model §2](data-model.md#json-de-get-appeducationalmodules-r0)). Faz a T003 passar
- [X] T010 Criar `act/data/datasources/activities_remote_data_source.dart` + `_impl.dart` (caminhos em constantes `modulesPath = '/app/educational/modules'` e `static String answerPath(moduleId, lessonId)`; `getModules()` devolve `ActivitiesDashboardModel`; `answerLesson` faz `post` com `{'selectedOptionId': …}` e ignora o corpo; os dois com o `requiresAuth` padrão, que só põe o token se a sessão tiver). Faz a T004 passar
- [X] T011 Criar `act/data/datasources/guest_progress_store.dart`: `GuestProgressStore(UserSessionService session)` que guarda `Map<String, GuestAnswer>` por `lessonId`, com `recordAnswer` e `answeredCount` (sem expor a lista de respostas, data-model §2), e um ouvinte de `session.sessionStatus` que guarda o status anterior e apaga tudo ao sair de `guest` (a exceção do cadastro entra na US3) e ao sair de `authenticated`; `dispose()` remove o ouvinte. Faz a T005 passar
- [X] T012 Criar `act/data/repositories/activities_repository_impl.dart` (`ActivitiesRepositoryImpl(remote)` na Base — registro e sessão entram no construtor na US3, para o commit da Base não ter campos sem uso; por enquanto: conta → `getModules()` e devolve; visitante → igual, ainda sem trocar pelo registro (US3); `ApiException` → `Left(e.toFailure())` pelo `api_failure_mapper`) e o teste `tact/data/repositories/activities_repository_impl_test.dart` com `FakeActivitiesRemoteDataSource` (`tact/fakes/fake_activities_remote_data_source.dart`, com fila de respostas, contador de chamadas e lista de respostas enviadas): sucesso → `Right`; conexão → `Left(ConnectionFailure)`; servidor → `Left(ServerFailure)`
- [X] T013 Registrar em `act/activities_module.dart`: `ActivitiesRemoteDataSource` (lazy singleton com `ApiClient`), `GuestProgressStore` (lazy singleton com `UserSessionService`), `ActivitiesRepository`, `GetActivitiesDashboardUseCase`; criar `tact/activities_module_test.dart` (padrão de `app/test/modules/news/news_module_test.dart`): tudo resolve; o registro é o mesmo objeto em duas leituras
- [X] T014 Criar `app/lib/core/widgets/refresh_on_return.dart` com `mixin RefreshOnReturnMixin<T extends StatefulWidget> on State<T>` (técnica do `_AccountProfileState` da B7: ouvir `GoRouter.of(context).routerDelegate` no `didChangeDependencies`, chamar `onReturn()` quando o caminho volta a ser `tabPath` vindo de outro; `pushAndRefresh(location, {extra})` faz `push` e chama `onReturn()` na volta se o ouvinte ainda não chamou; remove o ouvinte no `dispose`). Faz a T006 passar. Migrar `app/lib/modules/profile/presentation/pages/profile_page.dart` (`_AccountProfileState`) para o mixin, sem mudar comportamento: os testes de `app/test/modules/profile/presentation/pages/profile_page_test.dart` ("voltar de uma lista atualiza os números", "trocar de aba e voltar atualiza sem mostrar carregando") continuam verdes sem mudança

**Checkpoint**: `flutter analyze` limpo; testes de entidades, models, datasource, registro, repositório, módulo e mixin verdes; suíte do Perfil verde.

---

## Phase 3: User Story 1 - Ver os módulos e o próprio progresso (Priority: P1) 🎯 MVP

**Goal**: a aba mostra "Seu progresso" e os cartões dos módulos com status, em uma ou duas colunas
(FR-001 a FR-004, FR-003a, FR-007, FR-012 a FR-014).

**Independent Test**: passos 1–3 e 8–10 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T015 [P] [US1] Criar `tact/presentation/controller/activities_dashboard_controller_test.dart` com `FakeActivitiesRepository` (`tact/fakes/fake_activities_repository.dart`: fila de resultados, `Completer` opcional, contador): começa `loading`; sucesso com módulos → `loaded` com o `dashboard`; sucesso sem módulos → `empty`; falha → `error` com a `failure`; `load()` de novo depois do erro → `loading` → `loaded`; `dispose` durante a carga não lança
- [X] T016 [P] [US1] Criar `tact/presentation/extensions/module_status_presentation_test.dart`: rótulo pt-BR e en-US de cada status ("Não iniciado", "Em andamento", "Concluído", "Indisponível" / "Not started", "In progress", "Completed", "Unavailable"), tom do `SafeBadge` (`neutral`, `primary`, `success`, `neutral`) e ícone de cada um
- [X] T017 [US1] Criar `tact/presentation/pages/activities_dashboard_page_test.dart` com helper `registerActivitiesDependencies(GetIt, {FakeActivitiesRepository?})` (criado aqui em `app/test/helpers/activities_dependencies.dart`: usecase sobre o fake e `registerFactory` do controller) e sessão conectada; `GoRouter` de teste com `/activities` (página real), `/activities/:moduleId` identificado e `/login`:
  - "Seu progresso" e "4 de 9 lições concluídas", barra com valor ≈ 0,44;
  - três cartões na ordem m1, m2, m3, com título, descrição, "0 de 3 lições"/"2 de 3 lições"/"3 de 3 lições" e os selos "Não iniciado", "Em andamento", "Concluído";
  - módulo com `lessonsCount 0` → selo "Indisponível" e "Este módulo ainda não tem atividades"; totais `0/0` → sem "Seu progresso";
  - ícone: `iconUrl` nulo → ícone padrão (`LucideIcons.graduationCap`); URL que falha (`Image.network` com erro no teste) → ícone padrão, sem exceção;
  - **layout**: escala de letra 1,0 (`tester.platformDispatcher.textScaleFactorTestValue = 1`) → m1 e m2 lado a lado (mesmo `dy`, `dx` diferente) e m3 sozinho na linha seguinte com a mesma largura de m1; descrição com `maxLines: 3`; escala 1,15 → os três um embaixo do outro, descrição sem limite; com a página montada em 1,0, mudar a escala para 1,15 (`textScaleFactorTestValue` + `pump`) → reorganiza em uma coluna sem recarregar (contador do fake igual);
  - semântica: cada cartão disponível é lido com título, status, "X de Y lições" e descrição inteira;
  - celular 1080×2340, dpr 3, escala 2,0 → sem estouro, cartões alcançáveis rolando;
  - em inglês: "Your progress", "4 of 9 lessons completed", "In progress"

### Implementação

- [X] T018 [US1] Criar `act/presentation/controller/activities_dashboard_status.dart` (`enum ActivitiesDashboardStatus { loading, loaded, empty, error }`) e `activities_dashboard_controller.dart` (`ChangeNotifier`; `load()`; contador de pedidos para ignorar respostas antigas; `_disposed`, como o `SettingsController`); registrar `registerFactory` em `act/activities_module.dart`. Faz a T015 passar
- [X] T019 [P] [US1] Criar `act/presentation/extensions/module_status_presentation.dart` (`label`, `badgeTone`, `icon` por `switch`, valores do [data-model §4](data-model.md#extensão-modulestatuspresentation)). Faz a T016 passar
- [X] T020 [P] [US1] Criar `act/presentation/widgets/module_icon.dart` (`Image.network` 48×48 com `errorBuilder` e `loadingBuilder` → ícone padrão `LucideIcons.graduationCap` 28 `colors.primary` num quadrado 48 `colors.primary.withValues(alpha: 0.08)`, raio 12; `ExcludeSemantics`) e `overall_progress_card.dart` (título `activitiesOverallTitle` com `Semantics(header)`, texto `activitiesOverallCount.tr(args: [x, y])`, barra)
- [X] T021 [US1] Criar `act/presentation/widgets/module_card.dart` (`ModuleCard(module, {required bool compact, VoidCallback? onTap})`: ícone, título, descrição (`compact` → `maxLines: 3` com `TextOverflow.ellipsis`), "X de Y lições" (ou `activitiesModuleUnavailable` no indisponível), `SafeBadge` com tom e ícone do status; `MergeSemantics` + `Semantics(label: descrição inteira)`; altura mínima 48)
- [X] T022 [US1] Criar `act/presentation/pages/activities_dashboard_page.dart` (`ActivitiesDashboardPage`, `ChangeNotifierProvider` do controller com `load()`; `AppTopBar(title: activitiesTitle)` como hoje; `ListView` com `OverallProgressCard` (se `hasOverallProgress`) e os cartões em uma ou duas colunas pela escala total — `MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.0` → linhas de dois com `IntrinsicHeight` e `Expanded` vazio no ímpar, `compact: true`; senão uma coluna, `compact: false`). Por enquanto `loading` → `SafeLoadingState` e `error`/`empty` → `SizedBox.shrink()` (US4 completa). Apagar `act/presentation/pages/activities_page.dart`; o texto do `SafeBadge` (core) passou a ficar num `Flexible`, porque com letra 2× o selo estourava a largura do cartão; em `act/presentation/routes/activities_routes.dart` e em `act/activities.dart`, trocar pela página nova. Ajustar `app/test/core/routing/app_router_test.dart` (`'/activities': ActivitiesDashboardPage` e `registerActivitiesDependencies` no `setUp`), `app/test/modules/shell/presentation/app_shell_test.dart` (linha 89) e `app/test/widget_test.dart` (linha 114 e registrar um `FakeActivitiesRepository` como os outros repositórios falsos). Faz a T017 passar

**Checkpoint**: `flutter test` verde. Commit da Base + US1.

---

## Phase 4: User Story 2 - Abrir um módulo (Priority: P1)

**Goal**: tocar abre o módulo uma vez, o indisponível não abre, e o painel recarrega ao voltar
(FR-005, FR-006).

**Independent Test**: passos 4 e 5 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T023 [P] [US2] Em `tact/presentation/controller/activities_dashboard_controller_test.dart`: `refresh()` com conteúdo não passa por `loading` e troca o `dashboard`; `refresh()` que falha mantém `loaded` e o `dashboard` anterior; `refresh()` sem conteúdo se comporta como `load()`
- [X] T024 [US2] Em `tact/presentation/pages/activities_dashboard_page_test.dart`, grupo "abrir": tocar em "Golpes Digitais" abre `/activities/m1`; dois toques rápidos abrem uma tela só (contar páginas `/activities/m1` na pilha); cartão indisponível não abre e não tem `button` na semântica; voltar do módulo com o fake devolvendo "1 de 9" → o painel mostra "1 de 9" sem `SafeLoadingState`; trocar de aba e voltar recarrega (contador do fake +1) sem `SafeLoadingState` (coberto pelo teste do mixin, T006, que tem um shell de abas; o roteador deste teste não tem abas)

### Implementação

- [X] T025 [US2] Em `act/presentation/controller/activities_dashboard_controller.dart`, `refresh()` conforme a T023. Na página, o estado da lista usa o `RefreshOnReturnMixin` (`tabPath = '/activities'`, `onReturn` → `controller.refresh()`); o toque no cartão disponível chama `pushAndRefresh('/activities/${module.id}')` com trava de abertura (`_opening`, como o `AppTopBar`); cartão indisponível recebe `onTap: null`. Faz a T023 e a T024 passar

**Checkpoint**: arquivos de teste do painel verdes. Commit da US2.

---

## Phase 5: User Story 3 - Visitante vê o progresso desta sessão (Priority: P2)

**Goal**: o visitante vê o progresso do registro da sessão e o aviso com "Entrar ou criar conta";
ao criar conta, as respostas vão para ela (FR-008, FR-008a, FR-009, FR-010, FR-015).

**Independent Test**: passos 11 e 12 do [quickstart](quickstart.md) e os testes de transferência.

### Testes (escrever primeiro e ver falhar)

- [X] T026 [P] [US3] Em `app/test/modules/common/services/user_session_service_test.dart`: `saveSession(newAccount: true)` → `startedFromSignUp` verdadeiro **já dentro** de um ouvinte de `sessionStatus` (ler no ouvinte); `saveSession` sem o parâmetro → falso; `restoreSession`, `startGuestSession` e `logout` → falso
- [X] T027 [P] [US3] Em `app/test/modules/authentication/data/repositories/auth_repository_impl_test.dart`: `register` com sucesso deixa a sessão com `startedFromSignUp` verdadeiro; `login` deixa falso
- [X] T028 [P] [US3] Em `tact/data/datasources/guest_progress_store_test.dart`, grupo "cadastro": visitante com 2 respostas → `saveSession(newAccount: true)` → `answeredCount` 0, `pendingTransfer` com as 2 e `onSignUp` chamado uma vez; com a conta, `logout()` → pendentes apagadas; `removePending` tira só aquela; login (sem `newAccount`) não gera pendentes
- [X] T029 [P] [US3] Em `tact/data/repositories/activities_repository_impl_test.dart`, grupos:
  - "visitante": serviço com `completedCount` 0 e registro com 2 respostas em m1 e 1 em m2 → m1 "2", m2 "1", `totalCompleted` 3, `totalAvailable` do serviço; registro com 5 respostas em m1 de 3 lições → limitado a 3; nenhum `answerLesson` enviado;
  - "sessão expirada": conta que expira (`session.expire()`, estado `unauthenticated`) → `getDashboard()` segue o caminho sem conta (registro vazio, totais concluídos 0) e devolve `Right`, sem erro;
  - "transferência": conta com 2 pendentes → `getDashboard()` envia as 2 (`moduleId`, `lessonId`, `selectedOptionId` certos) **antes** do `getModules`, tira do registro e devolve o dashboard; uma falha de conexão → fica pendente e é a única enviada na próxima carga; 404 `EDUCATIONAL_LESSON_NOT_FOUND` e 400 → removidas sem repetir; `syncGuestAnswers()` chamado duas vezes ao mesmo tempo envia cada resposta uma vez; falha na transferência não vira `Left`
- [X] T030 [US3] Em `tact/presentation/pages/activities_dashboard_page_test.dart`, grupo "visitante": sessão de visitante → aviso "Sem conta, seu progresso vale até fechar o app." e "Entrar ou criar conta" acima dos cartões; tocar → `/login`; com conta → sem aviso; sessão expira com o painel aberto (`session.expire()`) → próxima recarga mostra os cartões sem erro e **sem** o aviso (só `isGuest` mostra); visitante com respostas no registro (registrar um `GuestProgressStore` real e o repositório real sobre `FakeActivitiesRemoteDataSource`) → "2 de 3 lições" e "Em andamento"

### Implementação

- [X] T031 [US3] Em `app/lib/modules/common/services/user_session_service.dart`: `saveSession(..., bool newAccount = false)` e `bool get startedFromSignUp` (campo privado definido **antes** de `sessionStatus.value`; zerado em `restoreSession`, `startGuestSession` e `_end`); comentário citando specs/015 R4. Em `app/lib/modules/authentication/data/repositories/auth_repository_impl.dart`: `_signIn({..., bool newAccount = false})` repassa ao `saveSession`; `register` passa `newAccount: true`. Faz a T026 e a T027 passar
- [X] T032 [US3] Em `act/data/datasources/guest_progress_store.dart`: na saída de `guest` para `authenticated` com `startedFromSignUp`, mover as respostas para `pendingTransfer` e chamar `onSignUp`; `removePending`; apagar pendentes ao sair de `authenticated`. Faz a T028 passar
- [X] T033 [US3] Em `act/data/repositories/activities_repository_impl.dart`: sem conta (`!session.isAuthenticated`: visitante ou sessão expirada) → troca `completedCount` de cada módulo por `store.answeredCount(id)` (`withCompletedCount`) e `totalCompleted` = soma; `syncGuestAnswers()` com um `Future` único em andamento, envio em sequência, 2xx/404/400 → `removePending`, outras falhas → ficam (códigos `EDUCATIONAL_MODULE_NOT_FOUND`/`EDUCATIONAL_LESSON_NOT_FOUND` em constantes); conta com pendentes → `await syncGuestAnswers()` antes do `getModules()`. `syncGuestAnswers()` entrou na interface `ActivitiesRepository`, e o `ActivitiesModule` liga `onSignUp` na criação do registro buscando o repositório no `GetIt`, para a transferência começar logo depois do cadastro mesmo que o painel nunca tenha sido aberto. Faz a T029 passar
- [X] T034 [US3] Criar `act/presentation/widgets/guest_progress_notice.dart` (cartão com ícone `LucideIcons.info`, `activitiesGuestNotice` e `SafeButton` `activitiesGuestAction` → `context.go('/login')`) e mostrá-lo na página, fixo entre a barra do topo e o conteúdo (fora da rolagem, em qualquer estado), quando a sessão é de visitante (ouvindo `sessionStatus`). Faz a T030 passar

**Checkpoint**: `flutter test` verde (inclusive `authentication` e `common`). Commit da US3.

---

## Phase 6: User Story 4 - Carregando, erro e lista vazia (Priority: P2)

**Goal**: estados claros com "Tentar novamente" e aviso de servidor acordando (FR-011, SC-005).

**Independent Test**: passos 6 e 7 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T035 [US4] Em `tact/presentation/pages/activities_dashboard_page_test.dart`, grupo "estados": com o fake preso num `Completer` → `SafeLoadingState`; depois de `SlowRequestNotice.delay` (5 s) → "O serviço está acordando…"; falha → "Não foi possível carregar as atividades" e "Tentar novamente", que recarrega e mostra os cartões; zero módulos → "Ainda não há atividades" e o texto, sem "Seu progresso"; recarga ao voltar que falha → cartões continuam e nenhum erro aparece

### Implementação

- [X] T036 [US4] Na página: `loading` → `SafeLoadingState` + `SlowRequestNotice(active: true, message: activitiesSlow)`; `error` → `SafeErrorState` (título `activitiesErrorTitle`, ação `commonTryAgain` → `controller.load()`); `empty` → `SafeEmptyState` (título e frase numa mensagem só, em duas linhas, porque o widget tem um texto só; ícone `graduationCap`); o aviso do visitante continua acima nos três estados. Faz a T035 passar

**Checkpoint**: `flutter test` verde. Commit da US4.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T037 Contrato da API → **1.0.10** em `.specify/memory/api-contract.md`: endpoints de atividades de 🧪 para ✅ (conferidos em 2026-10-19, specs/015 R0); notas: resposta errada conta como concluída; `progress.totalScore` 0 até a 1ª resposta; `selectedOptionId` que não é CUID → 400 `VALIDATION_ERROR`; entrada no changelog
- [ ] T038 Revisão de código sem uso e de código só para teste (prática do projeto): procurar em `act/`, `app/lib/core/widgets/refresh_on_return.dart`, `user_session_service.dart` e `auth_repository_impl.dart` membros, parâmetros, chaves de i18n ou imports sem uso (ex.: `GuestProgressStore.recordAnswer` só é chamado pelos testes até a B3: manter e citar a B3 no comentário); remover o que sobrar e ajustar testes
- [ ] T039 `flutter analyze` sem novos avisos em relação à linha de base da T001 e `flutter test` inteiro verde; anotar os números aqui
- [ ] T040 Validação no aparelho: rodar os 12 passos do [quickstart](quickstart.md) (a usuária valida); anotar o que falhar como tarefa nova
- [ ] T041 Fechar a feature: marcar a B1 em `.specify/memory/tasks.md`, anotando a transferência ao criar conta (RN-006 estendida) e que a B3 grava no `GuestProgressStore` (`recordAnswer`); marcar as tarefas deste arquivo; commit de docs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depende da T001; bloqueia todas as histórias.
- **US1 (Phase 3)**: depende da Phase 2. É o MVP.
- **US2 (Phase 4)**: depende da US1 (cartões e página).
- **US3 (Phase 5)**: depende da Phase 2 (registro e repositório) e da US1 (página, para o aviso);
  as partes de `common`, `authentication`, registro e repositório (T026–T029, T031–T033) podem
  andar em paralelo com US1/US2, porque não tocam na página.
- **US4 (Phase 6)**: depende da US1 (página).
- **Polish (Phase 7)**: depois de todas as histórias.

### Within Each User Story

- Teste escrito e visto falhar antes da implementação.
- Domínio e dados antes do controller; controller antes da página.
- Um commit ao fim de cada história.

### Parallel Opportunities

- Phase 2: T002–T006 juntos (arquivos diferentes); depois T008 e T009 juntos; T010 → T011 → T012
  → T013 em sequência (dependências de construtor); T014 independente.
- US1: T015 e T016 juntos; T019 e T020 juntos.
- US3: T026, T027, T028 e T029 juntos (quatro arquivos de teste); T031 e T032 em arquivos
  diferentes, mas a T032 usa o `startedFromSignUp` da T031.

## Parallel Example: User Story 3

```bash
# Testes, em arquivos diferentes:
Task: "T026 startedFromSignUp em user_session_service_test.dart"
Task: "T027 cadastro passa newAccount em auth_repository_impl_test.dart"
Task: "T028 grupo cadastro em guest_progress_store_test.dart"
Task: "T029 visitante e transferência em activities_repository_impl_test.dart"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 e Phase 2.
2. Phase 3 (US1): painel com progresso e cartões nos dois layouts.
3. **Parar e validar**: passos 1–3 e 8–10 do quickstart. Commit da Base + US1.

### Incremental Delivery

1. Base + US1 → aba com os módulos e o progresso da conta (MVP).
2. US2 → abrir módulo e recarregar ao voltar.
3. US3 → visitante com progresso da sessão, aviso e transferência ao criar conta.
4. US4 → carregando, erro e vazio.
5. Polish → contrato 1.0.10, limpeza, suíte, aparelho, B1 marcada.

Cada história é um commit; o PR para a `develop` sai depois da validação no aparelho (T040).
