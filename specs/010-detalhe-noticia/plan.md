# Implementation Plan: Detalhe da notícia e notícias salvas

**Branch**: `010-detalhe-noticia` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-detalhe-noticia/spec.md`

**Base**: tarefa A5 do [tasks do produto](../../.specify/memory/tasks.md),
[contrato da API](../../.specify/memory/api-contract.md) 1.0.5 "Notícias e Reels" (detalhe, leitura
e salvas conferidos no servidor, [R0](research.md)),
[constituição](../../.specify/memory/constitution.md) v1.1.0,
[design system](../../.specify/memory/design-system.md) (cartão de notícia §7.8, estados §7.16,
acessibilidade §9), módulo `news` das features [006](../006-feed-inicio/plan.md) e
[008](../008-reels-curtir-salvar/plan.md), convite e rotas da
[feature 005](../005-shell-navegacao-base/plan.md), serviços da
[feature 007](../007-servicos-plataforma-voz/plan.md) e preferências da
[feature 009](../009-acessibilidade-global/plan.md).

## Summary

Trocar a página provisória do detalhe pela notícia completa e criar a lista de salvas:

- **Dados**: `NewsRemoteDataSource` ganha `getNewsDetail(id)` (JSON cru, para a cópia),
  `markAsRead(id)` e `getSavedNews(page)`; `NewsLocalDataSource` ganha a cópia das últimas 30
  notícias abertas e a da 1ª página das salvas, marcadas com o dono ([R2, R3](research.md)).
  Model novo: `NewsDetailModel` (+ `SuggestedModuleModel`). O repository usa a cópia em
  `connection`/`timeout` e mapeia 404 → `NewsNotFoundFailure`.
- **Domínio**: `NewsDetailEntity` (compõe `NewsItemEntity`), `SuggestedModuleEntity`,
  `NewsDetailResult` (`detail` + `isFromCache`), `SavedNewsResult`; usecases
  `GetNewsDetailUseCase`, `MarkNewsAsReadUseCase`, `GetSavedNewsUseCase` (salvar reaproveita
  `ToggleSaveUseCase` da 008).
- **Apresentação**: `NewsDetailController` (carga, leitura registrada sem esperar, salvar
  otimista, leitura automática uma vez) e `SavedNewsController` (páginas sem repetir, cópia
  offline, recarga ao voltar); `NewsDetailPage` com cabeçalho, barra de ações (ouvir +
  velocidade, salvar, compartilhar, abrir fonte), texto e `RelatedActivityCard`; `SavedNewsPage`
  com cartões do feed. Rota `/news/saved` antes de `/news/:id` ([R1](research.md)).
- **Sessão**: o `NewsModule` apaga as cópias ao sair da conta ([R3](research.md)).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.6 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`), `fpdart`, `provider`, `get_it`,
`go_router`, `easy_localization`, `lucide_icons_flutter`; serviços do `common`:
`ReadAloudController`/`TextToSpeechService`, `ShareService`, `ExternalLauncherService`,
`LocalCacheService`, `UserSessionService`, `AccessibilityPreferencesNotifier`. Nenhuma nova.

**Storage**: `LocalCacheService` (shared_preferences), duas chaves novas:
`news_detail_cache_v1` (até 30 detalhes) e `news_saved_cache_v1` (1ª página das salvas), ambas
com `owner` ([data-model.md](data-model.md)).

**Testing**: `flutter_test`; `FakeHttpClientAdapter` no datasource, `FakeNewsRemoteDataSource` e
`FakeNewsLocalDataSource` no repository, `FakeNewsRepository` nos usecases/controllers;
`FakeTextToSpeechService`, `FakeShareService`, `FakeExternalLauncherService`,
`FakeLocalCacheService` e `UserSessionService` com `FakeSecureStorageService` nos widget tests;
`Completer` para segurar respostas (otimista, leitura sem esperar). Fixtures com o JSON real do
[R0](research.md).

**Target Platform**: Android e iOS

**Project Type**: mobile-app

**Performance Goals**: notícia completa em até 3 s com o servidor acordado (SC-001); leitura
automática começa em até 1 s depois da notícia aparecer (SC-003); salvar responde na hora
(otimista).

**Constraints**: registro de leitura nunca bloqueia (SC-002); visitante nunca chama
read/save/saved (RN-003); sem voz → nada de ouvir (CB-008); 48 dp, rótulos e alto contraste
(RNF-003, feature 009); toda HTTP pelo `ApiClient` (RNF-005); `news` não importa `activities`
(abre a rota por caminho).

