---

description: "Task list for feature 008: Reels com curtir, salvar e abrir a fonte (A4)"
---

# Tasks: Reels com curtir, salvar e abrir a fonte

**Input**: Design documents from `/specs/008-reels-curtir-salvar/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/reels.md](contracts/reels.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): todo teste é escrito e **falha** antes da
implementação. Offline, com fakes à mão: `FakeHttpClientAdapter`
(`click_seguro_app/test/modules/common/api_client/fake_http_client_adapter.dart`),
`FakeNewsRemoteDataSource`/`FakeNewsRepository` (`tnews/fakes/`, ganham reels/like/save),
`FakeExternalLauncherService` e `FakeSecureStorageService` (`click_seguro_app/test/fakes/`).
`Completer` para segurar respostas (estado otimista, toques repetidos).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `news/` =
  `click_seguro_app/lib/modules/news/`; `tnews/` = `click_seguro_app/test/modules/news/`.
- Formato JSON real em [research R0](research.md) e em [contracts/reels.md](contracts/reels.md).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (0 erros, 0 warnings). Se algo estiver vermelho, parar e reportar

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, fixtures e as camadas `domain/` e `data/` dos Reels, usadas por todas as histórias.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Base de teste e textos

- [X] T002 [P] Em `tnews/fakes/news_fixtures.dart`, ajustar `reelItemJson({required String id, String? imageUrl, int likesCount = 3, bool isSaved = false, String? content})` ao formato real (R0): `interaction` só com `{isSaved}` (sem `isLiked`), `likesCount` e `content`; acrescentar `likeJson({bool liked = true, int likesCount = 4})` e `saveJson({bool saved = true})`. Conferir que os testes do feed continuam verdes
- [X] T003 [P] Acrescentar as chaves de i18n do [data-model](data-model.md#i18n-appstrings--pt-brjsonen-usjson-bloco-news) em `app/lib/core/i18n/app_strings.dart` (bloco `// --- news ---`) e nos dois JSONs de `app/assets/translations/`. pt-BR: "Notícia anterior", "Próxima notícia", "Curtir", "Curtido", "{} curtidas", "Salvar", "Salvo", "Notícia salva", "Removida dos salvos", "Abrir fonte", "Não foi possível abrir a fonte", "Ler notícia completa", "Nenhuma notícia por aqui ainda.", "Atualizar", "Você viu todas as notícias", "Não foi possível carregar mais", "Notícia não encontrada", "{} mil"; en-US equivalente. `app/test/modules/shell/i18n_keys_test.dart` cobre o prefixo `news_`

### Testes (escrever primeiro e ver falhar)

- [X] T004 [P] Criar `tnews/data/models/reel_models_test.dart`: `ReelModel.fromJson(reelItemJson(...))` → `ReelEntity` com `news` completo, `content`, `likesCount` (`num` → `int`), `isSaved` de `interaction.isSaved`, `isLiked == false`; `content` ausente → `''`; `likesCount` ausente → 0; `interaction` ausente → `isSaved == false`; `ReelsPageModel.fromJson` mantém a ordem, lê `nextCursor` (`null` → `hasMore == false`) e **descarta** item sem `id`/`title`/`originalPublishedAt` mantendo os demais; `data` ausente → lança; `LikeResultModel.fromJson({'liked': true, 'likesCount': 42})`
- [X] T005 [P] Em `tnews/data/datasources/news_remote_data_source_impl_test.dart`, acrescentar: `getReelsPage()` → `GET /app/news/reels?limit=10` sem `cursor`; `getReelsPage(cursor: 'abc')` → `cursor=abc&limit=10`; `toggleLike('n1')` → `POST /app/news/n1/like` com `Bearer` e devolve `LikeResultModel`; `toggleSave('n1')` → `POST /app/news/n1/save` → `true`/`false` do `saved`; corpo sem `saved` → `ApiException(invalidResponse)`
- [X] T006 [P] Em `tnews/data/repositories/news_repository_impl_test.dart`, acrescentar: `getReels()` → `Right(ReelsPageEntity)`; erro de conexão → `Left(ConnectionFailure)`; `toggleLike`/`toggleSave` sucesso → `Right`; 404 (`statusCode: 404`) ou `errorCode: 'NEWS_NOT_FOUND'` → `Left(NewsNotFoundFailure)`; 401 → `UnauthorizedFailure`; 500 → `ServerFailure`
- [X] T007 [P] Em `tnews/domain/news_domain_test.dart`, acrescentar: `GetReelsUseCase`, `ToggleLikeUseCase`, `ToggleSaveUseCase` repassam ao repository; `ReelEntity.copyWith` troca só os campos pedidos; `appendUniqueReels` não repete `id` e devolve quantos entraram

