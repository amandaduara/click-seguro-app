# Implementation Plan: Feed da aba Início

**Branch**: `006-feed-inicio` | **Date**: 2026-10-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-feed-inicio/spec.md`

**Base**: tarefa A3 do [tasks do produto](../../.specify/memory/tasks.md),
[contrato da API](../../.specify/memory/api-contract.md) "Notícias e Reels" (conferido no
servidor, [R0](research.md)), [guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md),
[constituição](../../.specify/memory/constitution.md) v1.1.0,
[design system](../../.specify/memory/design-system.md) §7.4–§7.9 e §7.16, casca da
[feature 005](../005-shell-navegacao-base/plan.md), cache local da
[feature 001](../001-sessao-persistente-visitante/plan.md).

## Summary

Construir as camadas `data/`, `domain/` e `presentation/` do módulo `news` para a aba Início,
seguindo o guia de integração:

- **Dados**: `NewsRemoteDataSource` (feed por **página**, porque o servidor ignora o cursor do
  feed, [R1](research.md); lista filtrada com cancelamento da consulta anterior, [R3](research.md);
  Reels do carrossel; categorias) e `NewsLocalDataSource` (cópia da 1ª carga, [R4](research.md)).
- **Domínio**: entidades, `NewsFilter`, contrato do repository e quatro usecases; o repository
  devolve a cópia guardada em falha de conexão/servidor.
- **Apresentação**: `FeedController` (carga, paginação sem repetir, filtro, busca com espera de
  500 ms, respostas antigas descartadas, contagem de novas), extensions de exibição (data relativa,
  categorias, rótulo acessível) e a `FeedPage` com os widgets do wireframe, no lugar da
  `NewsHomePage` provisória.
- **Contrato**: linhas de notícias conferidas viram ✅; cursor do feed marcado ⚠️.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`), `fpdart`, `provider`, `get_it`,
`go_router`, `easy_localization`, `shared_preferences` (via `LocalCacheService`),
`lucide_icons_flutter`. Nenhuma dependência nova ([R7](research.md), [R8](research.md)).

**Storage**: `LocalCacheService`, chave `news_feed_cache_v1` (JSON cru da 1ª página + Reels).

**Testing**: `flutter_test`; `FakeHttpClientAdapter` no datasource, `FakeLocalCacheService` no
local, `FakeNewsRepository` nos usecases/controller; relógio falso do `testWidgets` para a espera
da busca; `now` injetado para datas.

**Target Platform**: Android e iOS

**Project Type**: mobile-app

**Performance Goals**: primeiras notícias em até 3 s com o servidor acordado (SC-001); no
máximo um pedido por busca digitada normalmente (SC-003).

**Constraints**: sem repetir notícias nem pedir depois do fim (CB-007), mesmo com o servidor
repetindo páginas; offline com a última 1ª carga (RNF-002); 48 dp/16 sp (RNF-003); toda HTTP pelo
`ApiClient` (RNF-005).

**Scale/Scope**: 1 módulo (`news`), ~25 arquivos de produção, ~12 de teste, ~35 chaves de i18n.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | `news` ganha `data/`, `domain/`, `presentation/` completos. Controller → usecases → repository (contrato) → datasources → `ApiClient`/`LocalCacheService`. `news` só importa `shell` (`AppTopBar`) e `common`/`core`, como o §1.3 permite. | ✅ |
| II. SOLID, DRY, KISS | Um modelo de item para feed, lista e Reels; cópia guardada reaproveita os mesmos `fromJson`; sem pacote de imagem nem `intl` direto; sem `Failure` nova para cancelamento ([R3](research.md)). | ✅ |
| III. TDD | Teste antes de cada camada: models (ida e volta JSON), datasource (pedidos, parâmetros, cancelamento), local (ler/gravar/ilegível), repository (cópia, deduplicação, fim, falhas), usecases, controller (paginação, filtro, busca, respostas antigas, contagem), extensions (datas, categorias) e widgets (estados, cartão, filtros, carrossel). Tudo offline. | ✅ |
| IV. Stack e DI | Registro no `NewsModule.registerServices`; `FeedController` em `providers`; textos por `easy_localization`. | ✅ |
| V. Erros tipados | Repository captura `ApiException` e devolve `Either`; usa `toFailure()`; status do feed em enum (`FeedStatus`); chave da cópia e limites em constantes nomeadas. | ✅ |

**Pós-design (Phase 1)**: reavaliado; nenhum desvio.

## Project Structure

### Documentation (this feature)

```text
specs/006-feed-inicio/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md
├── contracts/news-feed.md
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/modules/news/
├── news.dart · news_module.dart                         # registra datasources, repository, usecases, FeedController
├── data/
│   ├── datasources/news_remote_data_source(_impl).dart
│   ├── datasources/news_local_data_source(_impl).dart
│   ├── models/news_item_model.dart · news_category_model.dart · news_feed_model.dart · news_list_model.dart
│   └── repositories/news_repository_impl.dart
├── domain/
│   ├── entities/news_item_entity.dart · news_category_entity.dart · news_page_entity.dart · news_feed_entity.dart
│   ├── entities/news_filter.dart
│   ├── repositories/news_repository.dart
│   └── usecases/get_feed_usecase.dart · get_feed_page_usecase.dart · get_news_usecase.dart · get_categories_usecase.dart
└── presentation/
    ├── controller/feed_controller.dart · feed_status.dart
    ├── extensions/news_presentation_extension.dart
    ├── pages/news_home_page.dart                         # passa a ser o feed real
    └── widgets/news_card.dart · category_filter_bar.dart · reels_carousel.dart
                feed_search_field.dart · feed_section.dart · feed_list_footer.dart
lib/core/i18n/app_strings.dart + assets/translations/*.json    # bloco news
.specify/memory/api-contract.md                                 # ✅/⚠️ das linhas de notícias

test/modules/news/   (espelha lib/ + fakes/fake_news_repository.dart, fixtures JSON em fakes/)
```

**Structure Decision**: segue o §1.2 do plano do produto e o guia de integração. Widgets de lista
recebem valores prontos (strings/flags) da extension, não a entidade inteira, exceto o cartão,
que recebe a entidade e usa a extension (plano do produto §5).

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: contrato da API atualizado; chaves de i18n; entidades, `NewsFilter`, models com
   fixtures do servidor real; datasources; repository; usecases; registro no módulo.
2. **US1**: controller (carga, paginação sem repetir, atualizar, contagem), extensions, cartão,
   carrossel, seções, `NewsHomePage` com estados.
3. **US2**: filtros de categoria (controller + barra).
4. **US3**: busca (espera, cancelamento, respostas antigas, estado vazio).
5. **US4**: cópia guardada na UI (faixa, fim offline, erro sem cópia).
6. **Polimento**: analyze, suíte, aparelho, marcar A3.

## Complexity Tracking

Nenhuma violação a justificar.
