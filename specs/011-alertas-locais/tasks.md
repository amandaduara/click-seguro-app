---

description: "Task list for feature 011: Alertas locais de notícias novas (A6)"
---

# Tasks: Alertas locais de notícias novas

**Input**: Design documents from `/specs/011-alertas-locais/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/alerts.md](contracts/alerts.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): todo teste é escrito e **falha** antes da
implementação. Offline, com fakes à mão: `FakeHttpClientAdapter`
(`click_seguro_app/test/modules/common/api_client/fake_http_client_adapter.dart`),
`FakeLocalCacheService`, `FakeSecureStorageService` (`click_seguro_app/test/fakes/`) com
`UserSessionService` real nos widget tests, e os novos
`FakeNotificationsRemoteDataSource`/`FakeNotificationsLocalDataSource`
(`tnotif/fakes/fake_notifications_data_sources.dart`) e `FakeNotificationsRepository`
(`tnotif/fakes/fake_notifications_repository.dart`). `Completer` para segurar a conferência
(fila, marcar durante a conferência) e relógio injetado (`now`) para intervalo, 30 dias e grupos.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `notif/` =
  `click_seguro_app/lib/modules/notifications/`; `tnotif/` =
  `click_seguro_app/test/modules/notifications/`.
- Formato do serviço e do registro local em [contracts/alerts.md](contracts/alerts.md) e
  [data-model.md](data-model.md).

**Reaproveitado (não recriar)**: `ApiClient` (`get` com `queryParameters`) e `ApiException.toFailure()`
(`common/api_client/`), `LocalCacheService` (`readJson`/`writeJson`/`remove`),
`UserSessionService` (`sessionStatus`, `email`, `isAuthenticated`), `Failure`/`ConnectionFailure`/
`ServerFailure`/`CacheFailure` (`core/errors/`), `NotificationBellButton` e `NotificationsPage`
(esqueletos da F0.7/F0.9), rota `/notifications` (`notifications_routes.dart`, já sobre as abas),
`requireAccount` + `AccountRequiredSheet` (o `AppTopBar` do `shell` já os usa no sino),
`SafeButton`/`SafeCard`/`SafeEmptyState`/`SafeOfflineBanner` e `AppSpacing`/`context.colors`
(`core/`), chaves `common_offline_banner`, `common_account_required_*` e `notifications_title`,
padrão "módulo ouve a sessão" do `_AccountCopiesCleaner` (`news_module.dart`), padrão do
`SavedNewsPage` para o convite do visitante dentro da tela, helpers `fakeFeedProvider`/
`fakeReelsProvider` (`app/test/helpers/`) como modelo do novo `fakeNotificationsProvider`.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (0 erros, 0 warnings). Se algo estiver vermelho, parar e reportar
- [X] T002 Conferir no **servidor de desenvolvimento** (nunca produção; conta de teste criada pelo app e desativada no fim, como na feature 010) o que o `openapi.json` não diz, e registrar o resultado em [research.md](research.md) R0 e em [contracts/alerts.md](contracts/alerts.md) (`🧪` → `✅`): (1) formato aceito em `startDate` (ISO-8601 UTC esperado); (2) **qual data o filtro usa** (`publishedAt` ou `originalPublishedAt`) — se for a original, `AlertsRemoteDataSource` **não envia** `startDate` e T014 deve refletir; (3) `publishedAt` vem sempre?; (4) `startDate` é "maior ou igual" ou "maior que"; (5) `GET /users/me` traz `receiveNotifications` e `PATCH /users/me {"receiveNotifications": false}` o altera. Guardar 2 itens reais (JSON) para os fixtures do T003. **Bloqueia T003 em diante**; se algo divergir do contrato, atualizar o contrato antes de seguir

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, fixtures, fakes e as camadas `domain/` e `data/` dos alertas, usadas por todas as histórias.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Base de teste e textos

- [X] T003 [P] Criar `tnotif/fakes/alerts_fixtures.dart` com o JSON real do T002: `newsItemJson({required String id, String title, String source, String? publishedAt, String originalPublishedAt})`, `newsListJson(List<Map> items)` (`{data, meta}`), `profileJson({bool? receiveNotifications})` (omitir o campo quando `null`) e builders `alert({newsId, title, source, publishedAt, isRead})` e `snapshot({lastCheckAt, receiveAlerts, alerts})` com datas fixas (`now` de teste)
- [X] T004 [P] Criar `tnotif/fakes/fake_notifications_data_sources.dart` (`FakeNotificationsRemoteDataSource`: `newAlerts`, `newAlertsError`, `receiveAlerts`, `receiveAlertsError`, `Completer` opcional para segurar `fetchNewAlerts`, listas de chamadas; `FakeNotificationsLocalDataSource`: `snapshot`, contador de gravações, `saveError`, `clear`) e `tnotif/fakes/fake_notifications_repository.dart` (mesmos botões, sobre o `NotificationsRepository` do T014)
- [X] T005 [P] Acrescentar as chaves de i18n em `app/lib/core/i18n/app_strings.dart` (bloco `// --- notifications ---`, prefixo `notifications_`) e nos dois JSONs de `app/assets/translations/` (FR-021): grupos "Hoje"/"Ontem"/"Anteriores"; rótulo "Novo"; resumo com plural ("Você tem {} alertas novos"/"Você tem 1 alerta novo"/"Você não tem alertas novos"); "Marcar todos como lidos"; vazio ("Você não tem alertas." + "Quando sair uma notícia nova, ela aparece aqui."); convite do visitante (corpo curto; reaproveitar `common_account_required_*` no botão); aviso "Os alertas novos estão desligados." + "Ligar em Editar perfil"; rótulos de acessibilidade ("Alertas, {} novos", "Novo, {}"); e trocar `shell_notifications` de "Notificações" para "Alertas"/"Alerts" (R11). Atualizar `app/test/modules/shell/i18n_keys_test.dart` se a lista de chaves obrigatórias mudar

