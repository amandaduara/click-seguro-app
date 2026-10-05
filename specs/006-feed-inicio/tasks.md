---

description: "Task list for feature 006: feed da aba Início (A3)"
---

# Tasks: Feed da aba Início

**Input**: Design documents from `/specs/006-feed-inicio/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/news-feed.md](contracts/news-feed.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): todo teste é escrito e **falha** antes da
implementação. Offline, com fakes à mão: `FakeHttpClientAdapter`
(`click_seguro_app/test/modules/common/api_client/fake_http_client_adapter.dart`),
`FakeLocalCacheService` (`click_seguro_app/test/fakes/`) e `FakeNewsRepository` (novo). Datas
com `now` injetado; espera da busca com o relógio falso do `testWidgets` (sem esperas reais).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `news/` =
  `click_seguro_app/lib/modules/news/`; `tnews/` = `click_seguro_app/test/modules/news/`.
- Formatos JSON reais em [research R0](research.md) e no [data-model](data-model.md); pedidos e
  fim de lista em [contracts/news-feed.md](contracts/news-feed.md).
- Notícias fictícias nos testes (`n1`, `n2`…; categorias `phishing`/"Phishing",
  `golpes-bancarios`/"Golpes bancários").

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (esperado: 327 testes verdes, 0 erros, 0 warnings, 28 infos). Se algo estiver vermelho, parar e reportar

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, fixtures e as camadas `domain/` e `data/` do módulo `news`, usadas por todas as histórias.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Base de teste e textos

- [X] T002 [P] Criar `tnews/fakes/news_fixtures.dart` com funções que montam JSON no formato real do servidor ([R0](research.md)): `newsItemJson({required String id, String title = 'Golpe do Pix', DateTime? originalPublishedAt, List<Map<String, dynamic>> categories = const [phishingJson], String? imageUrl = 'https://img.test/n.jpg', bool isRead = false, bool isSaved = false})` (sempre com `source`, `sourceUrl`, `publishedAt`, `createdAt`, `isHighlight` e `interaction`), `reelItemJson(...)` (o mesmo + `content`, `likesCount`), `feedJson({highlights, recommended, recent, String? nextCursor})`, `reelsJson({items, nextCursor})`, `newsListJson({items, page, hasNextPage})` (com o `meta` completo) e `categoriesJson` (uma ativa `phishing`, uma ativa `golpes-bancarios`, uma com `isActive: false`)
- [X] T003 [P] Acrescentar as chaves do bloco `// --- news ---` listadas em "Chaves de i18n novas" do [data-model](data-model.md#chaves-de-i18n-novas-bloco-news) em `app/lib/core/i18n/app_strings.dart` (dentro do bloco `news`) e nos dois JSONs de `app/assets/translations/` (junto das outras `news_*`), com en-US equivalente; mais `news_slow_server` ("Conectando ao servidor. Isso pode levar até um minuto."); meses curtos pt-BR: "jan.", "fev.", "mar.", "abr.", "mai.", "jun.", "jul.", "ago.", "set.", "out.", "nov.", "dez.". O teste `app/test/modules/shell/i18n_keys_test.dart` já cobre o prefixo `news_`

### Testes (escrever primeiro e ver falhar)

- [X] T004 [P] Criar `tnews/data/models/news_models_test.dart`: `NewsItemModel.fromJson` com o JSON da fixture → entidade com todos os campos do data-model; `imageUrl` vazio ou ausente → `null`; `categories` ausente → `[]`; `interaction` ausente → tudo `false`; `isHighlight` ausente → `false`; sem `id`/`title`/`originalPublishedAt` → lança; `toJson()` → `fromJson` devolve item igual (ida e volta, para a cópia guardada); `NewsCategoryModel` e `NewsListModel` (`hasMore` = `meta.hasNextPage`); `NewsFeedModel.fromJson(feed, reels)`: `recent.hasMore` é `false` quando `nextCursor == null` **ou** quando vieram menos de 20 itens, e `true` com 20 itens e `nextCursor` preenchido
- [X] T005 [P] Criar `tnews/data/datasources/news_remote_data_source_impl_test.dart` com `ApiClient(dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter)` e `GetIt` com `UserSessionService(FakeSecureStorageService())`:
  - `getFeed(page: 2)` → `GET /app/news/feed` com `page=2&limit=20` e **sem** `cursor`;
  - `getReels()` → `GET /app/news/reels?limit=10`;
  - `getNews(page: 1, category: 'phishing', search: 'pix')` → `GET /app/news` com `page=1&limit=20&category=phishing&search=pix&sortBy=publishedAt&sortOrder=desc`; sem categoria/busca, esses parâmetros não vão;
  - `getCategories()` → `GET /categories`, devolve só as ativas;
  - visitante: sem cabeçalho `Authorization`; conectado (`saveSession`): com `Bearer`;
  - uma `getNews` em andamento é cancelada quando outra começa (a 1ª termina com `ApiException(type: cancelled)`; use `FakeResponse` com `delay`);
  - 500 → `ApiException(server)`; corpo inválido → `ApiException(invalidResponse)`
