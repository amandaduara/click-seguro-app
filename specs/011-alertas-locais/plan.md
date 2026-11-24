# Implementation Plan: Alertas locais de notícias novas

**Branch**: `011-alertas-locais` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/011-alertas-locais/spec.md`

**Base**: tarefa A6 do [tasks do produto](../../.specify/memory/tasks.md),
[contrato da API](../../.specify/memory/api-contract.md) 1.0.6 "Alertas — A6",
[constituição](../../.specify/memory/constitution.md) v1.1.0,
[design system](../../.specify/memory/design-system.md) (barra superior §7.11, estados §7.16,
acessibilidade §9), esqueleto do módulo `notifications` da
[feature 005](../005-shell-navegacao-base/plan.md), detalhe da notícia da
[feature 010](../010-detalhe-noticia/plan.md) e preferências da
[feature 009](../009-acessibilidade-global/plan.md).

## Summary

Dar vida ao sino e à tela de Alertas, tudo no módulo `notifications` (mais o contador no sino):

- **Dados**: `AlertsRemoteDataSource` (próprio, sem importar `news`) com `fetchNewAlerts` sobre
  `GET /app/news` e `getReceiveAlerts` sobre `GET /users/me`; `AlertsLocalDataSource` com **um
  registro por conta** (alertas, lidos, última verificação, dono) no `LocalCacheService`;
  `AlertModel` tolerante a item ruim; `NotificationsRepositoryImpl` ([R0, R1, R4, R9](research.md)).
- **Domínio**: `AlertEntity`, `AlertsSnapshot`; usecases `CheckNewAlertsUseCase` (primeira vez só
  marca o horário, sem repetir por `newsId`, 50 alertas/30 dias, respeita "Receber alertas"),
  `GetAlertsUseCase`, `MarkAsReadUseCase`, `MarkAllAsReadUseCase`, `ClearAlertsUseCase`. O
  contador é derivado do snapshot (divergência do backlog, [data-model](data-model.md)).
- **Apresentação**: `NotificationsController` único, criado no módulo (estado do contador vive
  entre telas), com fila de gravações ([R5](research.md)); `AlertsLifecycleTrigger` confere ao
  abrir, ao voltar ao app e ao abrir a tela ([R2](research.md)); extension de agrupamento
  Hoje/Ontem/Anteriores ([R8](research.md)); `NotificationBellButton` com contador;
  `NotificationsPage` com resumo e botão fixos, faixas fixas, lista agrupada e convite para
  visitante ([R12](research.md)).
- **Sessão**: o controller ouve `sessionStatus` e apaga tudo ao sair ([R4](research.md)).
- **Documentos do produto**: `api-contract.md` (`limit=50`, resultados do R0) e `plan.md`
  (usecases do módulo, leitura de `receiveNotifications`, design system do contador).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.6 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`), `fpdart`, `provider`, `get_it`,
`go_router`, `easy_localization`, `lucide_icons_flutter`; `common`: `LocalCacheService`,
`UserSessionService`, `ApiClient`. Nenhuma nova (formatação de hora/data sem `intl`, R8).

**Storage**: `LocalCacheService` (shared_preferences), uma chave nova `notifications_alerts_v1`
com `owner` ([data-model.md](data-model.md)).

**Testing**: `flutter_test`; `FakeHttpClientAdapter` no datasource remoto,
`FakeNotificationsRemoteDataSource`/`FakeNotificationsLocalDataSource` no repository,
`FakeNotificationsRepository` nos usecases/controller, `FakeLocalCacheService` e
`UserSessionService` com `FakeSecureStorageService` nos widget tests; `Completer` para segurar
a conferência (fila, marcar durante a conferência); `tester.binding.handleAppLifecycleStateChanged`
para o gatilho; relógio injetado (`now`). Fixtures com o JSON do [R0](research.md).

**Target Platform**: Android e iOS

**Project Type**: mobile-app

**Performance Goals**: contador atualizado em até 5 s depois de abrir o app com o serviço acordado
(SC-001); marcar como lido muda a tela na hora (estado em memória primeiro); nenhuma tela espera
a conferência (SC-009).

**Constraints**: visitante nunca chama o serviço (RN-003, SC-004); conferência falha em silêncio
(FR-005); no máximo uma conferência por vez e uma automática a cada 5 min (R2); `notifications`
não importa `news`, `shell`, `authentication` nem `profile` (abre `/news/:id` e `/profile/edit`
por caminho); 48 dp, rótulos e alto contraste (RNF-003, feature 009); toda HTTP pelo
`ApiClient` (RNF-005); sem push (v1).