### Testes (escrever primeiro e ver falhar)

- [X] T006 [P] Criar `tnotif/data/models/alert_model_test.dart`: `AlertModel.fromNewsJson(newsItemJson(...))` → `newsId`, `title`, `source`, `publishedAt` em UTC, `isRead == false`; sem `publishedAt` usa `originalPublishedAt`; item sem `id`, sem `title`, sem `source` ou sem nenhuma das duas datas → `FormatException`; `toJson`/`fromJson` do registro (ida e volta, `isRead`); `AlertsSnapshotModel.fromJson` com `lastCheckAt`/`receiveAlerts` ausentes → `null`, `alerts` ausente → vazio e item ilegível descartado
- [X] T007 [P] Criar `tnotif/data/datasources/alerts_remote_data_source_impl_test.dart` com `FakeHttpClientAdapter`: `fetchNewAlerts(since, limit: 50)` → `GET /app/news` com `startDate` (ISO-8601 UTC de `since`), `sortBy=publishedAt`, `sortOrder=desc`, `limit=50` e `page=1` (ajustar ao T002: sem `startDate` se o filtro for pela data original); devolve só itens válidos e **ignora** o item sem `title`; `data` ausente ou não lista → `ApiException`/falha de resposta inválida (CB-005); `getReceiveAlerts()` → `GET /users/me` e lê `receiveNotifications` (ausente → `true`); erro de conexão e timeout → `ApiException` do tipo correspondente
- [X] T008 [P] Criar `tnotif/data/datasources/alerts_local_data_source_impl_test.dart` com `FakeLocalCacheService` e `owner` injetado: `write` grava em `notifications_alerts_v1` com `owner`, `lastCheckAt`, `receiveAlerts` e `alerts`; `read` devolve o registro do mesmo dono; **dono diferente** → `null`; registro ilegível ou sem `owner` → `null`; `clear` remove a chave; escrita única por `write` (contador de gravações); armazenamento que lança → exceção para o repository tratar
- [X] T009 [P] Criar `tnotif/data/repositories/notifications_repository_impl_test.dart`: `getSnapshot` com registro → snapshot, sem registro → snapshot vazio (`lastCheckAt == null`); `saveSnapshot` grava; falha de armazenamento → `Left(CacheFailure)`; `fetchNewAlerts` sucesso → lista de `AlertEntity`; `ApiException` de conexão/timeout → `Left(ConnectionFailure)`, outras → `Left(ServerFailure)`, 401 → `Left(UnauthorizedFailure)`; `getReceiveAlerts` idem; `clear` remove
- [X] T010 [P] Criar `tnotif/domain/check_new_alerts_usecase_test.dart` (todas as regras do [data-model](data-model.md), com `FakeNotificationsRepository` e `now` fixo): **sem `lastCheckAt`** → grava `lastCheckAt = now`, `outcome == firstRun` e **nenhuma** chamada a `getReceiveAlerts`/`fetchNewAlerts` (FR-003); `receiveAlerts == false` → grava `lastCheckAt = now` e `receiveAlerts = false`, sem alertas novos e sem `fetchNewAlerts` (FR-006); **falha** em `getReceiveAlerts` ou `fetchNewAlerts` → devolve `Left`, **nada gravado** (FR-005); sucesso → alertas novos com `isRead == false`, `lastCheckAt = now` e `receiveAlerts = true` numa **única** gravação; `since = max(lastCheckAt, now − 30 dias)`; candidato com `publishedAt <= lastCheckAt` descartado (rede de segurança do R0); `newsId` já existente **não** duplica e preserva `isRead`; repetido dentro da própria resposta entra uma vez; mais de 50 → ficam os 50 mais recentes por `publishedAt` decrescente (`maxAlerts = 50`); alerta com `publishedAt` anterior a `now − 30 dias` removido (`retentionDays = 30`); marcação feita entre o pedido e a mesclagem é preservada (o caso de uso lê o registro **de novo** antes de mesclar, R5)
- [X] T011 [P] Criar `tnotif/domain/notifications_domain_test.dart`: `AlertsSnapshot.unreadCount`, `isEmpty`, `markRead(newsId)` (id inexistente → igual, sem erro), `markAllRead()`; `GetAlertsUseCase`, `MarkAsReadUseCase`, `MarkAllAsReadUseCase` (gravam o snapshot alterado) e `ClearAlertsUseCase` repassam ao repository; `AlertEntity.copyWith(isRead:)` e igualdade por `newsId`