- [X] T006 [P] Criar `tnews/data/datasources/news_local_data_source_impl_test.dart` com `FakeLocalCacheService`: `writeFeed(feedJson, reelsJson)` grava em `news_feed_cache_v1` com `savedAt` (relógio injetado); `readFeed()` devolve os dois JSON e o `savedAt`; nada guardado, JSON sem `feed` ou ilegível → `null`
- [X] T007 [P] Criar `tnews/data/repositories/news_repository_impl_test.dart` com fakes dos dois datasources:
  - `getFeedFirstPage()` ok → `Right` com destaques, recomendados, recentes e Reels, `isFromCache == false`, e grava a cópia;
  - Reels falham e o feed não → `Right` com `reels == []` (e a cópia guarda Reels vazios);
  - feed falha com `ApiException(connection)` e há cópia → `Right` da cópia com `isFromCache == true`; o mesmo com `server`;
  - feed falha com `connection` sem cópia → `Left(ConnectionFailure())`; com `unauthorized` → `Left(UnauthorizedFailure())` **sem** usar a cópia;
  - `getFeedPage(3)` → página 3 sem destaques; erro → `Left` pelo `toFailure()`;
  - `getNews(NewsFilter(categorySlug: 'phishing', search: 'pix'), 2)` repassa os parâmetros; com `search: 'p'` (menos de 2) **não** envia `search`;
  - `getCategories()` ok e erro → `Left`
- [X] T008 [P] Criar `tnews/domain/news_domain_test.dart`: `NewsFilter` (`search` com `trim`; `hasSearch` só com 2+ caracteres; `isEmpty` sem categoria e sem busca útil; igualdade por valor); `List<NewsItemEntity>.appendUnique(page)` acrescenta só itens de `id` novo, na ordem, e informa quantos entraram; e os quatro usecases repassando ao `FakeNewsRepository`

### Implementação

- [X] T009 Criar em `news/domain/entities/`: `news_category_entity.dart`, `news_item_entity.dart` (com `NewsInteraction`), `news_page_entity.dart` (com a extension `NewsItemsMerge` e o método `appendUnique` que devolve `(List<NewsItemEntity> items, int added)`), `news_feed_entity.dart` e `news_filter.dart` (`const int minSearchLength = 2`), conforme o [data-model](data-model.md). Faz a parte de domínio da T008 passar
- [X] T010 Criar `news/domain/repositories/news_repository.dart` (contrato da [contracts/news-feed.md](contracts/news-feed.md)) e os usecases `news/domain/usecases/get_feed_usecase.dart`, `get_feed_page_usecase.dart`, `get_news_usecase.dart` e `get_categories_usecase.dart`; criar `tnews/fakes/fake_news_repository.dart` (respostas configuráveis por método, `Completer` opcional para segurar respostas, contadores de chamadas e últimos argumentos). Faz a T008 passar
- [X] T011 Criar os models em `news/data/models/`: `news_item_model.dart` (`fromJson`, `toJson`, `toEntity`), `news_category_model.dart`, `news_list_model.dart` e `news_feed_model.dart` (`static const int pageSize = 20`; `hasMore` do feed = `nextCursor != null && recent.length >= pageSize`). Faz a T004 passar
- [X] T012 Criar `news/data/datasources/news_remote_data_source.dart` e `_impl.dart` (caminhos em constantes `feedPath`, `reelsPath`, `newsPath`, `categoriesPath`; `reelsPreviewLimit = 10`; um `CancelToken? _listToken` cancelado no início de cada `getNews`). `getFeed`/`getReels` devolvem o `Map` cru (para a cópia). Faz a T005 passar
- [X] T013 [P] Criar `news/data/datasources/news_local_data_source.dart` e `_impl.dart` sobre o `LocalCacheService` (`static const String feedCacheKey = 'news_feed_cache_v1'`; `DateTime Function() now` opcional), com `CachedFeed { feedJson, reelsJson, savedAt }`. Faz a T006 passar
- [X] T014 Criar `news/data/repositories/news_repository_impl.dart` ([R1](research.md), [R4](research.md)): 1ª página = `Future.wait` de feed e Reels (Reels com falha → `[]`), grava a cópia no sucesso; em `ApiException` de tipo `connection`, `timeout` ou `server` tenta a cópia; demais → `toFailure()`. Nunca lança. Faz a T007 passar
- [X] T015 Em `news/news_module.dart`, registrar em `registerServices`: `NewsRemoteDataSource`, `NewsLocalDataSource`, `NewsRepository` (por tipo abstrato) e os quatro usecases. Rodar `flutter test test/modules/news`

