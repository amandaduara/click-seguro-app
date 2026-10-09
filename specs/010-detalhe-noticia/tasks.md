---

description: "Task list for feature 010: Detalhe da notícia e notícias salvas (A5)"
---

# Tasks: Detalhe da notícia e notícias salvas

**Input**: Design documents from `/specs/010-detalhe-noticia/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/news-detail.md](contracts/news-detail.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): todo teste é escrito e **falha** antes da
implementação. Offline, com fakes à mão: `FakeHttpClientAdapter`
(`click_seguro_app/test/modules/common/api_client/fake_http_client_adapter.dart`),
`FakeNewsRemoteDataSource`/`FakeNewsLocalDataSource`
(`tnews/fakes/fake_news_data_sources.dart`) e `FakeNewsRepository`
(`tnews/fakes/fake_news_repository.dart`), que ganham detalhe, leitura, salvas e cópias;
`FakeTextToSpeechService`, `FakeShareService`, `FakeExternalLauncherService`,
`FakeLocalCacheService` e `FakeSecureStorageService` (`click_seguro_app/test/fakes/`) com
`UserSessionService` real nos widget tests. `Completer` para segurar respostas (salvar otimista,
leitura sem esperar).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `news/` =
  `click_seguro_app/lib/modules/news/`; `tnews/` = `click_seguro_app/test/modules/news/`.
- Formato JSON real em [research R0](research.md) e em [contracts/news-detail.md](contracts/news-detail.md).

**Reaproveitado (não recriar)**: `NewsItemEntity`/`NewsInteraction`/`NewsCategoryEntity`,
`NewsPageEntity.appendUnique`, `NewsItemModel.fromJson`, `NewsListModel`, `NewsNotFoundFailure`
(`news/domain/failures/news_failures.dart`), `ToggleSaveUseCase`, `_guardNews` do
`NewsRepositoryImpl`, extension `NewsItemPresentation` (`relativeDate`, `categoryLabels`,
`semanticLabel`), `NewsCard`, `FeedStatus`, `ReadAloudController` (factory do `CommonModule`),
`ShareService`, `ExternalLauncherService` + `isOpenableWebUrl`, `requireAccount`,
`LocalCacheService`, `UserSessionService.sessionStatus`/`email`,
`SafeLoadingState`/`SafeErrorState`/`SafeEmptyState`/`SafeOfflineBanner`/`SlowRequestNotice`,
chaves de i18n `news_reels_saved*`, `news_reels_open_source*`, `news_error_not_found`,
`news_slow_server`, `common_offline_banner`, `common_account_required_*`.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (0 erros, 0 warnings). Se algo estiver vermelho, parar e reportar

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, fixtures e as camadas `domain/` e `data/` do detalhe, da leitura e das salvas, usadas por todas as histórias.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Base de teste e textos

- [X] T002 [P] Em `tnews/fakes/news_fixtures.dart`, acrescentar com o JSON real do [R0](research.md): `suggestedModuleJson({String id = 'm1', int lessonsCount = 3, String? iconUrl})`, `newsDetailJson({required String id, String content = 'Texto completo', int likesCount = 2, int readsCount = 1, bool isSaved = false, String? imageUrl, Map<String, dynamic>? suggestedModule})` (com `isHighlight`, `createdAt`, `categories`, `interaction {isLiked,isSaved,isRead}` e `suggestedModule` `null` quando omitido) e `savedListJson({required List<Map<String, dynamic>> items, int page = 1, bool hasNextPage = false})` (`data` + `meta {page, limit, total, totalPages, hasNextPage, hasPreviousPage}`; os itens vêm de `newsItemJson`, **sem** `content`, `createdAt` nem `isHighlight`). Conferir que os testes existentes continuam verdes
- [X] T003 [P] Acrescentar as chaves de i18n em `app/lib/core/i18n/app_strings.dart` (bloco `// --- news ---`, prefixo `news_detail_`/`news_saved_`) e nos dois JSONs de `app/assets/translations/` (FR-023): "Ouvir"/"Parar", "Velocidade: {}" e os nomes lenta/normal/rápida (o `app_strings.dart` ainda não tem rótulos de velocidade), "{} curtidas" do detalhe, "Compartilhar", "Pratique o que aprendeu" e "{} perguntas", "O texto completo desta notícia não está disponível.", "Notícias salvas" (título), "Você ainda não salvou nenhuma notícia." com a dica de usar o marcador, texto do convite no lugar da lista. **Reusar** (não duplicar) `news_reels_saved`, `news_reels_saved_toast`, `news_reels_removed_toast`, `news_reels_open_source`, `news_reels_open_source_failed`, `news_error_not_found`, `news_slow_server`, `common_offline_banner`. `app/test/modules/shell/i18n_keys_test.dart` cobre pt-BR × en-US; acrescentar as chaves novas à lista dele se ela for explícita

### Testes (escrever primeiro e ver falhar)