### Implementação

- [X] T012 [P] Criar `notif/domain/entities/alert_entity.dart` (`AlertEntity {String newsId; String title; String source; DateTime publishedAt; bool isRead}` com `copyWith(isRead:)` e igualdade por `newsId`), `alerts_snapshot.dart` (`AlertsSnapshot {DateTime? lastCheckAt; bool? receiveAlerts; List<AlertEntity> alerts}` + constantes `maxAlerts = 50` e `retentionDays = 30` + extension `unreadCount`, `isEmpty`, `markRead`, `markAllRead`, `merge(candidates, now)` que remove `publishedAt < now − 30 dias`, ordena por `publishedAt` decrescente e mantém 50) e `check_new_alerts_result.dart` (`CheckNewAlertsResult {AlertsSnapshot snapshot; CheckOutcome outcome}`, `enum CheckOutcome { firstRun, disabled, updated }`)
- [X] T013 [P] Criar `notif/data/models/alert_model.dart` (`fromNewsJson` com fallback `originalPublishedAt`, lança `FormatException` sem `id`/`title`/`source`/data; `fromJson`/`toJson`/`toEntity`/`fromEntity`) e `alerts_snapshot_model.dart` (`fromJson`/`toJson`, tolerante a `alerts` ausente e item ilegível). T006 verde
- [X] T014 Criar `notif/domain/repositories/notifications_repository.dart` (`getSnapshot`, `saveSnapshot`, `fetchNewAlerts({since, limit})`, `getReceiveAlerts`, `clear`, todos `Either<Failure, …>`) e os usecases `check_new_alerts_usecase.dart` (passos 1–7 do [data-model](data-model.md), com `call(DateTime now)`), `get_alerts_usecase.dart`, `mark_as_read_usecase.dart`, `mark_all_as_read_usecase.dart`, `clear_alerts_usecase.dart`. T010 e T011 verdes
- [X] T015 Criar `notif/data/datasources/alerts_remote_data_source.dart` e `_impl.dart` (`fetchNewAlerts({required DateTime since, required int limit})` e `getReceiveAlerts()`; constantes `newsPath = '/app/news'`, `mePath = '/users/me'`, `checkLimit = 50`; item inválido ignorado, `data` não-lista lança; **sem importar** `modules/news`). T007 verde
- [X] T016 Criar `notif/data/datasources/alerts_local_data_source.dart` e `_impl.dart` (`read()`, `write(snapshot)`, `clear()`; constante `cacheKey = 'notifications_alerts_v1'`; `owner: () => String` injetado; dono diferente, ausente ou registro ilegível → `null`; uma única escrita por `write`). T008 verde
- [X] T017 Criar `notif/data/repositories/notifications_repository_impl.dart` (mapeia `ApiException` com `toFailure()` e armazenamento que lança com `CacheFailure`; `getSnapshot` sem registro → snapshot vazio). T009 verde
- [X] T018 Em `notif/notifications_module.dart`, registrar os datasources (`AlertsRemoteDataSourceImpl(injector<ApiClient>())`, `AlertsLocalDataSourceImpl(injector<LocalCacheService>(), owner: () => injector<UserSessionService>().email ?? 'guest')`), o repository e os cinco usecases como `registerLazySingleton`. Rodar T006–T011: verdes

**Checkpoint**: dados e domínio dos alertas prontos; `flutter test tnotif` verde.

---

## Phase 3: User Story 1 - Saber pelo sino que há notícias novas (Priority: P1) 🎯 MVP

**Goal**: o app confere as notícias novas ao abrir, ao voltar e ao abrir a tela; cria um alerta por notícia; o sino mostra o número de não lidos; falhas são silenciosas.

**Independent Test**: com uma conta, voltar a última verificação 7 dias (entrada de desenvolvimento), reabrir o app e conferir o número no sino; reabrir e conferir que não muda.

### Tests for User Story 1