**Checkpoint**: camadas `data/` e `domain/` verdes.

---

## Phase 3: User Story 1 - Ver as notícias mais recentes (Priority: P1) 🎯 MVP

**Goal**: feed completo sem filtro: barra superior com saudação e contagem, carrossel, destaques, recomendados, "Tudo recente" paginado sem repetir, atualizar, abrir detalhe e Reels (FR-001 a FR-011, FR-023 a FR-025).

**Independent Test**: passos 1–4, 7 e 11 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T016 [P] [US1] Criar `tnews/presentation/extensions/news_presentation_extension_test.dart` com `pumpLocalized` (para os textos) e `now` fixo em `2026-10-05 15:00` local: data de hoje → "Hoje"; ontem às 23:59 → "Ontem"; há 2 e 6 dias → "Há 2 dias"/"Há 6 dias"; há 7 dias → "28 de set."; categorias: 0 → lista vazia, 2 → os dois nomes, 4 → dois nomes e "+2"; rótulo acessível "título, fonte, data, categorias" (sem categoria, sem a última parte); `newCount`: junta Reels, destaques, recomendados e recentes, ignora `id` repetido e conta só `originalPublishedAt` nas últimas 24 h
- [X] T017 [P] [US1] Criar `tnews/presentation/controller/feed_controller_test.dart` (grupo `feed`) com `FakeNewsRepository` e `now` fixo:
  - `load()`: `status` loading → loaded; destaques, recomendados, Reels e `items` preenchidos; `hasMore` do repositório; `newCount` calculado;
  - falha sem cópia → `status == error` e `failure`; `load()` de novo → sucesso;
  - `loadMore()` pede a página 2, acrescenta só itens novos; página que não acrescenta nada → `hasMore == false` e não pede mais; com `hasMore == false`, `loadMore()` não chama o repositório;
  - `loadMore()` chamado duas vezes seguidas faz **um** pedido;
  - falha no `loadMore()` → mantém `items`, `loadMoreFailure` preenchido; nova chamada tenta de novo e limpa a falha;
  - `refresh()` volta à página 1 e substitui a lista;
  - saudação: o controller não sabe o nome (vem do `AppTopBar`); só expõe `newCount`;
  - `newCount` aumenta quando uma página nova do feed traz notícias das últimas 24 h; com `selectCategory`/busca ativa, `newCount` não muda (mantém o do feed);
  - carga inicial que falha com `UnauthorizedFailure` e depois tem sucesso → o controller tenta de novo **uma vez**, sem a pessoa tocar em nada, e termina `loaded`; se a segunda tentativa também falhar, `status == error`