- [X] T004 [P] Criar `tnews/data/models/news_detail_model_test.dart`: `NewsDetailModel.fromJson(newsDetailJson(...))` → `NewsDetailEntity` com `news` completo (via `NewsItemModel.fromJson`), `content`, `likesCount`/`readsCount` (`num` → `int`), `interaction.isSaved`; `content` ausente → `''`; `likesCount`/`readsCount` ausentes → 0; `suggestedModule` presente → `SuggestedModuleModel` (`iconUrl` vazio → `null`, `description` pode ser vazio); `suggestedModule` `null`, ausente ou sem `id` → `null`; campo obrigatório faltando (`id`, `title`, `source`, `sourceUrl`, `originalPublishedAt`) → lança (CB-005); item da lista de salvas (sem `content`/`createdAt`/`isHighlight`) passa por `NewsListModel.fromJson` sem erro e com `hasMore` de `meta.hasNextPage`
- [X] T005 [P] Em `tnews/data/datasources/news_remote_data_source_impl_test.dart`, acrescentar: `getNewsDetail('n1')` → `GET /app/news/n1`, devolve o JSON cru (`Map<String, dynamic>`); `markAsRead('n1')` → `POST /app/news/n1/read` com `Bearer`, 204 sem corpo sem erro; `getSavedNews(page: 2)` → `GET /users/me/news/saved?page=2&limit=20` (constante `savedPageSize = 20`) → `NewsListModel`; 404 `NEWS_NOT_FOUND` → `ApiException` com `statusCode: 404`
- [X] T006 [P] Em `tnews/data/datasources/news_local_data_source_impl_test.dart`, acrescentar (com `FakeLocalCacheService` e relógio injetado): detalhes — `writeDetail(json)` grava em `news_detail_cache_v1` com `owner` e `savedAt`; mais recente primeiro; id já existente sobe para o topo sem repetir; máximo `maxCachedDetails = 30` (o excedente sai do fim); `readDetail(id)` devolve o JSON cru; id ausente → `null`; cópia de outro dono → `null` e substituída na próxima gravação; visitante grava com `owner == 'guest'`; JSON ilegível → `null`. Salvas — `writeSavedPage(json)`/`readSavedPage()` em `news_saved_cache_v1` só da página 1, substituída a cada gravação, dono diferente → `null`. `clearAccountCopies()` remove as duas chaves e **não** mexe em `news_feed_cache_v1`
- [X] T007 [P] Em `tnews/data/repositories/news_repository_impl_test.dart`, acrescentar: `getNewsDetail` sucesso → `Right(NewsDetailResult(isFromCache: false))` e grava a cópia (inclusive com `isSaved == false` e para visitante); falha de `connection`/`timeout` com cópia → `Right(isFromCache: true)`; sem cópia → `Left` da falha; erro `server` (500) **não** usa a cópia; 404/`NEWS_NOT_FOUND` → `Left(NewsNotFoundFailure)` sem tocar na cópia; resposta malformada → `Left` genérico, não lança; `markAsRead` sucesso → `Right(unit)`, falha → `Left`; `getSavedNews(1)` sucesso → `Right(SavedNewsResult)` e grava a 1ª página; só a página 1 grava; `connection`/`timeout` na página 1 com cópia → `isFromCache: true`; página 2 sem internet → `Left` (sem cópia); 401 → `UnauthorizedFailure`
- [X] T008 [P] Em `tnews/domain/news_domain_test.dart`, acrescentar: `GetNewsDetailUseCase`, `MarkNewsAsReadUseCase`, `GetSavedNewsUseCase` repassam ao repository; `NewsDetailEntity.hasSource` (`sourceUrl` vazio ou não `http(s)` → `false`), `isSaved` (= `news.interaction.isSaved`), `copyWith(isSaved:)` troca só `news.interaction.isSaved`

### Implementação