- [X] T019 [P] [US1] Criar `tnotif/fakes/notifications_controller_factory.dart` (monta o `NotificationsController` com `FakeNotificationsRepository`, `UserSessionService` real com `FakeSecureStorageService`, relógio injetado e `autoCheckInterval` padrão) e `app/test/helpers/notifications_provider.dart` (`fakeNotificationsProvider([...])` como o `fakeFeedProvider`)
- [X] T020 [P] [US1] Criar `tnotif/presentation/controller/notifications_controller_test.dart` (grupo conferência e contador): com conta, `load()` → `status` `loading` → `ready` com os alertas do registro e `unreadCount` derivado; `checkNew()` primeira vez → grava horário, `unreadCount == 0`; com notícias novas → `alerts` e `unreadCount` atualizados e `notifyListeners`; **falha** (qualquer) → alertas, contador e `lastCheckAt` iguais, nenhuma mensagem exposta, só `ConnectionFailure` preenche `lastCheckFailure`; `checkNew()` automático dentro de **5 minutos** (`autoCheckInterval`) da anterior é ignorado, `checkNew(force: true)` não; segunda chamada **durante** uma conferência não dispara outro pedido (`isChecking`); marcar como lido durante o pedido (com `Completer`) é preservado depois da mesclagem (R5); visitante/desconectado → nenhuma chamada ao repository e `unreadCount == 0` (FR-007)
- [X] T021 [P] [US1] Criar `tnotif/presentation/controller/alerts_lifecycle_trigger_test.dart`: ao criar com a sessão `authenticated` → chama `checkNew()` uma vez; sessão vira `authenticated` depois → chama; `AppLifecycleState.resumed` (via `tester.binding.handleAppLifecycleStateChanged`) → chama `checkNew()`; `paused` não chama; com visitante não chama; `dispose` remove o observador
- [X] T022 [P] [US1] Criar `tnotif/presentation/widgets/notification_bell_button_test.dart`: `unreadCount == 0` → só o sino e rótulo "Alertas"; `unreadCount == 3` → círculo com "3" (círculo ≥ 24 dp, número em negrito) e rótulo "Alertas, 3 novos"; o número muda quando o controller muda; `onPressed` é chamado ao tocar; área de toque ≥ 48×48 dp; sem `NotificationsController` acima o teste não é suportado (o provider é do módulo, R7)
- [X] T023 [P] [US1] Em `app/test/modules/shell/presentation/app_top_bar_test.dart`, acrescentar: com `fakeNotificationsProvider` e conta, o sino mostra o número de não lidos; visitante toca no sino → convite (`AccountRequiredSheet`) e nenhuma chamada ao repository; conta toca → `/notifications`. Atualizar com o `fakeNotificationsProvider` os testes que montam a barra, o app ou o roteador: `app/test/modules/shell/presentation/app_shell_test.dart`, `session_expired_listener_test.dart` (se montar o `AppTopBar`), `app/test/core/routing/app_router_test.dart`, `app/test/modules/news/presentation/pages/news_home_page_test.dart`, `app/test/accessibility_app_test.dart` e `app/test/widget_test.dart`

### Implementation for User Story 1