- [X] T018 [P] [US1] Criar `tnews/presentation/widgets/news_card_test.dart`: compacto mostra título, fonte, data relativa e até 2 categorias + "+N"; sem categoria não mostra rótulo; sem `imageUrl` mostra o quadro neutro; com `isRead`/`isSaved` mostra "Lida"/"Salva" (semântica), sem eles não; completo mostra imagem grande; tocar chama `onTap` uma vez mesmo com dois toques rápidos; área de toque ≥ 48 de altura; rótulo semântico do cartão igual ao da extension; fonte em 200% sem exceção
- [X] T019 [P] [US1] Criar `tnews/presentation/pages/news_home_page_test.dart` (grupo `feed`) com `FeedController` real sobre `FakeNewsRepository`, `GetIt` com `UserSessionService`, `pumpLocalized(router:)` e rotas `/home` (página), `/news/:id` e `/reels` identificadas:
  - carregando → `SafeLoadingState`;
  - carregado → na ordem: "Notícias seguras", busca, filtros, "Novidades", "Destaques", "Tudo recente"; "Recomendadas para você" só quando a lista vier preenchida;
  - subtítulo: visitante sem novas → "Bem-vindo!"; visitante com 3 novas → "Bem-vindo! 3 notícias novas para você"; conectada "Maria" com 1 nova → "Olá, Maria! 1 notícia nova para você";
  - tocar num cartão de "Tudo recente" → `/news/<id>`; tocar num cartão das Novidades → `/reels?start=<id>`;
  - rolar até o fim → pede a página 2 e mostra os novos cartões; no fim de verdade, "Você viu todas as notícias"; com falha, "Não foi possível carregar mais." e "Tentar novamente";
  - erro sem cópia → `SafeErrorState` com a mensagem da `Failure`; "Tentar novamente" recarrega;
  - puxar para atualizar (`tester.fling` para baixo + `pumpAndSettle`) → nova chamada de `getFeedFirstPage`;
  - Reels vazios → sem a seção "Novidades";
  - com uma categoria selecionada, abrir um cartão (`/news/<id>`) e voltar (`router.pop()`) → a mesma categoria continua selecionada e os mesmos cartões aparecem, sem novo `getNews` (este caso entra junto com a US2, quando os filtros existirem);
  - carga segurada por `Completer`: depois de `tester.pump(Duration(seconds: 5))`, aparece "Conectando ao servidor. Isso pode levar até um minuto."

### Implementação