**Scale/Scope**: 1 módulo (`news`) + 1 linha no `lib/dev`; ~20 arquivos de produção
novos/alterados, ~12 de teste, ~30 chaves de i18n.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo em `news` (`data/`, `domain/`, `presentation/`). Controller → usecases → `NewsRepository` → datasources → `ApiClient`/`LocalCacheService`. `news` importa só `shell` (`requireAccount`), `common` (serviços, `ReadAloudController`, preferências, sessão) e `core`. A atividade relacionada abre `/activities/:id` por caminho, sem importar `activities`. A limpeza ao sair fica em `news`, ouvindo a sessão ([R3](research.md)). | ✅ |
| II. SOLID, DRY, KISS | `NewsDetailEntity` compõe `NewsItemEntity` e reaproveita as extensions de data/categorias; `NewsDetailModel` reaproveita `NewsItemModel.fromJson`; salvas reaproveitam `NewsListModel`, `NewsPageEntity`, `appendUnique`, `NewsCard` e `ToggleSaveUseCase`. Cópia do detalhe sem regra de "só salvas" ([R2](research.md)). | ✅ |
| III. TDD | Teste antes de cada camada: models (JSON real, `suggestedModule` nulo/presente, item malformado), datasources (paths, `page`/`limit`, limite de 30, dono), repository (cópia em falha de conexão, 404, dono), usecases, controllers (carga, leitura sem esperar e só com conta, otimista, auto-leitura uma vez, páginas, offline) e widgets (estados, ações, visitante sem chamada, sem voz, bloco de atividade, rota). Tudo offline. | ✅ |
| IV. Stack e DI | Registro em `NewsModule`; controllers por página (`ChangeNotifierProvider` na rota, como o `ReadAloudController`); textos por `easy_localization`. | ✅ |
| V. Erros tipados | `Either<Failure, T>`; `NewsNotFoundFailure` já existe; status e mensagens em enum; `30`, `20` e chaves de cache em constantes nomeadas. | ✅ |

**Pós-design (Phase 1)**: reavaliado; nenhum desvio.

## Project Structure

### Documentation (this feature)

```text
specs/010-detalhe-noticia/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md
├── contracts/news-detail.md
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/modules/news/
├── news_module.dart                                   # usecases novos + limpeza das cópias ao sair
├── data/
│   ├── datasources/news_remote_data_source(_impl).dart  # + getNewsDetail, markAsRead, getSavedNews
│   ├── datasources/news_local_data_source(_impl).dart   # + detalhes (30) e salvas, com dono; clearAccountCopies
│   ├── models/news_detail_model.dart                  # novo (+ SuggestedModuleModel)
│   └── repositories/news_repository_impl.dart         # + getNewsDetail, markAsRead, getSavedNews
├── domain/
│   ├── entities/news_detail_entity.dart               # novo (+ SuggestedModuleEntity, NewsDetailResult)
│   ├── entities/saved_news_result.dart                # novo
│   ├── repositories/news_repository.dart              # + 3 métodos
│   └── usecases/get_news_detail_usecase.dart · mark_news_as_read_usecase.dart · get_saved_news_usecase.dart
└── presentation/
    ├── controller/news_detail_controller.dart · news_detail_status.dart       # novos
    ├── controller/saved_news_controller.dart                                 # novo
    ├── extensions/news_detail_presentation_extension.dart                    # texto lido, texto compartilhado, rótulos
    ├── pages/news_detail_page.dart                    # provisória → tela real
    ├── pages/saved_news_page.dart                     # nova
    ├── routes/news_routes.dart                        # + /news/saved antes de /news/:id
    └── widgets/news_detail_header.dart · news_detail_actions.dart · read_aloud_bar.dart · related_activity_card.dart
lib/dev/accessibility_playground.dart                  # botão "Notícias salvas" (R8)
lib/core/i18n/app_strings.dart + assets/translations/*.json    # bloco news
.specify/memory/plan.md                                 # §2: rota /news/saved

test/modules/news/   (espelha lib/; fakes/ ganham detalhe, leitura, salvas e cópias)
```

**Structure Decision**: segue o §1.2 do plano do produto e o padrão das features 006 e 008 no
mesmo módulo. Os widgets recebem entidades e callbacks; regras de leitura, otimismo, auto-leitura
e paginação ficam nos controllers, testáveis sem UI.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; entidades e models com fixtures do servidor; datasources remoto e local;
   repository; usecases; fakes; registro no módulo; rota `/news/saved`.
2. **US1**: `NewsDetailController` (carga, cópia, leitura sem esperar), cabeçalho, texto,
   estados, `NewsDetailPage`.
3. **US2**: barra de ouvir (velocidade, parar, auto-leitura, sem voz).
4. **US3**: salvar no detalhe; `SavedNewsController` e `SavedNewsPage`; limpeza ao sair; entrada
   de desenvolvimento.
5. **US4**: compartilhar e abrir a fonte.
6. **US5**: `RelatedActivityCard`.
7. **Polimento**: plano do produto (§2) com a rota; analyze; suíte; teste no emulador com
   prints em `evidencias/`; marcar A5.

## Complexity Tracking

Nenhuma violação a justificar.