### Implementação

- [X] T008 [P] Criar `news/domain/entities/reel_entity.dart` (`ReelEntity {NewsItemEntity news; String content; int likesCount; bool isLiked = false; bool isSaved}`, getter `id`, `copyWith({int? likesCount, bool? isLiked, bool? isSaved})`), `news/domain/entities/reels_page_entity.dart` (`items`, `String? nextCursor`, `hasMore => nextCursor != null`, extension `appendUniqueReels` em `List<ReelEntity>` devolvendo `(List<ReelEntity>, int)`) e `news/domain/entities/like_result_entity.dart` (`liked`, `likesCount`)
- [X] T009 [P] Criar `news/domain/failures/news_failures.dart` com `NewsNotFoundFailure` (chave `AppStrings.newsErrorNotFound`)
- [X] T010 Em `news/domain/repositories/news_repository.dart`, acrescentar `getReels({String? cursor})` → `Either<Failure, ReelsPageEntity>`, `toggleLike(String newsId)` → `Either<Failure, LikeResultEntity>`, `toggleSave(String newsId)` → `Either<Failure, bool>`; criar `news/domain/usecases/get_reels_usecase.dart`, `toggle_like_usecase.dart`, `toggle_save_usecase.dart`
- [X] T011 [P] Criar `news/data/models/reel_model.dart` (reaproveita `NewsItemModel.fromJson`), `news/data/models/reels_page_model.dart` (item a item, descarta os que lançam `TypeError`/`FormatException`, R8) e `news/data/models/like_result_model.dart`
- [X] T012 Em `news/data/datasources/news_remote_data_source.dart` e `_impl.dart`, acrescentar `getReelsPage({String? cursor})` (constante `reelsPageSize = 10`, `'cursor': ?cursor`), `toggleLike(String id)` e `toggleSave(String id)` via `_apiClient.post('$newsPath/$id/like')`/`'/save'`. `getReels()` do carrossel fica igual
- [X] T013 Em `news/data/repositories/news_repository_impl.dart`, implementar os três métodos com `_guard`; like/save mapeiam `statusCode == 404 || errorCode == 'NEWS_NOT_FOUND'` → `NewsNotFoundFailure` antes do `toFailure()`
- [X] T014 Atualizar `tnews/fakes/fake_news_data_sources.dart` (`reelsPages` por cursor, `likeResult`, `saveResult`, erros e listas de chamadas) e `tnews/fakes/fake_news_repository.dart` (`reelsResults` por cursor, `likeResults`/`saveResults` em fila, `likeGate`/`saveGate` `Completer`, `likeCalls`/`saveCalls`/`reelsCalls`); helper `reel(String id, {int likesCount = 3, bool isSaved = false, String? sourceUrl, String content = 'Texto'})` em `fake_news_repository.dart`
- [X] T015 Em `news/news_module.dart`, registrar `GetReelsUseCase`, `ToggleLikeUseCase`, `ToggleSaveUseCase`. Rodar T004–T007: verdes

**Checkpoint**: dados e domínio dos Reels prontos; `flutter test tnews` verde.

---

## Phase 3: User Story 1 - Passar pelos Reels (Priority: P1) 🎯 MVP

**Goal**: aba Notícias com Reels em tela cheia, gesto e setas, paginação por cursor sem repetir, `start` do carrossel, estados.

**Independent Test**: como visitante, abrir a aba Notícias, passar pelos Reels por gesto e setas até a 2ª parte; tocar num cartão do carrossel e abrir naquele Reel.

### Tests for User Story 1