- [X] T009 [P] Criar `news/domain/entities/news_detail_entity.dart` (`SuggestedModuleEntity {String id; String title; String description; String? iconUrl; int lessonsCount}`, `NewsDetailEntity {NewsItemEntity news; String content; int likesCount; int readsCount; SuggestedModuleEntity? suggestedModule}` com getters `id`, `hasSource`, `isSaved` e `copyWith({bool? isSaved})`, e `NewsDetailResult {NewsDetailEntity detail; bool isFromCache}`) e `news/domain/entities/saved_news_result.dart` (`SavedNewsResult {NewsPageEntity page; bool isFromCache}`). Seguir as regras do [data-model](data-model.md#domínio) (`content` pode ser vazio; `description` pode ser vazio; `iconUrl` vazio → `null`)
- [X] T010 [P] Criar `news/data/models/news_detail_model.dart` (`NewsDetailModel` + `SuggestedModuleModel`; reaproveita `NewsItemModel.fromJson` para a parte comum; `content` ausente → `''`; `num` → `int`; `suggestedModule` `null`/ausente/sem `id` → `null`; campo obrigatório faltando → lança). T004 verde
- [X] T011 Em `news/domain/repositories/news_repository.dart`, acrescentar `getNewsDetail(String id)` → `Either<Failure, NewsDetailResult>`, `markAsRead(String id)` → `Either<Failure, Unit>` e `getSavedNews(int page)` → `Either<Failure, SavedNewsResult>`; criar `news/domain/usecases/get_news_detail_usecase.dart`, `mark_news_as_read_usecase.dart`, `get_saved_news_usecase.dart`. T008 verde
- [X] T012 Em `news/data/datasources/news_remote_data_source.dart` e `_impl.dart`, acrescentar `getNewsDetail(String id)` (JSON cru, para a cópia), `markAsRead(String id)` e `getSavedNews({required int page})` (constante `savedPageSize = 20`) via `ApiClient`. T005 verde
- [X] T013 Em `news/data/datasources/news_local_data_source.dart` e `_impl.dart`, acrescentar `readDetail(String id)`, `writeDetail(Map<String, dynamic> json)`, `readSavedPage()`, `writeSavedPage(Map<String, dynamic> json)` e `clearAccountCopies()`; constantes `detailCacheKey = 'news_detail_cache_v1'`, `savedCacheKey = 'news_saved_cache_v1'`, `maxCachedDetails = 30`; o dono vem de um parâmetro nomeado `String Function()? owner` do construtor (padrão `() => 'guest'`), que o `NewsModule` liga a `UserSessionService.email` (R3). Ajustar as construções existentes de `NewsLocalDataSourceImpl` nos testes. T006 verde
- [X] T014 Em `news/data/repositories/news_repository_impl.dart`, implementar os três métodos: `getNewsDetail` e `getSavedNews(1)` usam a cópia só em `ApiErrorType.connection`/`timeout` (**não** reaproveitar `_offlineErrors` do feed, que inclui `server`); 404 → `NewsNotFoundFailure` via `_guardNews`; gravar o JSON cru do detalhe a cada sucesso e a 1ª página das salvas; `markAsRead` por `_guard`. T007 verde
- [X] T015 Atualizar `tnews/fakes/fake_news_data_sources.dart` (`FakeNewsRemoteDataSource` com `detail`/`detailError`/`savedPages` por página/`markAsReadError` e listas de chamadas; `FakeNewsLocalDataSource` com as cópias de detalhe e salvas, contador de gravações e `clearAccountCopies`), `tnews/fakes/fake_news_repository.dart` (`detailResults`/`savedResults` em fila, `readResults`, `detailGate`/`savedGate`/`readGate` `Completer`, `detailCalls`/`readCalls`/`savedCalls`; helper `newsDetail(String id, {String content = 'Texto', bool isSaved = false, SuggestedModuleEntity? suggestedModule, String sourceUrl = 'https://fonte.test/n'})`) e criar `tnews/fakes/news_detail_controller_factory.dart` e `tnews/fakes/saved_news_controller_factory.dart` no padrão de `reels_controller_factory.dart`
- [X] T016 Em `news/news_module.dart`, registrar `GetNewsDetailUseCase`, `MarkNewsAsReadUseCase`, `GetSavedNewsUseCase` e passar `owner: () => injector<UserSessionService>().email ?? 'guest'` ao `NewsLocalDataSourceImpl`. Rodar T004–T008: verdes

**Checkpoint**: dados e domínio do detalhe e das salvas prontos; `flutter test tnews` verde.

---

## Phase 3: User Story 1 - Ler a notícia completa (Priority: P1) 🎯 MVP

**Goal**: o detalhe mostra imagem, categorias, título, fonte, data, curtidas e texto completo, com estados e registro de leitura sem bloquear.

**Independent Test**: como visitante, abrir uma notícia pelo feed e conferir todos os campos; com conta, conferir que a leitura foi registrada.

### Tests for User Story 1

- [X] T017 [P] [US1] Criar `tnews/presentation/controller/news_detail_controller_test.dart` (grupo carga): `status` `loading` → `loaded` com `detail`; `isFromCache` da cópia; 404 → `notFound`; outra falha → `error` + `failure`; `retry()` recarrega; com `authenticated` e detalhe do servidor → `markAsRead` chamado **sem esperar** (`readGate` segurando e a tela já `loaded`, SC-002) e uma vez por abertura; falha do `markAsRead` não muda o estado; visitante → `readCalls` vazio; detalhe vindo da cópia → não chama `markAsRead`; resposta de carga antiga ignorada; `sessionStatus` virar `authenticated` com a tela aberta → `load()` de novo
- [X] T018 [P] [US1] Criar `tnews/presentation/extensions/news_detail_presentation_extension_test.dart`: `formattedLikes` com as mesmas regras do `ReelEntity` (0 → "0", 999 → "999", 1200 → "1,2 mil"); `hasContent` (`content` só com espaços → `false`); `semanticLabel(now)` na ordem título, fonte, data
- [X] T019 [P] [US1] Criar `tnews/presentation/pages/news_detail_page_test.dart` (grupo leitura), com `GetIt` (`UserSessionService`, `FakeTextToSpeechService`, `FakeShareService`, `FakeExternalLauncherService`) e `MaterialApp.router` simples com `/news/:id`: carregando com barra superior e voltar; "Conectando ao servidor…" após `SlowRequestNotice.delay`; erro com "Tentar novamente" que recarrega; `notFound` com "Notícia não encontrada", voltar e **sem** "Tentar novamente"; detalhe completo (imagem, categorias, título, fonte, data no formato do feed, "{} curtidas", texto) com rolagem; sem imagem não quebra e não sobra espaço; texto vazio → "O texto completo desta notícia não está disponível."; cópia → `SafeOfflineBanner`; voltar mantém a tela anterior

### Implementation for User Story 1

- [X] T020 [US1] Criar `news/presentation/controller/news_detail_status.dart` (`enum NewsDetailStatus { loading, loaded, error, notFound }`) e `news/presentation/controller/news_detail_controller.dart` com o estado e as ações de carga do [data-model](data-model.md#newsdetailcontroller--um-por-página) (`load`, `retry`, `_requestId`, `unawaited(markAsRead)` só com `UserSessionStatus.authenticated` e detalhe do servidor, recarga ao virar `authenticated`, listener removido no `dispose`). Construtor recebe `getNewsDetail`, `markAsRead`, `toggleSave`, `sessionStatus` (`ValueListenable<UserSessionStatus>`), `newsId`. T017 verde
- [X] T021 [P] [US1] Criar `news/presentation/extensions/news_detail_presentation_extension.dart` (`formattedLikes`, `hasContent`, `semanticLabel(now)` reaproveitando `NewsItemPresentation`). Extrair a formatação de curtidas de `news/presentation/extensions/reel_presentation_extension.dart` para uma função compartilhada, usada pelos dois (sem duplicar a regra do "mil"). T018 verde e os testes da 008 continuam verdes
- [X] T022 [US1] Criar `news/presentation/widgets/news_detail_header.dart` (imagem com `errorBuilder` e fundo neutro do feed, categorias via `categoryLabels`, título, "fonte · data" via `relativeDate`, "{} curtidas"; `Semantics` com a ordem título, fonte, data)
- [X] T023 [US1] Substituir `news/presentation/pages/news_detail_page.dart` pela tela real: `AppBar` com voltar; `Scaffold` com corpo `SingleChildScrollView`; estados `loading` (`SafeLoadingState` + `SlowRequestNotice`, `news_slow_server`), `error` (`SafeErrorState` com "Tentar novamente"), `notFound` (mensagem + voltar, sem retry), `loaded` (cabeçalho, `SafeOfflineBanner` se `isFromCache`, texto ou aviso de texto vazio). Em `news/presentation/routes/news_routes.dart`, a rota `/news/:id` cria `ChangeNotifierProvider(create: (_) => NewsDetailController(...)..load())` (um por abertura). T019 verde; rodar `flutter test tnews`

**Checkpoint**: US1 completa e testável sozinha (MVP).

---

## Phase 4: User Story 2 - Ouvir a notícia (Priority: P1)

**Goal**: "Ouvir"/"Parar" com velocidade, leitura automática uma vez por abertura, parada ao sair, nada de voz quando não há.

**Independent Test**: com voz em português, ouvir, trocar a velocidade, parar; ligar a leitura automática e reabrir; sem voz, o botão some.

### Tests for User Story 2

- [X] T024 [P] [US2] Em `tnews/presentation/controller/news_detail_controller_test.dart` (grupo auto-leitura): `autoReadDone` começa `false`; `markAutoReadDone()` o liga e não desliga; novo `load()` por `retry` ou por virar `authenticated` não reabre a leitura automática se já feita
- [X] T025 [P] [US2] Em `tnews/presentation/pages/news_detail_page_test.dart` (grupo ouvir), com `FakeTextToSpeechService` e `ReadAloudController` real: voz no idioma → "Ouvir" e seletor lenta/normal/rápida começando na velocidade guardada (`AccessibilityPreferencesNotifier`); tocar em "Ouvir" → `spoken` com `"<título>.\n\n<texto>"`, idioma do app e velocidade escolhida, botão vira "Parar"; "Parar" → `stopCalls` e volta a "Ouvir"; trocar velocidade vale para a próxima leitura e **não** muda a preferência guardada; texto vazio → lê só o título; `autoReadAloud` ligado + voz → começa sozinho depois da carga, uma vez só; "Parar" logo depois não recomeça; sem voz (`availableLanguages` vazio) → sem "Ouvir", sem seletor, sem erro e sem leitura automática; app em en-US com notícia em português → idioma `en` (RF-042, Clarifications); sair da tela → `stop`; rótulos "Ouvir", "Parar", "Velocidade: normal"; botões ≥ 48×48 dp

### Implementation for User Story 2

- [X] T026 [US2] Em `news/presentation/controller/news_detail_controller.dart`, acrescentar `autoReadDone` e `markAutoReadDone()` (R5, FR-008). T024 verde
- [X] T027 [US2] Em `news/presentation/extensions/news_detail_presentation_extension.dart`, acrescentar `spokenText` (`"<título>.\n\n<texto>"`; sem texto, só o título) e os rótulos de acessibilidade de ouvir/parar/velocidade; criar `news/presentation/widgets/read_aloud_bar.dart` (botão "Ouvir"/"Parar" e seletor de velocidade, oculto quando `!isAvailable`, quebra de linha com fonte 2×)
- [X] T028 [US2] Em `news/presentation/pages/news_detail_page.dart` (e `news_routes.dart`), obter o `ReadAloudController` (`GetIt.instance<ReadAloudController>()` pelo factory do `CommonModule`, descartado no `dispose` da página), chamar `prepare(context.locale)` em paralelo com a carga e disparar a leitura automática quando carga e preparo terminarem, se `AccessibilityPreferencesNotifier.value.autoReadAloud && isAvailable && !autoReadDone`; "Parar" chama `markAutoReadDone()`; ligar "Ouvir"/"Parar" e a velocidade a `ReadAloudController`. T025 verde

**Checkpoint**: US1 + US2 funcionando.

---

## Phase 5: User Story 3 - Salvar a notícia e ver as salvas (Priority: P2)

**Goal**: marcador de salvar no detalhe (otimista, convite para visitante) e a tela "Notícias salvas" com cópia offline e limpeza ao sair.

**Independent Test**: com conta, salvar no detalhe, abrir "Notícias salvas" pela entrada de desenvolvimento, ver a notícia, remover, ver sumir; offline ver a cópia; como visitante, ver o convite.

### Tests for User Story 3

- [X] T029 [P] [US3] Em `tnews/presentation/controller/news_detail_controller_test.dart` (grupo salvar): `toggleSave()` com `saveGate` segurando → `isSaved` já invertido e `isSaving == true`; ao soltar com `true`/`false` → exatamente o estado devolvido e `message` `saved`/`removed`; segundo toque durante o pedido → ignorado (1 chamada em `saveCalls`); falha → estado anterior restaurado, `message` `saveFailed` com a falha; 404 (`NewsNotFoundFailure`) → volta e `notFound`; toque sem detalhe carregado → ignorado
- [X] T030 [P] [US3] Criar `tnews/presentation/controller/saved_news_controller_test.dart`: `load()` → `loading` → `loaded` com a página 1 (20 por página); lista vazia → `items.isEmpty` (vazio derivado, ver T034); `loadMore()` perto do fim junta sem repetir (`appendUnique`), página sem nada novo encerra (`hasMore == false`), sem `hasMore` não pede, dois `loadMore` seguidos → um pedido, falha → `loadMoreFailure` e itens mantidos; `isFromCache` só na página 1; `refresh()` volta à página 1 e substitui a lista (notícia removida some); falha sem cópia → `error`; resposta antiga ignorada (`_requestId`)
- [X] T031 [P] [US3] Em `tnews/presentation/pages/news_detail_page_test.dart` (grupo salvar): visitante toca no marcador → convite (`AccountRequiredSheet`) e `saveCalls` vazio, marcador vazio mesmo com `isSaved: true` no JSON; com conta (`saveSession`) → marcador reflete o `isSaved` do serviço, alterna na hora, `SnackBar` "Notícia salva"/"Removida dos salvos" (chaves `news_reels_*`); falha → marcador volta e `SnackBar` com o erro; rótulos "Salvar"/"Salvo"; visitante que entra pelo convite e volta → detalhe recarregado
- [X] T032 [P] [US3] Criar `tnews/presentation/pages/saved_news_page_test.dart`: com conta, cartões do feed (título, fonte, data) na ordem do serviço; chegar perto do fim carrega a próxima página sem repetir; tocar num cartão abre `/news/:id` e **ao voltar** chama `refresh` (a notícia removida some); lista vazia → "Você ainda não salvou nenhuma notícia." com a dica; cópia → `SafeOfflineBanner`; erro sem cópia → "Tentar novamente"; visitante → convite no lugar da lista e **nenhum** pedido; carregando com `SlowRequestNotice`
- [X] T033 [P] [US3] Criar `tnews/news_module_test.dart`: com `UserSessionService` e `FakeLocalCacheService`, gravar as duas cópias, mudar `sessionStatus` para `unauthenticated` (sair **ou** sessão expirada) → `clearAccountCopies` apaga detalhes e salvas e preserva `news_feed_cache_v1`; `guest` e `authenticated` não apagam. Criar também `tnews/presentation/routes/news_routes_test.dart`: `/news/saved` abre `SavedNewsPage` e **não** `NewsDetailPage` (R1), `/news/abc` abre o detalhe de `abc`

### Implementation for User Story 3

- [X] T034 [US3] Em `news/presentation/controller/news_detail_controller.dart`, implementar `toggleSave()` (padrão otimista do `ReelsController`, R6), `isSaving`, `NewsDetailMessage` (`saved`, `removed`, `saveFailed`, `notFound`) e o `Stream<NewsDetailMessage> messages` (broadcast, fechado no `dispose`), usando o `ToggleSaveUseCase` da 008. T029 verde
- [X] T035 [US3] Criar `news/presentation/controller/saved_news_controller.dart` (`status` reaproveitando `FeedStatus` — `loading`/`loaded`/`error`; **vazio = `loaded` com `items.isEmpty`**, o `FeedStatus` não tem `empty`; `items`, `page`, `hasMore`, `isLoadingMore`, `loadMoreFailure`, `isFromCache`; `load`, `loadMore`, `refresh`, `_requestId`). T030 verde
- [X] T036 [US3] Criar `news/presentation/widgets/news_detail_actions.dart` com o botão de salvar (`bookmark`, preenchido quando salvo; recebe `isSaved` já resolvido pela página: visitante → `false`; área ≥ 48 dp, rótulos "Salvar"/"Salvo") e, em `news_detail_page.dart`, ligar com `if (await requireAccount(context)) controller.toggleSave()`, escutar `controller.messages` e mostrar `SnackBar` (`news_reels_saved_toast`/`news_reels_removed_toast`/`failureKey.tr()`). T031 verde
- [X] T037 [US3] Criar `news/presentation/pages/saved_news_page.dart` (`AppBar` "Notícias salvas", `ListView` de `NewsCard` com `loadMore` perto do fim e rodapé reaproveitando `FeedListFooter`, `SafeOfflineBanner`, `SafeEmptyState`, `SafeErrorState`, `SlowRequestNotice`; `await context.push('/news/${id}')` seguido de `controller.refresh()`; visitante → convite no lugar da lista reaproveitando `common_account_required_title/body/action` com ação para `/login`, sem criar o controller com carga) e, em `news/presentation/routes/news_routes.dart`, declarar `/news/saved` **antes** de `/news/:id`, ambas com `parentNavigatorKey: rootNavigatorKey`, com `ChangeNotifierProvider<SavedNewsController>`. T032 e o teste de rota verdes
- [X] T038 [US3] Em `news/news_module.dart`, ouvir `UserSessionService.sessionStatus` e, ao ir para `unauthenticated`, chamar `clearAccountCopies()` do `NewsLocalDataSource` (R3, FR-018). T033 verde
- [X] T039 [P] [US3] Em `app/lib/dev/accessibility_playground.dart`, acrescentar o botão fixo "Notícias salvas" (R8) que faz `router.push('/news/saved')`, usando o `router` devolvido por `setupApp()` (o painel fica acima do `ClickSeguroApp`, sem contexto do `go_router`); texto fixo, como o resto do arquivo

**Checkpoint**: US1–US3 funcionando.

---

## Phase 6: User Story 4 - Compartilhar e abrir a fonte (Priority: P2)

**Goal**: "Compartilhar" pelo menu do aparelho e "Abrir fonte" no navegador externo, sem depender de conta.

**Independent Test**: tocar em "Compartilhar" e ver o menu com título e endereço; tocar em "Abrir fonte" e ver o navegador.

### Tests for User Story 4

- [X] T040 [P] [US4] Em `tnews/presentation/extensions/news_detail_presentation_extension_test.dart`, acrescentar `shareText`: título, fonte e endereço da fonte em linhas; sem endereço válido → só título e fonte
- [X] T041 [P] [US4] Em `tnews/presentation/pages/news_detail_page_test.dart` (grupo compartilhar e fonte), com `FakeShareService`/`FakeExternalLauncherService`: "Compartilhar" → `shareText` com `shareText` e `subject` (título); `ShareOutcome.cancelled` volta ao detalhe sem aviso; `failed` também não mostra aviso (a spec não define um); "Abrir fonte" → `openedUrls == ['https://fonte.test/n']` também para visitante; `openResult = false` → `SnackBar` "Não foi possível abrir a fonte" e continua no detalhe; sem `sourceUrl` válido → "Abrir fonte" ausente; texto vazio mantém "Abrir fonte"; toque duplo em cada um → uma ação só; rótulos e ≥ 48×48 dp

### Implementation for User Story 4

- [X] T042 [US4] Em `news/presentation/extensions/news_detail_presentation_extension.dart`, acrescentar `shareText` (FR-019). T040 verde
- [X] T043 [US4] Em `news/presentation/widgets/news_detail_actions.dart`, acrescentar "Compartilhar" (`share`) e "Abrir fonte" (`externalLink`, só com `hasSource`), com `Wrap` para quebrar linha com fonte 2×; em `news/presentation/pages/news_detail_page.dart`, chamar `GetIt.instance<ShareService>().shareText(text, subject: title)` e `GetIt.instance<ExternalLauncherService>().openUrl(...)` (aviso `news_reels_open_source_failed` em `false`; é decisão da página, como no `reels_page.dart`), protegidos contra toque duplo. T041 verde

**Checkpoint**: US1–US4 funcionando.

---

## Phase 7: User Story 5 - Seguir para uma atividade relacionada (Priority: P3)

**Goal**: bloco "Pratique o que aprendeu" depois do texto, só com `suggestedModule`, abrindo `/activities/<id>`.

**Independent Test**: como visitante, abrir uma notícia com módulo sugerido, ver o bloco e abrir `/activities/<id>`; abrir uma sem sugestão e não ver o bloco.

### Tests for User Story 5

- [X] T044 [P] [US5] Criar `tnews/presentation/widgets/related_activity_card_test.dart` e acrescentar em `tnews/presentation/pages/news_detail_page_test.dart` (grupo atividade): com `suggestedModule`, o bloco aparece **depois do texto** com título, descrição e "{} perguntas" (`lessonsCount`) para visitante e para conta; tocar → `/activities/m1` aberto por cima das abas e, ao voltar, o detalhe igual; toque duplo → uma navegação; sem `suggestedModule` → sem bloco e sem espaço vazio; `description` vazia não deixa buraco; rótulo e ≥ 48 dp

### Implementation for User Story 5

- [X] T045 [US5] Criar `news/presentation/widgets/related_activity_card.dart` (`SafeCard` com título, descrição, "{} perguntas" e ícone; `onTap` com guarda de toque duplo) e, em `news/presentation/pages/news_detail_page.dart`, mostrá-lo após o texto quando `detail.suggestedModule != null`, com `context.push('/activities/${module.id}')` (por caminho, **sem** importar `activities`, constituição I). T044 verde

**Checkpoint**: todas as histórias funcionando.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T046 [P] Em `tnews/presentation/pages/news_detail_page_test.dart` (grupo acessibilidade, FR-022, SC-008), ajustar o que falhar em `news_detail_page.dart`/widgets: todos os botões ≥ 48×48 dp; fonte do sistema 2× sem sobreposição e com botões quebrando de linha; ordem do `Semantics` título, fonte, data, ações, texto, bloco de atividade; tema de alto contraste da feature 009. Repetir o essencial em `saved_news_page_test.dart`
- [X] T047 [P] Em `.specify/memory/api-contract.md`, acrescentar à linha de `GET /users/me/news/saved` a ordem observada no passo 9 do quickstart (a pendência do [R0](research.md)) e atualizar a versão/data se mudar algo
- [X] T048 Formatar só os arquivos tocados (`dart format` em `news/`, `tnews/`, `app/lib/dev/accessibility_playground.dart`, `app_strings.dart`), depois `flutter analyze` (sem avisos novos) e `flutter test` (todos verdes). Revisar código morto e confirmar que `news/` não importa `activities`
- [X] T049 Validar no aparelho os passos 1–16 do [quickstart.md](quickstart.md) (SC-001, SC-003 e a ordem da lista de salvas só são conferidos aqui; usar conta de teste e desativá-la no fim). Guardar prints e relatório em `specs/010-detalhe-noticia/evidencias/` e anotar o resultado nesta tarefa
  - **Resultado (2026-10-09, emulador Pixel 4, servidor de desenvolvimento)**: passos 1–13, 15 e 16 conformes; passo 14 só em parte (o convite do visitante em "Notícias salvas" está conforme, mas o app ainda não tem saída da conta na interface, então a limpeza ao sair/FR-018 segue coberta só pelos testes automáticos). **Ordem da lista de salvas**: da salva mais recente para a mais antiga (conferida com 3 notícias; não é `publishedAt`), registrada no contrato 1.0.6 (T047). **SC-003** conforme (voz no mesmo quadro em que a notícia aparece). **SC-001** no limite: ~1,95 s com o app em uso, mas 3,1 a 5,1 s na primeira abertura depois de ~45 s parado (conexão fria). Nenhum defeito do app. Conta de teste `teste-a5-20261009183350@example.com`, desativada no fim. Prints e relatório em [evidencias/](evidencias/) ([relatório](evidencias/relatorio-de-teste.md)). Não marcada `[X]` por causa de SC-001 e do passo 14, a decidir pelo orquestrador
  - **Aceite (2026-10-09)**: SC-001 conforme (o critério pede serviço acordado; 3–5 s só na 1ª abertura com o Render parado). Passo 14 aceito em parte: a saída da conta pela interface chega na B7/B8, e a limpeza ao sair (FR-018) fica coberta pelos testes. Fora da spec: conta desativada recebe 403 `USER_INACTIVE` e as salvas mostram o erro genérico, sem encerrar a sessão; avaliar na B8.
- [X] T050 Em `.specify/memory/tasks.md`, marcar a A5 como `[x] **A5 Detalhe da notícia** … (specs/010-detalhe-noticia)`. Conferir que a rota `/news/saved` já consta no §2 de `.specify/memory/plan.md` (consta)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro.
- **Foundational (Phase 2)**: T002 ∥ T003; testes T004–T008 em paralelo; T009 ∥ T010; T011 depois de T009; T012 e T013 depois de T010/T011; T014 depois de T011–T013; T015 → T016.
- **US1 (Phase 3)**: depende da Phase 2. T017 ∥ T018 ∥ T019; T020 e T021 em paralelo; T022 → T023.
- **US2 (Phase 4)**: depende da US1 (controller e página). T024 ∥ T025; T026 → T027 → T028.
- **US3 (Phase 5)**: depende da US1; independe da US2 (mesmos arquivos de página/controller: fazer em sequência). T029–T033 em paralelo; T034 e T035 em paralelo; T036 depois de T034; T037 depois de T035; T038 depois de T037; T039 em paralelo.
- **US4 (Phase 6)**: depende da US1 e de `news_detail_actions.dart` (T036); independe de US2/US3 na lógica.
- **US5 (Phase 7)**: depende da US1; independe das demais.
- **Polish (Phase 8)**: depois de todas; T046 ∥ T047.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Controller → extension → widgets → página.
- Commit ao fim de cada fase (Base, US1, US2, US3, US4, US5, Polish).

### Parallel Opportunities

- **Phase 2:** T002 ∥ T003; T004 ∥ T005 ∥ T006 ∥ T007 ∥ T008; T009 ∥ T010.
- **US1:** T017 ∥ T018 ∥ T019; T020 ∥ T021.
- **US2:** T024 ∥ T025. **US3:** T029 ∥ T030 ∥ T031 ∥ T032 ∥ T033; T034 ∥ T035; T039.
- **US4:** T040 ∥ T041. **Polish:** T046 ∥ T047.

---

## Parallel Example: Phase 2 (testes)

```bash
Task: "Teste do model em click_seguro_app/test/modules/news/data/models/news_detail_model_test.dart"
Task: "Teste do datasource remoto em click_seguro_app/test/modules/news/data/datasources/news_remote_data_source_impl_test.dart"
Task: "Teste do datasource local em click_seguro_app/test/modules/news/data/datasources/news_local_data_source_impl_test.dart"
Task: "Teste do repository em click_seguro_app/test/modules/news/data/repositories/news_repository_impl_test.dart"
Task: "Teste do domínio em click_seguro_app/test/modules/news/domain/news_domain_test.dart"
```

## Parallel Example: User Story 3

```bash
Task: "Teste do controller do detalhe (salvar) em click_seguro_app/test/modules/news/presentation/controller/news_detail_controller_test.dart"
Task: "Teste do SavedNewsController em click_seguro_app/test/modules/news/presentation/controller/saved_news_controller_test.dart"
Task: "Teste da tela de salvas em click_seguro_app/test/modules/news/presentation/pages/saved_news_page_test.dart"
Task: "Teste do módulo e da rota em click_seguro_app/test/modules/news/news_module_test.dart"
```

---

## Cobertura (spec → tarefas)

- **US1 / FR-001 a FR-004**: T004, T010 (parse), T017–T023 (carga, estados, leitura sem esperar, visitante sem pedido).
- **US2 / FR-005 a FR-010**: T024–T028.
- **US3 / FR-011 a FR-018**: T006, T013, T029–T039 (otimista, convite, lista, cópia offline, vazio, visitante, limpeza ao sair); FR-016 em T006/T007/T014.
- **US4 / FR-019, FR-020**: T040–T043.
- **US5 / FR-021**: T044, T045.
- **FR-022, FR-023**: T003 (i18n), T046 (48 dp, rótulos, alto contraste, fonte 2×).

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): detalhe completo com estados e registro de leitura.
3. **PARAR e VALIDAR**: `flutter test` verde e os passos 1 e 3 do quickstart.

### Incremental Delivery

1. Base → dados e domínio.
2. US1 → detalhe (MVP).
3. US2 → ouvir.
4. US3 → salvar e lista de salvas.
5. US4 → compartilhar e abrir a fonte.
6. US5 → atividade relacionada.
7. Polish → acessibilidade, contrato, aparelho e marcar a A5.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- Verifique que o teste falha antes de implementar.
- A Trilha A é da Amanda: combinar antes de abrir o PR para a `develop` (A5 também mexe em `news`). As PRs #12 (008) e #13 (009) entram antes desta.
- Curtir fica **fora** do detalhe (só mostra a contagem); o atalho do Perfil para as salvas é da B7; a tela da atividade é da B2.