- [X] T024 [US1] Criar `notif/presentation/controller/alerts_status.dart` (`enum AlertsStatus { loading, ready }`) e `notif/presentation/controller/notifications_controller.dart` com o estado e as ações do [data-model](data-model.md#notificationscontroller-novo-único-acima-do-app) (`load`, `checkNew({force})` com `autoCheckInterval = Duration(minutes: 5)`, `isChecking`, `lastCheckFailure` só para `ConnectionFailure`, `unreadCount` derivado de `AlertsSnapshot`, fila de gravações do R5 com o pedido de rede fora da fila, gate por `sessionStatus == authenticated`, `now` injetável). T020 verde
- [X] T025 [US1] Criar `notif/presentation/controller/alerts_lifecycle_trigger.dart` (`WidgetsBindingObserver` que chama `checkNew()` na criação com sessão conectada, quando `sessionStatus` vira `authenticated` e em `resumed`; remove o observador e o listener no `dispose`). T021 verde
- [X] T026 [US1] Em `notif/notifications_module.dart`, preencher `providers`: `ChangeNotifierProvider<NotificationsController>` (`lazy: false`, com `..load()`), e um `Provider<AlertsLifecycleTrigger>` (`lazy: false`, `dispose`) criado **depois** do controller. Em `notif/notifications.dart`, exportar `NotificationsController` (o sino e os testes do shell precisam dele)
- [X] T027 [US1] Em `notif/presentation/widgets/notification_bell_button.dart`, ler `unreadCount` com `context.select<NotificationsController, int>` e desenhar o contador (círculo `primary` de pelo menos 24 dp no canto superior direito, número branco em negrito maior que o 10 sp do design system, sem ultrapassar o círculo de 48 dp do botão) e o `Semantics` "Alertas" / "Alertas, N novos" (`excludeSemantics` mantido). `onPressed` e a decisão de abrir/convite continuam no `AppTopBar`. T022 e T023 verdes
- [X] T028 [P] [US1] Em `app/lib/dev/accessibility_playground.dart`, acrescentar três botões fixos de texto (R10), como o "Notícias salvas" da 010: "Alertas: voltar verificação 7 dias" (grava `lastCheckAt = agora − 7 dias` no registro da conta atual via `AlertsLocalDataSource`, preservando `alerts`), "Alertas: apagar" (`ClearAlertsUseCase`) e "Abrir Alertas" (`router.push('/notifications')`, para o visitante no quickstart). Usar o `router` devolvido por `setupApp()`

**Checkpoint**: US1 funcionando — sino com número, conferência silenciosa; `flutter test` verde.

---

## Phase 4: User Story 2 - Ver os alertas e abrir a notícia (Priority: P1)

**Goal**: tela "Alertas" com resumo fixo, grupos Hoje/Ontem/Anteriores, "Novo" escrito, tocar marca como lido e abre `/news/:id`; vazio e sem internet.

**Independent Test**: com alertas guardados, tocar no sino, conferir grupos e ordem, tocar num alerta "Novo", ver a notícia abrir e, ao voltar, o alerta sem "Novo" e o sino com N−1.

### Tests for User Story 2

- [X] T029 [P] [US2] Criar `tnotif/presentation/extensions/alerts_grouping_test.dart` (`now` injetado): `sections(now)` → `today`/`yesterday`/`earlier` pela **data local** de `publishedAt` (virada de dia, fuso), do mais novo ao mais antigo dentro do grupo, **sem seção vazia**; data futura → `today`; lista vazia → sem seções. Criar `tnotif/presentation/extensions/alert_presentation_extension_test.dart`: `timeLabel(now)` → `HH:mm` (24 h, com zero à esquerda) em hoje/ontem e `dd/MM` em anteriores; `semanticLabel(now)` → "Novo, título, fonte, hora" e, lido, sem o "Novo"; `summaryText(unreadCount)` → chaves de zero, um e vários
- [X] T030 [P] [US2] Em `tnotif/presentation/controller/notifications_controller_test.dart` (grupo marcar como lido): `markAsRead(id)` muda `isRead` e `unreadCount` **na hora** (antes de a gravação terminar, com `Completer`), grava depois; id inexistente → sem efeito e sem erro; falha ao gravar mantém o estado em memória; persiste: novo controller sobre o mesmo registro mostra o alerta lido
- [X] T031 [P] [US2] Criar `tnotif/presentation/pages/notifications_page_test.dart` (grupo lista), com `GetIt` (`UserSessionService`), `fakeNotificationsProvider` e `MaterialApp.router` simples com `/notifications` e `/news/:id`: abrir a tela chama `checkNew(force: true)`; grupos "Hoje"/"Ontem"/"Anteriores" na ordem e sem grupo vazio; cada alerta mostra título, fonte, hora (hoje/ontem) ou data (anteriores) e "Novo" escrito só nos não lidos; resumo "Você tem N alertas novos" fixo no alto (não dentro da lista que rola); tocar num alerta → `markAsRead` e `push('/news/<newsId>')`; ao voltar, alerta sem "Novo"; **toque duplo** abre uma vez; sem alertas → "Você não tem alertas." com a explicação e sem botão de marcar; `lastCheckFailure` de conexão → `SafeOfflineBanner` fixa no alto com a lista guardada visível; nenhum `SnackBar` nem menu de três pontos

### Implementation for User Story 2

- [X] T032 [P] [US2] Criar `notif/presentation/extensions/alerts_grouping.dart` (`AlertGroup { today, yesterday, earlier }`, `AlertSection`, `List<AlertEntity>.sections(now)`) e `notif/presentation/extensions/alert_presentation_extension.dart` (`timeLabel`, `semanticLabel`, `summaryText`; `HH:mm`/`dd/MM` com `padLeft`, sem `intl`). T029 verde
- [X] T033 [US2] Em `notif/presentation/controller/notifications_controller.dart`, implementar `markAsRead(newsId)` (estado em memória primeiro, depois grava pela fila) e expor o necessário à tela (`alerts`, `lastCheckFailure`). T030 verde
- [X] T034 [P] [US2] Criar `notif/presentation/widgets/alert_tile.dart` (cartão tocável sobre `SafeCard`/`InkWell`: "Novo" escrito + título + "fonte · hora/data"; não lido com destaque (cor + texto), lido discreto mas com contraste AA; `Semantics` com `semanticLabel`; área ≥ 48 dp; guarda de toque duplo), `notif/presentation/widgets/alerts_summary_bar.dart` (só o resumo por enquanto; o botão entra na US3) e `notif/presentation/widgets/alerts_notices.dart` (faixa "sem internet" reaproveitando `SafeOfflineBanner`)
- [X] T035 [US2] Substituir `notif/presentation/pages/notifications_page.dart` pela tela real: `Scaffold` com `AppBar` ("Alertas", voltar); corpo em coluna com o resumo e as faixas **fixos** acima de um `ListView` agrupado (`SliverList` ou `ListView` com cabeçalhos "Hoje"/"Ontem"/"Anteriores", `Semantics(header: true)`); estado vazio com `SafeEmptyState`; ao abrir, `controller.checkNew(force: true)` fora do `build`; tocar → `controller.markAsRead` e `context.push('/news/${alert.newsId}')` (sem importar `news`). `notifications_routes.dart` mantém `/notifications` no `rootNavigatorKey`. T031 verde

**Checkpoint**: US1 + US2 funcionando.

---

## Phase 5: User Story 3 - Marcar todos como lidos (Priority: P2)

**Goal**: botão grande "Marcar todos como lidos", fixo no alto, que zera os não lidos de uma vez, sem confirmação.

**Independent Test**: com vários alertas novos, tocar no botão e ver tudo sem "Novo", o resumo "Você não tem alertas novos" e o sino sem número; reabrir o app e ver que continua.

### Tests for User Story 3

- [X] T036 [P] [US3] Em `tnotif/presentation/controller/notifications_controller_test.dart` (grupo marcar todos): `markAllAsRead()` deixa `unreadCount == 0` **na hora**, grava pela fila, é idempotente (segunda chamada não grava de novo), não perde alerta que chegou por conferência no meio (R5) e persiste entre controllers
- [X] T037 [P] [US3] Em `tnotif/presentation/pages/notifications_page_test.dart` (grupo marcar todos): com não lidos, o botão "Marcar todos como lidos" aparece **fixo** no alto, com texto e altura ≥ 48 dp; tocar → todos sem "Novo", resumo "Você não tem alertas novos" e botão some, **sem** diálogo de confirmação; sem não lidos (lista vazia ou tudo lido) → botão ausente

### Implementation for User Story 3

- [X] T038 [US3] Em `notif/presentation/controller/notifications_controller.dart`, implementar `markAllAsRead()` (`MarkAllAsReadUseCase` pela fila, estado em memória primeiro). T036 verde (o usecase ganhou o parâmetro opcional `newsIds`, para gravar só o que a tela mostrava)
- [X] T039 [US3] Em `notif/presentation/widgets/alerts_summary_bar.dart` e `notifications_page.dart`, acrescentar o botão "Marcar todos como lidos" (`SafeButton` com texto, só com `unreadCount > 0`, `Semantics` de botão, quebra de linha com letra grande) ligado a `markAllAsRead`. T037 verde

**Checkpoint**: US1–US3 funcionando.

---

## Phase 6: User Story 4 - Visitante e alertas desligados (Priority: P2)

**Goal**: visitante vê o convite (no sino e dentro da tela); "Receber alertas" desligado não gera alertas e a tela avisa; sair da conta apaga tudo e uma conta não vê a outra.

**Independent Test**: como visitante, tocar no sino e abrir `/notifications` e ver o convite; com a chave desligada, ver o sino parado e o aviso; sair e entrar com outra conta e não ver os alertas da primeira.

### Tests for User Story 4

- [X] T040 [P] [US4] Em `tnotif/presentation/controller/notifications_controller_test.dart` (grupo sessão e chave): `receiveAlerts == false` no snapshot → `controller.receiveAlerts == false` e nenhum alerta novo, `lastCheckAt` avança; sessão `authenticated` → `unauthenticated` → estado zerado (`alerts` vazio, `unreadCount == 0`), `ClearAlertsUseCase` chamado (registro apagado) e nenhuma conferência; `authenticated` → `guest` → estado zerado em memória; `guest` → `authenticated` → `load` + `checkNew`; outra conta no mesmo aparelho (dono diferente) → sem alertas e **primeira conferência** só marca o horário
- [X] T041 [P] [US4] Criar `tnotif/notifications_module_test.dart`: com `UserSessionService` e `FakeLocalCacheService`, gravar o registro; mudar `sessionStatus` para `unauthenticated` (sair **ou** sessão expirada) → registro apagado; `guest` e `authenticated` não apagam; o módulo registra os usecases e o provider do controller (`NotificationsModule().registerServices`/`providers`)
- [X] T042 [P] [US4] Em `tnotif/presentation/pages/notifications_page_test.dart` (grupo visitante e desligado): visitante → convite **dentro da tela** (texto curto, ícone, botão grande "Entrar ou criar conta" que vai a `/login`) e nenhuma chamada ao repository; sessão passa a `authenticated` com a tela aberta → mostra a lista; `receiveAlerts == false` → aviso fixo "Os alertas novos estão desligados." com o botão "Ligar em Editar perfil" que faz `push('/profile/edit')`, e a lista existente continua visível; `receiveAlerts == true` ou `null` → sem aviso

### Implementation for User Story 4

- [X] T043 [US4] Em `notif/presentation/controller/notifications_controller.dart`, ouvir `UserSessionService.sessionStatus` (R4): `unauthenticated` → zera o estado, chama `ClearAlertsUseCase` pela fila e cancela a conferência em andamento (resposta tardia descartada); `guest` → zera em memória; `authenticated` → `load()` + `checkNew()`; expor `receiveAlerts` (do snapshot). T040 e T041 verdes
- [X] T044 [US4] Em `notif/presentation/pages/notifications_page.dart` e `notif/presentation/widgets/alerts_notices.dart`, acrescentar o convite do visitante dentro da tela (mesmo padrão do `_GuestInvite` do `SavedNewsPage`, `ValueListenableBuilder` sobre `sessionStatus`) e a faixa fixa "Os alertas novos estão desligados." com o botão "Ligar em Editar perfil" (`context.push('/profile/edit')`, sem importar `profile`). T042 verde

**Checkpoint**: todas as histórias funcionando.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T045 [P] Em `tnotif/presentation/pages/notifications_page_test.dart` (grupo acessibilidade, FR-020, SC-008) e `notification_bell_button_test.dart`, ajustar o que falhar em `notifications_page.dart`/widgets: todos os alvos de toque ≥ 48×48 dp (sino, alerta, botão, "Ligar em Editar perfil", convite); fonte do sistema 2× sem sobreposição e com o texto do botão quebrando linha; ordem do `Semantics` título, resumo, botão, grupos, alertas; rótulo do sino com a quantidade; tema de alto contraste da feature 009 (contador, "Novo" e alerta lido legíveis) — ajuste de 2026-10-09: com letra ≥ 1,5× o resumo, o botão e as faixas entram na própria lista (uma rolagem só); abaixo disso o alto continua fixo, sem rolagem interna
- [X] T046 [P] Em `.specify/memory/api-contract.md`, seção "Alertas — A6": trocar `limit=20` por `limit=50` (R6), registrar o resultado do T002 (campo de data do `startDate`, formato, `receiveNotifications` em `GET /users/me`), marcar a linha `🧪` → `✅` **só** depois do T049 e acrescentar a entrada de changelog (1.0.7). Atualizar a versão/data
- [X] T047 [P] Em `.specify/memory/plan.md`: linha "Alertas (A6)" da §3 (usecases do módulo: sai `GetUnreadCount`, entra `ClearAlerts`; contador derivado), a nota "Alertas locais (A6)" (§3: conferência ao abrir, ao voltar ao app e ao abrir a tela; `receiveNotifications` lida de `GET /users/me` pelo datasource do módulo; intervalo de 5 minutos) e a rastreabilidade; em `.specify/memory/design-system.md` §7.11, o contador do sino (círculo ≥ 24 dp, texto maior que 10/700 por legibilidade, RNF-003)
- [X] T048 Formatar só os arquivos tocados (`dart format` em `notif/`, `tnotif/`, `app/test/helpers/notifications_provider.dart`, `app/lib/dev/accessibility_playground.dart`, `app_strings.dart` e nos testes do shell alterados), depois `flutter analyze` (sem avisos novos) e `flutter test` (todos verdes). Revisar código morto e confirmar com `grep` que `notif/` **não importa** `modules/news`, `modules/shell`, `modules/authentication` nem `modules/profile`
- [X] T049 Validar no aparelho os passos 1–18 do [quickstart.md](quickstart.md) (SC-001, SC-007 e a conferência real do `startDate` só são verificados aqui; usar conta de teste e desativá-la no fim). Guardar prints e relatório em `specs/011-alertas-locais/evidencias/` e anotar o resultado nesta tarefa
  - **Resultado (2026-10-09, emulador Pixel 4, servidor de desenvolvimento)**: passos 1–13 e 15–18 conformes; passo 14 só em parte (o app ainda não tem saída da conta na interface: coberto o isolamento por dono, com o registro de outro e-mail ignorado e substituído; a limpeza ao sair segue coberta só pelos testes automáticos, como na 010). **SC-001** conforme (3,45 s, 3,12 s e 2,93 s do comando de abrir até o contador aparecer; limite 5 s). **SC-007** conforme (2 toques: sino, alerta). Sino com 12 novos = as 12 notícias dos últimos 7 dias; reabrir não repete (SC-002); 1ª conferência sem alertas (SC-003); desligado sem alertas (SC-005); offline guarda número e lista com faixa fixa (SC-006, SC-009). Grupos Hoje/Ontem/Anteriores conferidos (Hoje e Ontem com `publishedAt` ajustado no registro, porque as notícias reais só caem em Anteriores). Letra 1,3× com topo fixo; 1,5× + alto contraste e 2× do sistema com uma rolagem só, nada cortado; TalkBack por árvore de acessibilidade; inglês conforme. **"99+"** não alcançável: o app guarda no máximo 50 (50 alertas de teste mostraram "50"); segue coberto só por teste de widget. **R0**: `startDate` usa `publishedAt`; diferença de relógio aparelho×serviço 0 s (emulador usa o relógio do host). Nenhum defeito do app. Conta de teste `teste-a6v-20261009232834@example.com`, desativada no fim. Prints e relatório em [evidencias/](evidencias/) ([relatório](evidencias/relatorio-de-teste.md)). Não marcada `[X]` por causa do passo 14 e do "99+", a decidir pelo orquestrador
  - **Aceite (2026-10-09)**: passo 14 aceito em parte (sair da conta pela interface chega na B7/B8; limpeza coberta por testes; isolamento por dono conferido no aparelho). "99+" coberto só por teste de widget: o registro guarda no máximo 50 alertas. Tocar num alerta sem internet o marca como lido mesmo com o detalhe em erro: aceito, a pessoa escolheu abrir aquele alerta.
- [X] T050 Em `.specify/memory/tasks.md`, marcar a A6 como `[x] **A6 Alertas locais** … (specs/011-alertas-locais)` e acertar a descrição (sem `GetUnreadCount`, com `ClearAlerts`). Conferir que a rota `/notifications` consta no §2 de `.specify/memory/plan.md` (consta) e que o [api-contract.md](../../.specify/memory/api-contract.md) está atualizado (T046)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro; **T002 bloqueia T003 e T007** (fixtures e query reais).
- **Foundational (Phase 2)**: T003 ∥ T004 ∥ T005; testes T006–T011 em paralelo (T004 antes dos que usam fakes: T009–T011); T012 ∥ T013; T014 depois de T012; T015, T016 depois de T013; T017 depois de T014–T016; T018 por último.
- **US1 (Phase 3)**: depende da Phase 2. T019 ∥ T020 ∥ T021 ∥ T022 ∥ T023; T024 → T025 → T026; T027 depois de T026; T028 em paralelo.
- **US2 (Phase 4)**: depende da US1 (controller e módulo). T029 ∥ T030 ∥ T031; T032 ∥ T034; T033 depois de T024; T035 depois de T032–T034.
- **US3 (Phase 5)**: depende da US2 (página e `AlertsSummaryBar`). T036 ∥ T037; T038 → T039.
- **US4 (Phase 6)**: depende da US1 (controller) e da US2 (página); independe da US3 na lógica (a página é o mesmo arquivo: fazer em sequência com a US3). T040 ∥ T041 ∥ T042; T043 → T044.
- **Polish (Phase 7)**: depois de todas; T045 ∥ T046 ∥ T047; T048 depois; T049 depois de T048; T050 por último.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Controller → extension → widgets → página.
- Commit ao fim de cada fase (Base, US1, US2, US3, US4, Polish).

### Parallel Opportunities

- **Phase 2:** T003 ∥ T004 ∥ T005; T006 ∥ T007 ∥ T008 ∥ T009 ∥ T010 ∥ T011; T012 ∥ T013.
- **US1:** T019 ∥ T020 ∥ T021 ∥ T022 ∥ T023; T028 em paralelo com T024–T027.
- **US2:** T029 ∥ T030 ∥ T031; T032 ∥ T034. **US3:** T036 ∥ T037. **US4:** T040 ∥ T041 ∥ T042.
- **Polish:** T045 ∥ T046 ∥ T047.

---

## Parallel Example: Phase 2 (testes)

```bash
Task: "Teste do model em click_seguro_app/test/modules/notifications/data/models/alert_model_test.dart"
Task: "Teste do datasource remoto em click_seguro_app/test/modules/notifications/data/datasources/alerts_remote_data_source_impl_test.dart"
Task: "Teste do datasource local em click_seguro_app/test/modules/notifications/data/datasources/alerts_local_data_source_impl_test.dart"
Task: "Teste do repository em click_seguro_app/test/modules/notifications/data/repositories/notifications_repository_impl_test.dart"
Task: "Teste do CheckNewAlertsUseCase em click_seguro_app/test/modules/notifications/domain/check_new_alerts_usecase_test.dart"
Task: "Teste dos demais usecases e do snapshot em click_seguro_app/test/modules/notifications/domain/notifications_domain_test.dart"
```

## Parallel Example: User Story 1

```bash
Task: "Teste do NotificationsController (conferência e contador) em click_seguro_app/test/modules/notifications/presentation/controller/notifications_controller_test.dart"
Task: "Teste do gatilho do ciclo de vida em click_seguro_app/test/modules/notifications/presentation/controller/alerts_lifecycle_trigger_test.dart"
Task: "Teste do sino em click_seguro_app/test/modules/notifications/presentation/widgets/notification_bell_button_test.dart"
Task: "Testes do shell com o provider de alertas em click_seguro_app/test/modules/shell/presentation/app_top_bar_test.dart"
```

---

## Cobertura (spec → tarefas)

- **US1 / FR-001 a FR-010 (geração, falha silenciosa, contador, sino)**: T006–T018 (regras do caso de uso), T019–T028; FR-003 em T010/T020; FR-004 em T010/T012; FR-005 em T010/T020; FR-008 a FR-010 em T022/T023/T027.
- **US2 / FR-011 a FR-015**: T029–T035 (grupos, "Novo", abrir a notícia, vazio, sem internet).
- **US3 / FR-014 (botão)**: T036–T039.
- **US4 / FR-006, FR-007, FR-016 a FR-019**: T010 (chave desligada), T040–T044 (sessão, convite, aviso, dono, limpeza).
- **FR-020, FR-021**: T005 (i18n), T045 (48 dp, rótulos, alto contraste, fonte 2×).
- **SC-001 a SC-009**: T020/T021 (SC-001, SC-009), T010 (SC-002, SC-003, SC-005), T020/T042 (SC-004), T049 (SC-001, SC-006, SC-007), T045 (SC-008).

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): conferência silenciosa e sino com número.
3. **PARAR e VALIDAR**: `flutter test` verde e os passos 3 a 5 do quickstart.

### Incremental Delivery

1. Base → dados e domínio.
2. US1 → contador no sino (MVP).
3. US2 → tela de alertas e abrir a notícia.
4. US3 → marcar todos como lidos.
5. US4 → visitante, chave desligada e limpeza ao sair.
6. Polish → acessibilidade, contrato, aparelho e marcar a A6.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- Verifique que o teste falha antes de implementar.
- A Trilha A é da Amanda: combinar antes de abrir a PR para a `develop` (A6 também mexe em
  `shell` só nos testes, e em `lib/dev`). A tela de edição do perfil com "Receber alertas" é da
  B7 e a linha "Alertas" de Configurações é da B8; esta feature só usa as rotas `/profile/edit`
  e `/notifications`.
- Sem push: o app só confere as notícias quando está aberto (decisão de produto v1).
- O marcador do FR-006 (religar "Receber alertas") segue a proposta "não gera alertas do período
  desligado" até o usuário responder; se mudar, ajustar T010, T014 e a spec.
- Sem chamadas ao servidor de produção: só o servidor de desenvolvimento, com conta de teste
  desativada no fim (T002, T049).