- [X] T020 [US1] Criar `news/presentation/extensions/news_presentation_extension.dart` ([R7](research.md)): `relativeDate(DateTime now)`, `categoryLabels({int max = 2})` (nomes + "+N"), `semanticLabel(DateTime now)`, e em `NewsFeedEntity`/listas o `newCount(DateTime now)` ([R6](research.md)). Faz a T016 passar
- [X] T021 [US1] Criar `news/presentation/controller/feed_status.dart` (`enum FeedStatus { loading, loaded, error }`) e `news/presentation/controller/feed_controller.dart` com o estado do [data-model](data-model.md#estado-do-feedcontroller), recebendo os quatro usecases e `DateTime Function() now` (padrão `DateTime.now`); `load()`, `refresh()` e `loadMore()` (guarda `_loadingMore` para não duplicar; usa `appendUnique`; `added == 0` → `hasMore = false`); `_requestId` incrementado a cada carga inicial, descartando respostas antigas ([R3](research.md)); `newCount` recalculado em `load()`, `refresh()` e `loadMore()` do feed sem filtro e inalterado nas consultas com filtro; na carga inicial, `Left(UnauthorizedFailure())` dispara uma segunda tentativa automática, uma vez só (a sessão já foi encerrada pelo `ApiClient`, então o pedido sai sem token). Faz a T017 passar
- [X] T022 [P] [US1] Criar `news/presentation/widgets/news_card.dart` (`NewsCard({required NewsItemEntity item, required VoidCallback onTap, bool compact = true, required DateTime now})`) conforme o [design system §7.8](../../.specify/memory/design-system.md) (sem botões de curtir/salvar; sinais "Lida"/"Salva" só quando verdadeiros; imagem com `Image.network` + `errorBuilder`/quadro neutro, [R8](research.md); `Semantics(button: true, label: item.semanticLabel(now), excludeSemantics: true)`; ignora toques enquanto `_opening`). Faz a T018 passar
- [X] T023 [P] [US1] Criar `news/presentation/widgets/reels_carousel.dart` ([design system §7.9](../../.specify/memory/design-system.md): proporção 9:16, largura 160, gradiente, selo "Reels", título 3 linhas, fonte; sem imagem → fundo `secondary`) e `news/presentation/widgets/feed_section.dart` (título de seção 18/700 `secondary` + filhos) e `news/presentation/widgets/feed_list_footer.dart` (carregando mais / fim / falha com "Tentar novamente" / fim offline)
- [X] T024 [US1] Reescrever `news/presentation/pages/news_home_page.dart` como o feed: `AppTopBar(title: news_title, subtitle: ...)` (subtítulo: `news_greeting_named` com o nome da sessão ou `news_greeting_guest`, mais `news_new_count`/`news_new_count_one` quando `newCount > 0`, lendo a sessão por `GetIt` como o `AppTopBar` faz); corpo em `RefreshIndicator` + `CustomScrollView` com slivers: busca e filtros (na US1, a barra de filtros mostra só "Todas" e o campo de busca fica oculto; as US2/US3 os ativam), "Novidades" (se houver Reels), "Destaques" (cartões completos), "Recomendadas para você" (se houver), "Tudo recente" (cartões compactos) e o rodapé; `loadMore()` quando faltar menos de 600 px para o fim; estados `SafeLoadingState` (com `SlowRequestNotice(active: true, message: news_slow_server)` abaixo) e `SafeErrorState` (`failure.message.tr()`); navegação conforme [R10](research.md). Faz a T019 passar
- [X] T025 [US1] Em `news/news_module.dart`, `providers` com `ChangeNotifierProvider(create: (_) => FeedController(...)..load())`, para o estado sobreviver a trocas de aba ([R10](research.md)). Em `app/test/widget_test.dart`, depois do `registerModules(appModules())` e antes de montar o app, registrar `GetIt.instance.registerSingleton<NewsRepository>(FakeNewsRepository())` (o `allowReassignment` já está ligado no teste), para que o Início carregue sem rede (constituição, Seção III). Rodar `flutter test` inteiro
- [X] T026 [US1] Criar `app/test/helpers/feed_provider.dart` no padrão do `splash_provider.dart`: `SingleChildWidget fakeFeedProvider([FakeNewsRepository? repository])` com `ChangeNotifierProvider(create: (_) => FeedController(<usecases sobre o FakeNewsRepository>, now: () => DateTime(2026, 10, 5, 15))..load())`, e o `FakeNewsRepository` padrão devolvendo um feed com 2 notícias. Acrescentar `fakeFeedProvider()` aos `providers` de `app/test/core/routing/app_router_test.dart`, `app/test/modules/shell/presentation/app_shell_test.dart` e `app/test/modules/shell/presentation/session_expired_listener_test.dart`. Rodar os três e confirmar que continuam verdes

**Checkpoint**: feed sem filtro completo nos testes e no aparelho.

---

## Phase 4: User Story 2 - Filtrar por categoria (Priority: P1)

**Goal**: "Todas" + categorias ativas; lista por categoria paginada; seções ocultas; vazio próprio; respostas antigas descartadas (FR-012 a FR-015).

**Independent Test**: passo 5 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T027 [P] [US2] Em `tnews/presentation/controller/feed_controller_test.dart`, grupo `categoria`: `load()` também carrega as categorias; falha nelas → `categories == []` sem afetar o feed; `selectCategory('phishing')` → `status` loading → loaded com `getNews(filter(categorySlug: 'phishing'), 1)`, sem Reels/destaques/recomendados; `loadMore()` pede a página 2 da mesma categoria; `selectCategory(null)` volta ao feed (`getFeedFirstPage`); duas trocas rápidas com o 1º pedido segurado por `Completer` → o resultado final é o da 2ª escolha, mesmo que o 1º responda depois; selecionar a categoria já ativa não faz pedido
- [ ] T028 [P] [US2] Criar `tnews/presentation/widgets/category_filter_bar_test.dart`: mostra "Todas" e os nomes; o selecionado tem `Semantics(selected: true)` e fundo `secondary`; tocar chama `onSelected(slug)` (e `null` para "Todas"); cada chip mede ≥ 48 de altura; rola na horizontal

### Implementação

- [ ] T029 [US2] No `FeedController`: carregar categorias em paralelo no `load()`; `selectCategory(String? slug)` troca o `NewsFilter`, zera a lista e carrega pela rota certa ([R2](research.md)); `loadMore()` usa `getNews` quando o filtro não é vazio. Faz a T027 passar
- [ ] T030 [P] [US2] Criar `news/presentation/widgets/category_filter_bar.dart` ([design system §7.6](../../.specify/memory/design-system.md)): `CategoryFilterBar({required List<NewsCategoryEntity> categories, required String? selectedSlug, required ValueChanged<String?> onSelected})`, chips 16×8 com área mínima de 48, rolagem horizontal sem barra. Faz a T028 passar
- [ ] T031 [US2] Na `NewsHomePage`: barra real ligada ao controller; com filtro, só a lista (sem "Novidades"/"Destaques"/"Recomendadas") e título "Tudo recente"; lista vazia com categoria → `SafeEmptyState(message: news_empty_category)`. Acrescentar ao `news_home_page_test.dart` (grupo `categoria`): tocar numa categoria mostra só a lista dela; vazia mostra a mensagem; "Todas" volta às seções

**Checkpoint**: filtros funcionando, independentes da busca.

---

## Phase 5: User Story 3 - Buscar uma notícia (Priority: P2)

**Goal**: busca com espera de 500 ms, mínimo de 2 caracteres, cancelamento e respostas antigas descartadas, dentro da categoria, com estado vazio e "X" (FR-016 a FR-019).

**Independent Test**: passo 6 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T032 [P] [US3] Em `tnews/presentation/controller/feed_controller_test.dart`, grupo `busca` (com `testWidgets` e relógio falso): digitar "p", "pi", "pix" em menos de 500 ms → **um** `getNews` com `search: 'pix'`, só depois de `tester.pump(Duration(milliseconds: 500))`; "p" sozinho não busca; busca com categoria ativa envia os dois; respostas fora de ordem (1ª segurada por `Completer`) → vale a última; `clearSearch()` volta à lista sem busca (feed ou categoria) imediatamente; `loadMore()` em resultados pede a página seguinte com o mesmo texto; o título da seção vira "Resultados" (`isSearching == true`)
- [ ] T033 [P] [US3] Criar `tnews/presentation/widgets/feed_search_field_test.dart`: placeholder "Buscar notícia ou tipo de golpe"; digitar chama `onChanged`; o "X" só aparece com texto, tem rótulo "Limpar busca", mede ≥ 48×48 e limpa o campo chamando `onCleared`

### Implementação

- [ ] T034 [US3] No `FeedController`: `onSearchChanged(String text)` com `Timer` de 500 ms (`static const Duration searchDebounce`), atualiza o `NewsFilter` e carrega quando `hasSearch` (ou volta à lista sem busca quando o texto fica curto); `clearSearch()`; `isSearching`; cancelar o `Timer` no `dispose()`. Faz a T032 passar
- [ ] T035 [P] [US3] Criar `news/presentation/widgets/feed_search_field.dart` ([design system §7.4](../../.specify/memory/design-system.md)), usando o `SafeTextField` se ele aceitar o visual de busca; senão, campo próprio com raio `full`, fundo `muted` 40% e ícone `search`. Faz a T033 passar
- [ ] T036 [US3] Na `NewsHomePage`: campo real ligado ao controller; resultados vazios → `SafeEmptyState(message: news_empty_search.tr(args: [texto]))`. Acrescentar ao `news_home_page_test.dart` (grupo `busca`): digitar e esperar 500 ms mostra "Resultados"; sem resultado mostra a mensagem com o texto; "X" volta ao feed

**Checkpoint**: busca e filtros combinados.

---

## Phase 6: User Story 4 - Ler o feed sem internet (Priority: P2)

**Goal**: abrir da cópia guardada com a faixa de aviso, sem paginar; erro sem cópia; filtro/busca offline com erro (FR-020 a FR-022).

**Independent Test**: passos 8 e 9 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T037 [P] [US4] Em `tnews/presentation/controller/feed_controller_test.dart`, grupo `sem internet`: `getFeedFirstPage` devolvendo feed com `isFromCache: true` → `isFromCache == true` e `hasMore == false` (não pagina, mesmo que a cópia diga `hasMore`); `refresh()` com sucesso → `isFromCache == false`; categoria sem internet (`getNews` → `Left(ConnectionFailure())`) → `status == error`; `selectCategory(null)` depois → tenta o feed (e a cópia)
- [ ] T038 [P] [US4] Em `tnews/presentation/pages/news_home_page_test.dart`, grupo `sem internet`: feed da cópia → `SafeOfflineBanner` no topo e, no fim da lista, "Conecte-se à internet para ver mais notícias."; erro de conexão sem cópia → "Sem conexão com a internet. Verifique sua rede." e "Tentar novamente"; atualizar com sucesso → a faixa some

### Implementação

- [ ] T039 [US4] No `FeedController`: `isFromCache` vindo do `NewsFeedEntity`; com ele, `hasMore = false` e `offlineEnd = true` para o rodapé. Faz a T037 passar
- [ ] T040 [US4] Na `NewsHomePage`: `SafeOfflineBanner` como primeiro sliver quando `isFromCache`; rodapé com `news_offline_end`. Faz a T038 passar

**Checkpoint**: as quatro histórias verdes.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T041 Formatar só os arquivos tocados (`dart format` em `news/`, `tnews/`, `app_strings.dart`), depois `flutter analyze` (sem avisos novos além dos 28 infos) e `flutter test` (todos verdes). Revisar código morto ou só para testes antes do commit
- [ ] T042 Validar no aparelho os 11 passos do [quickstart.md](quickstart.md). Anotar o resultado no fim desta tarefa. O SC-001 (até 3 s com o servidor acordado) só é conferido aqui
- [ ] T043 Em `.specify/memory/tasks.md`, marcar a A3 como `[x] **A3 Feed (Início)** … (specs/006-feed-inicio)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro.
- **Foundational (Phase 2)**: T002 e T003 em paralelo; testes T004–T008 em paralelo; T009 → T010 → (T011, T013 em paralelo) → T012 → T014 → T015.
- **US1 (Phase 3)**: depende da Phase 2. Testes T016–T019 em paralelo; T020 → T021; T022 e T023 em paralelo; T024 depois de T021–T023; T025 e depois T026 por último.
- **US2 (Phase 4)**: depende da US1 (controller e página).
- **US3 (Phase 5)**: depende da US1; independe da US2, mas a busca dentro da categoria (T032) usa o filtro da US2 — fazer depois da US2 é mais simples.
- **US4 (Phase 6)**: depende da US1 (a cópia em si já vem da Phase 2).
- **Polish (Phase 7)**: depois de todas.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Extension → controller → widgets → página.
- Commit ao fim de cada história (Base + US1, US2, US3, US4).

### Parallel Opportunities

- **Phase 2:** T002 ∥ T003; T004 ∥ T005 ∥ T006 ∥ T007 ∥ T008; T011 ∥ T013.
- **US1:** T016 ∥ T017 ∥ T018 ∥ T019; T022 ∥ T023.
- **US2:** T027 ∥ T028; T030 ∥ T029.
- **US3:** T032 ∥ T033; T035 ∥ T034.
- **US4:** T037 ∥ T038.

---

## Parallel Example: Phase 2 (testes)

```bash
Task: "Testes dos models em click_seguro_app/test/modules/news/data/models/news_models_test.dart"
Task: "Teste do datasource remoto em click_seguro_app/test/modules/news/data/datasources/news_remote_data_source_impl_test.dart"
Task: "Teste do datasource local em click_seguro_app/test/modules/news/data/datasources/news_local_data_source_impl_test.dart"
Task: "Teste do repository em click_seguro_app/test/modules/news/data/repositories/news_repository_impl_test.dart"
Task: "Teste do domínio e usecases em click_seguro_app/test/modules/news/domain/news_domain_test.dart"
```

## Parallel Example: User Story 1

```bash
Task: "Teste da extension em click_seguro_app/test/modules/news/presentation/extensions/news_presentation_extension_test.dart"
Task: "Teste do controller (feed) em click_seguro_app/test/modules/news/presentation/controller/feed_controller_test.dart"
Task: "Teste do cartão em click_seguro_app/test/modules/news/presentation/widgets/news_card_test.dart"
Task: "Teste da página (feed) em click_seguro_app/test/modules/news/presentation/pages/news_home_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): feed sem filtro completo.
3. **PARAR e VALIDAR**: `flutter test` verde e os passos 1–4, 7 e 11 do quickstart.

### Incremental Delivery

1. Base → dados e domínio.
2. US1 → feed (MVP).
3. US2 → filtros.
4. US3 → busca.
5. US4 → sem internet na UI.
6. Polish → aparelho e marcar a A3.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- Verifique que o teste falha antes de implementar.
- Testes que dependem de tempo usam o relógio falso (`tester.pump(Duration)`) ou `now` injetado,
  nunca esperas reais.
- Não usar o `cursor` do feed ([R1](research.md)).
- Não mexer em `main.dart`, `app_router.dart`, `common/` nem `shell/` (fechados desde a 005).
- O `dart format` em pastas inteiras reformata arquivos fora do escopo: formate só os arquivos
  tocados pela tarefa.