- [X] T016 [P] [US1] Criar `tnews/presentation/controller/reels_controller_test.dart` (grupo navegação): status `initial` antes do `open`; `open()` → `loading` → `loaded` com a 1ª parte e `currentIndex == 0`; `open('r3')` com `r3` na 1ª parte → `currentIndex == 2`; `open('xx')` → 0; `open('r2')` já carregado → só posiciona, sem novo pedido; falha → `error` + `failure`; `retry()` recarrega; `setIndex` com `reels.length - 1 - index <= 3` pede a parte seguinte com o `nextCursor`; junta sem repetir; parte sem nada novo encerra (`hasMore == false`); sem `hasMore` não pede; dois `setIndex` seguidos → um pedido só; falha na parte seguinte → `loadMoreFailure` e Reels mantidos, sem novo pedido automático; `loadMore()` depois tenta de novo; `canGoPrevious`/`canGoNext`; `isEnd`; resposta de carga antiga ignorada (`refresh` no meio)
- [X] T017 [P] [US1] Criar `tnews/presentation/extensions/reel_presentation_extension_test.dart`: `formattedLikes` (0 → "0", 999 → "999", 1200 → "1,2 mil"); `semanticLabel(now)` com título, fonte e data relativa
- [X] T018 [P] [US1] Criar `tnews/presentation/pages/reels_page_test.dart` (grupo navegação), com `GetIt` (`UserSessionService` visitante, `FakeExternalLauncherService`), `ChangeNotifierProvider<ReelsController>` sobre `FakeNewsRepository` e `MaterialApp.router` simples com `/reels` e `/news/:id`: carregando; erro com "Tentar novamente" que recarrega; vazio com "Atualizar"; primeiro Reel com título, categorias, trecho, fonte e data; arrastar para cima → próximo; seta "Próxima notícia" → próximo; "Notícia anterior" desabilitada no primeiro; `startNewsId: 'r2'` abre no 2º; "Ler notícia completa" abre `/news/r1` uma vez com toque duplo; último Reel com fim → "Você viu todas as notícias"; falha da parte seguinte → "Não foi possível carregar mais" + "Tentar novamente"; Reel sem imagem não quebra; todos os botões ≥ 48×48 e com `Semantics` rotulado

### Implementation for User Story 1