**Scale/Scope**: 1 módulo novo preenchido (`notifications`) + `shell` (`AppTopBar` não muda de
lógica; testes do shell ganham provider) + 1 arquivo em `lib/dev`; ~25 arquivos de produção
novos/alterados, ~18 de teste, ~25 chaves de i18n.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo em `notifications` (`data/`, `domain/`, `presentation/`). Controller → usecases → `NotificationsRepository` → datasources → `ApiClient`/`LocalCacheService`. O módulo importa só `common` e `core`. `shell` importa o barrel de `notifications` (já era assim, F0.9) e continua dono do convite (`requireAccount`). A rota `/news/:id` e `/profile/edit` abrem por caminho. A limpeza ao sair fica no próprio módulo ouvindo a sessão ([R4](research.md)). | ✅ |
| II. SOLID, DRY, KISS | Um registro local por conta; contador derivado (sem usecase redundante); regras de "nova", limite e chave desligada em um só usecase; agrupamento e rótulos em extensions testáveis; `AlertTile`, `AlertsSummaryBar` e `AlertsNotices` pequenos e sem lógica. Sem `intl` novo. | ✅ |
| III. TDD | Teste antes de cada camada: model (item ruim, data de fallback), datasources (query, `ConnectionFailure`, dono, ilegível, limpeza), repository (mapeamento de falhas), usecases (primeira vez, repetição, 50/30 dias, chave desligada, falha sem gravar, rede de segurança do filtro), extension de agrupamento, controller (fila, intervalo, sessão, marcar durante conferência) e widgets (sino, tela, visitante, faixas, 2×). Tudo offline. | ✅ |
| IV. Stack e DI | Registro em `NotificationsModule` (`registerServices` + `providers`); datasources por `LocalCacheService` e `ApiClient` já registrados no `common`; textos por `easy_localization`. | ✅ |
| V. Erros tipados | `Either<Failure, T>` com `ConnectionFailure`, `ServerFailure`, `CacheFailure` existentes; status em enum (`AlertsStatus`, `AlertGroup`, `CheckOutcome`); `50`, `30`, `5 min` e a chave de cache em constantes nomeadas; mensagens por chave de i18n. | ✅ |

**Pós-design (Phase 1)**: reavaliado; nenhum desvio. Dois ajustes ao backlog, registrados:
`GetUnreadCount` vira propriedade derivada e entra `ClearAlertsUseCase`.

## Project Structure

### Documentation (this feature)

```text
specs/011-alertas-locais/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md
├── contracts/alerts.md
├── checklists/requirements.md
├── evidencias/                    # prints e relatório do teste no emulador (tasks.md)
└── tasks.md                       # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/modules/notifications/
├── notifications.dart                                  # barrel (+ controller, para o shell)
├── notifications_module.dart                           # datasources, repository, usecases + providers (controller e gatilho)
├── data/
│   ├── datasources/alerts_remote_data_source(_impl).dart    # fetchNewAlerts (GET /app/news), getReceiveAlerts (GET /users/me)
│   ├── datasources/alerts_local_data_source(_impl).dart     # registro único com dono, clear
│   ├── models/alert_model.dart · alerts_snapshot_model.dart
│   └── repositories/notifications_repository_impl.dart
├── domain/
│   ├── entities/alert_entity.dart · alerts_snapshot.dart · check_new_alerts_result.dart
│   ├── repositories/notifications_repository.dart
│   └── usecases/check_new_alerts_usecase.dart · get_alerts_usecase.dart · mark_as_read_usecase.dart
│                · mark_all_as_read_usecase.dart · clear_alerts_usecase.dart
└── presentation/
    ├── controller/notifications_controller.dart · alerts_status.dart · alerts_lifecycle_trigger.dart
    ├── extensions/alerts_grouping.dart · alert_presentation_extension.dart
    ├── pages/notifications_page.dart                   # provisória → tela real
    ├── routes/notifications_routes.dart                # mantém /notifications
    └── widgets/notification_bell_button.dart (alterado) · alert_tile.dart · alerts_summary_bar.dart · alerts_notices.dart
lib/modules/shell/presentation/widgets/app_top_bar.dart # sem mudança de lógica (requireAccount segue aqui)
lib/dev/accessibility_playground.dart                   # botões "Alertas: voltar verificação 7 dias" / "apagar" (R10)
lib/core/i18n/app_strings.dart + assets/translations/*.json   # bloco notifications; shell_notifications → "Alertas"
.specify/memory/api-contract.md · plan.md · design-system.md   # limit=50 e R0; usecases do módulo; contador

test/modules/notifications/   (espelha lib/; fakes/ com datasources, repository, fixtures e factory do controller)
test/helpers/notifications_provider.dart                # fakeNotificationsProvider para testes do shell/app
```

**Structure Decision**: segue o §1.2 do plano do produto e o padrão das features 006, 008 e 010
(estado global do módulo em `providers`, páginas e widgets burros, regras em usecases e
controller testáveis sem UI). O `NotificationBellButton` lê o controller do módulo; o
`AppTopBar` continua só decidindo entre abrir a tela e mostrar o convite.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Setup**: linha de base; conferir no serviço o que o `openapi.json` não diz ([R0](research.md)).
2. **Base**: i18n; entidades, models e fixtures; datasources remoto e local; repository; usecases;
   fakes; registro no módulo.
3. **US1 (contador)**: controller com fila e intervalo; gatilho do ciclo de vida; sino com
   contador; provider nos testes do shell; entrada de desenvolvimento.
4. **US2 (lista)**: agrupamento e rótulos; `AlertTile`; `NotificationsPage` com resumo, lista e
   abrir a notícia.
5. **US3 (marcar todos)**: botão fixo e ação.
6. **US4 (visitante e desligado)**: convite na tela, faixas, aviso de desligado, limpeza ao sair.
7. **Polimento**: acessibilidade (48 dp, 2×, alto contraste, ordem do `Semantics`); contrato,
   plano e design system; analyze; suíte; teste no emulador com prints em `evidencias/`; marcar A6.

## Complexity Tracking

Nenhuma violação a justificar.
