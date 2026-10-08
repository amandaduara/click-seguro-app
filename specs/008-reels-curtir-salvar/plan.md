# Implementation Plan: Reels com curtir, salvar e abrir a fonte

**Branch**: `008-reels-curtir-salvar` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-reels-curtir-salvar/spec.md`

**Base**: tarefa A4 do [tasks do produto](../../.specify/memory/tasks.md),
[contrato da API](../../.specify/memory/api-contract.md) "Notícias e Reels" (Reels conferidos no
servidor, [R0](research.md)), [guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md),
[constituição](../../.specify/memory/constitution.md) v1.1.0,
[design system](../../.specify/memory/design-system.md) §7.10, módulo `news` da
[feature 006](../006-feed-inicio/plan.md), convite da [feature 005](../005-shell-navegacao-base/plan.md)
e `ExternalLauncherService` da [feature 007](../007-servicos-plataforma-voz/plan.md).

## Summary

Completar o módulo `news` com a tela de Reels da aba central:

- **Dados**: `NewsRemoteDataSource` ganha `getReelsPage(cursor)`, `toggleLike(id)` e
  `toggleSave(id)`; models `ReelModel`, `ReelsPageModel` (descarta item malformado, [R8](research.md))
  e `LikeResultModel`. O repository mapeia 404 → `NewsNotFoundFailure`.
- **Domínio**: `ReelEntity` (composição com `NewsItemEntity`), `ReelsPageEntity`,
  `LikeResultEntity`, três usecases.
- **Apresentação**: `ReelsController` (carga por cursor sem repetir, posição, `start`,
  atualização otimista com reversão, toques ignorados durante o pedido, recarga quando a sessão
  muda), extension de rótulos e a `ReelsPage` com `PageView` vertical, botões e estados, no lugar
  da página provisória.
- **Contrato**: linha dos Reels ✅ com a observação do cursor inválido; like/save seguem 🧪 até o
  teste com conta ([R1](research.md)).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.6 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`), `fpdart`, `provider`, `get_it`,
`go_router`, `easy_localization`, `lucide_icons_flutter`, `url_launcher` (via
`ExternalLauncherService`). Nenhuma nova.

**Storage**: nenhum (Reels sem cópia offline).

**Testing**: `flutter_test`; `FakeHttpClientAdapter`/`FakeNewsRemoteDataSource` no repository,
`FakeNewsRepository` nos usecases/controller, `FakeExternalLauncherService` e
`UserSessionService` com `FakeSecureStorageService` nos widget tests; `Completer` para segurar
respostas e testar o estado otimista e os toques repetidos.

**Target Platform**: Android e iOS

**Project Type**: mobile-app

**Performance Goals**: primeiro Reel em até 3 s com o servidor acordado (SC-001); retorno do
toque em curtir/salvar < 100 ms (SC-003, atualização otimista).

**Constraints**: sem repetir Reels nem pedir depois do fim (CB-007); visitante nunca chama
like/save (RN-003); 48 dp e rótulos (RNF-003); toda HTTP pelo `ApiClient` (RNF-005).

**Scale/Scope**: 1 módulo (`news`), ~14 arquivos de produção novos/alterados, ~8 de teste,
~18 chaves de i18n.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo dentro de `news` (`data/`, `domain/`, `presentation/`). Controller → usecases → `NewsRepository` → datasource → `ApiClient`. `news` importa só `shell` (`requireAccount`), `common` (`ExternalLauncherService`, `UserSessionService`) e `core`, como já faz. | ✅ |
| II. SOLID, DRY, KISS | `ReelEntity` reaproveita `NewsItemEntity` e as extensions de data/categorias; `ReelModel` reaproveita `NewsItemModel.fromJson`; dedup no mesmo padrão do `appendUnique`; sem pacote novo. | ✅ |
| III. TDD | Teste antes de cada camada: models (formato real, item malformado), datasource (paths, `cursor`, `limit`), repository (404 → `NewsNotFoundFailure`, demais falhas), usecases, controller (paginação, `start`, otimista, reversão, pendências, sessão), extension (rótulos) e widgets (estados, navegação, visitante sem chamada, abrir fonte). Tudo offline. | ✅ |
| IV. Stack e DI | Registro em `NewsModule.registerServices`/`providers`; textos por `easy_localization`; `Provider`/`ChangeNotifier`. | ✅ |
| V. Erros tipados | `Either<Failure, T>`; `NewsNotFoundFailure` com chave i18n; `ReelsStatus` e `ReelsMessageType` em enum; `limit` e limiar de pré-carga em constantes nomeadas. | ✅ |

**Pós-design (Phase 1)**: reavaliado; nenhum desvio.

## Project Structure

### Documentation (this feature)

```text
specs/008-reels-curtir-salvar/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md
├── contracts/reels.md
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/modules/news/
├── news_module.dart                                   # registra usecases e ReelsController
├── data/
│   ├── datasources/news_remote_data_source(_impl).dart  # + getReelsPage, toggleLike, toggleSave
│   ├── models/reel_model.dart · reels_page_model.dart · like_result_model.dart   # novos
│   └── repositories/news_repository_impl.dart         # + getReels, toggleLike, toggleSave
├── domain/
│   ├── entities/reel_entity.dart · reels_page_entity.dart · like_result_entity.dart   # novos
│   ├── failures/news_failures.dart                    # novo: NewsNotFoundFailure
│   ├── repositories/news_repository.dart              # + 3 métodos
│   └── usecases/get_reels_usecase.dart · toggle_like_usecase.dart · toggle_save_usecase.dart
└── presentation/
    ├── controller/reels_controller.dart · reels_status.dart
    ├── extensions/reel_presentation_extension.dart
    ├── pages/reels_page.dart                          # provisória → tela real
    └── widgets/reel_view.dart · reel_actions.dart
lib/core/i18n/app_strings.dart + assets/translations/*.json    # bloco news
.specify/memory/api-contract.md                                 # Reels ✅ + observação do cursor

test/modules/news/   (espelha lib/; fakes/ ganham reels, like e save)
```

**Structure Decision**: segue o §1.2 do plano do produto e o padrão já usado pela feature 006
no mesmo módulo. Os widgets recebem o `ReelEntity` e callbacks; regras de paginação e de
otimismo ficam no controller, testáveis sem UI.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; entidades, failure, models com fixtures do servidor; datasource; repository;
   usecases; fakes; registro no módulo.
2. **US1**: controller (carga, `start`, índice, pré-carga, fim, falha de parte), extension,
   `ReelView`, setas, `ReelsPage` com estados.
3. **US2**: curtir (otimista, reversão, pendente, visitante → convite).
4. **US3**: salvar (idem + mensagens).
5. **US4**: abrir a fonte.
6. **Polimento**: sessão mudou → recarga; contrato ✅; analyze; suíte; marcar A4.

## Complexity Tracking

Nenhuma violação a justificar.