- [X] T019 [US1] Criar `news/presentation/controller/reels_status.dart` (`enum ReelsStatus { initial, loading, loaded, error }`) e `news/presentation/controller/reels_controller.dart` com o estado e as ações de navegação do [data-model](data-model.md#reelscontroller--controllerreels_controllerdart) (`open`, `retry`, `refresh`, `setIndex`, `loadMore`, `prefetchThreshold = 3`, `_requestId`), mais `ReelsMessage`/`ReelsMessageType` e o `Stream<ReelsMessage> messages` (broadcast; fechado no `dispose`). Construtor recebe `getReels`, `toggleLike`, `toggleSave`, `sessionStatus` (`ValueListenable<UserSessionStatus>`). T016 verde
- [X] T020 [P] [US1] Criar `news/presentation/extensions/reel_presentation_extension.dart` (`formattedLikes`, `semanticLabel(now)` reaproveitando `NewsItemPresentation`). T017 verde
- [X] T021 [US1] Criar `news/presentation/widgets/reel_view.dart`: fundo preto, `Image.network` com opacidade 70% e `errorBuilder` (fundo `AppColors.secondary` + ícone de jornal), gradiente do design system §7.10, categorias (`categoryLabels`), título 24/700 até 4 linhas, trecho 14 com 90% até 4 linhas (oculto se vazio), "fonte · data", botão "Ler notícia completa" (branco, raio full, texto `secondary`), rodapé opcional (fim / falha com "Tentar novamente"); `Semantics` com `semanticLabel`
- [X] T022 [US1] Criar `news/presentation/widgets/reel_actions.dart` com a coluna de botões redondos (40 px visuais, branco 20% + desfoque, área de toque ≥ 48 dp): anterior e próxima nesta história (curtir, salvar e abrir fonte entram como parâmetros opcionais, preenchidos nas próximas)
- [X] T023 [US1] Substituir `news/presentation/pages/reels_page.dart` pela tela real: `StatefulWidget` que chama `controller.open(widget.startNewsId)` no `initState` e no `didUpdateWidget` quando o `startNewsId` muda; estados `loading` (com `SlowRequestNotice`), `error`, vazio, em fundo escuro; `PageView.builder(scrollDirection: Axis.vertical)` com `PageController` sincronizado ao `currentIndex`; setas com `animateToPage`; "Ler notícia completa" → `context.push('/news/${id}')` protegido contra toque duplo; sem barra superior
- [X] T024 [US1] Em `news/news_module.dart`, acrescentar em `providers` o `ChangeNotifierProvider(create: (_) => ReelsController(...))` **sem** carga no `create` (R4). T018 verde; rodar `flutter test tnews`

**Checkpoint**: US1 completa e testável sozinha (MVP).

---

## Phase 4: User Story 2 - Curtir um Reel (Priority: P1)

**Goal**: curtir/descurtir com retorno imediato, estado final do servidor, reversão em falha; visitante vê o convite.

**Independent Test**: com conta, curtir e descurtir; como visitante, tocar no coração e ver o convite sem pedido ao serviço.

### Tests for User Story 2

- [X] T025 [P] [US2] Em `tnews/presentation/controller/reels_controller_test.dart` (grupo curtir): `toggleLike('r1')` com `likeGate` segurando → já `isLiked == true` e `likesCount + 1`, `isLikePending('r1')`; ao soltar com `{liked: true, likesCount: 10}` → exatamente 10; segundo `toggleLike` durante o pedido → ignorado (1 chamada); descurtir → −1 na hora; resposta `{liked: false}` partindo de `isLiked == false` (já curtido antes, cenário 2.4) → `false` e a contagem do servidor; falha → estado anterior restaurado e mensagem `error` com a chave do `Failure` (incluindo `NewsNotFoundFailure`); estado mantido depois de `setIndex` para outro Reel e volta
- [X] T026 [P] [US2] Em `tnews/presentation/pages/reels_page_test.dart` (grupo curtir): visitante toca no coração → convite (`AccountRequiredSheet`) e `likeCalls` vazio; conectado (`saveSession` no `UserSessionService`) → coração preenchido e contagem atualizada; falha → `SnackBar` com a mensagem; rótulos "Curtir, 3 curtidas"/"Curtido, 4 curtidas"

### Implementation for User Story 2

- [X] T027 [US2] Em `news/presentation/controller/reels_controller.dart`, implementar `toggleLike(id)` e `isLikePending(id)` (R3). T025 verde
- [X] T028 [US2] Em `news/presentation/extensions/reel_presentation_extension.dart`, acrescentar `likeSemanticLabel`; em `news/presentation/widgets/reel_actions.dart`, o botão de curtir (ícone `heart` preenchido com `AppColors.primary` quando curtido) com a contagem `formattedLikes` abaixo
- [X] T029 [US2] Em `news/presentation/pages/reels_page.dart`, ligar o curtir: `if (await requireAccount(context)) controller.toggleLike(id)`; escutar `controller.messages` e mostrar `SnackBar` (`failureKey.tr()`). T026 verde

**Checkpoint**: US1 + US2 funcionando.

---

## Phase 5: User Story 3 - Salvar um Reel (Priority: P2)

**Goal**: salvar/remover dos salvos com retorno imediato e aviso; visitante vê o convite.

**Independent Test**: com conta, salvar e remover; como visitante, ver o convite.

### Tests for User Story 3

- [X] T030 [P] [US3] Em `tnews/presentation/controller/reels_controller_test.dart` (grupo salvar): otimista; resposta `{saved: true}` → mensagem `saved`; `{saved: false}` → `removed`; o estado final é o devolvido; pendente ignora toques; falha → reverte e mensagem `error`
- [X] T031 [P] [US3] Em `tnews/presentation/pages/reels_page_test.dart` (grupo salvar): visitante → convite, `saveCalls` vazio e marcador vazio mesmo com `isSaved: true` no Reel; conectado → marcador preenchido e `SnackBar` "Notícia salva"/"Removida dos salvos"; rótulos "Salvar"/"Salvo"

### Implementation for User Story 3

- [X] T032 [US3] Em `news/presentation/controller/reels_controller.dart`, implementar `toggleSave(id)` e `isSavePending(id)`. T030 verde
- [X] T033 [US3] Em `reel_presentation_extension.dart`, `saveSemanticLabel`; em `reel_actions.dart`, o botão de salvar (`bookmark`, preenchido quando salvo; recebe `isSaved` já resolvido pela página: visitante → `false`); em `reels_page.dart`, ligar com `requireAccount` e as mensagens `saved`/`removed`. T031 verde

**Checkpoint**: US1–US3 funcionando.

---

## Phase 6: User Story 4 - Abrir a fonte original (Priority: P2)

**Goal**: "Abrir fonte" no navegador externo para qualquer pessoa.

**Independent Test**: tocar em "Abrir fonte" e ver o navegador abrir; repetir como visitante.

- [X] T034 [P] [US4] Em `tnews/presentation/pages/reels_page_test.dart` (grupo fonte): visitante toca em "Abrir fonte" → `FakeExternalLauncherService.openedUrls == ['https://fonte.test/r1']`; `openResult = false` → `SnackBar` "Não foi possível abrir a fonte"; Reel com `sourceUrl` vazio/inválido → botão ausente
- [X] T035 [US4] Em `reel_actions.dart`, botão "Abrir fonte" (`externalLink`), exibido só com `isOpenableWebUrl(sourceUrl)`; em `reels_page.dart`, chamar `GetIt.instance<ExternalLauncherService>().openUrl` e mostrar o aviso em `false`. T034 verde

**Checkpoint**: todas as histórias funcionando.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T036 [P] Em `reels_controller_test.dart` (grupo sessão): depois de carregar, `sessionStatus` muda → próximo `open()` recarrega do início; sem mudança, `open()` não pede de novo. Implementar em `reels_controller.dart` (listener removido no `dispose`)
- [X] T037 [P] Em `.specify/memory/api-contract.md`, linha `GET /app/news/reels` com a observação "cursor inválido devolve 200 com a 1ª parte (specs/008, R0)"; like/save continuam 🧪 até o passo 4 do quickstart
- [X] T038 Formatar só os arquivos tocados (`dart format` em `news/`, `tnews/`, `app_strings.dart`), depois `flutter analyze` (sem avisos novos) e `flutter test` (todos verdes). Revisar código morto
- [X] T039 Validar no aparelho os passos do [quickstart.md](quickstart.md) (SC-001, SC-003 e o contrato de like/save só são conferidos aqui); trocar 🧪 por ✅ no contrato se confirmados. Anotar o resultado nesta tarefa
  - **Resultado (2026-10-08, emulador Pixel 4, servidor de desenvolvimento)**: tudo conforme. Visitante: Reels com dados reais, arrastar entre eles, convite ao curtir/salvar sem mudar nada, "Abrir fonte" no navegador e volta no mesmo Reel. Carrossel do Início abre no Reel tocado. Conta nova: curtir/descurtir (0 → 1 → 0) e salvar/remover com "Notícia salva"/"Removida dos salvos", confirmados pelo servidor. Ao reabrir o app, `isSaved` e `likesCount` voltam do servidor e o coração começa vazio (sem `isLiked`, como previsto). O aviso só aparece quando o servidor responde (alguns segundos no Render). Contrato 1.0.4: like/save ✅. Prints em [evidencias/](evidencias/)
- [ ] T040 Em `.specify/memory/tasks.md`, marcar a A4 como `[x] **A4 Reels** … (specs/008-reels-curtir-salvar)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro.
- **Foundational (Phase 2)**: T002 ∥ T003; testes T004–T007 em paralelo; T008 ∥ T009 ∥ T011; T010 depois de T008/T009; T012 depois de T011; T013 depois de T010 e T012; T014 → T015.
- **US1 (Phase 3)**: depende da Phase 2. T016 ∥ T017 ∥ T018; T019 e T020 em paralelo; T021 → T022 → T023 → T024.
- **US2 (Phase 4)**: depende da US1 (controller, ações e página).
- **US3 (Phase 5)**: depende da US1; independe da US2 (mesmos arquivos: fazer em sequência).
- **US4 (Phase 6)**: depende da US1; independe de US2/US3.
- **Polish (Phase 7)**: depois de todas; T036 ∥ T037.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Controller → extension → widgets → página.
- Commit ao fim de cada fase (Base, US1, US2, US3, US4, Polish).

### Parallel Opportunities

- **Phase 2:** T002 ∥ T003; T004 ∥ T005 ∥ T006 ∥ T007; T008 ∥ T009 ∥ T011.
- **US1:** T016 ∥ T017 ∥ T018; T019 ∥ T020.
- **US2:** T025 ∥ T026. **US3:** T030 ∥ T031.
- **Polish:** T036 ∥ T037.

---

## Parallel Example: Phase 2 (testes)

```bash
Task: "Testes dos models em click_seguro_app/test/modules/news/data/models/reel_models_test.dart"
Task: "Teste do datasource em click_seguro_app/test/modules/news/data/datasources/news_remote_data_source_impl_test.dart"
Task: "Teste do repository em click_seguro_app/test/modules/news/data/repositories/news_repository_impl_test.dart"
Task: "Teste do domínio em click_seguro_app/test/modules/news/domain/news_domain_test.dart"
```

## Parallel Example: User Story 1

```bash
Task: "Teste do controller em click_seguro_app/test/modules/news/presentation/controller/reels_controller_test.dart"
Task: "Teste da extension em click_seguro_app/test/modules/news/presentation/extensions/reel_presentation_extension_test.dart"
Task: "Teste da página em click_seguro_app/test/modules/news/presentation/pages/reels_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): Reels navegáveis.
3. **PARAR e VALIDAR**: `flutter test` verde e os passos 2–3 do quickstart.

### Incremental Delivery

1. Base → dados e domínio.
2. US1 → Reels (MVP).
3. US2 → curtir.
4. US3 → salvar.
5. US4 → abrir a fonte.
6. Polish → sessão, contrato, aparelho e marcar a A4.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- Verifique que o teste falha antes de implementar.
- A Trilha A é da Amanda: combinar antes de abrir o PR para a `develop` (A5 também mexe em `news`).
