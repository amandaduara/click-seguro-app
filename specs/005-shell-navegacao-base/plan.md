# Implementation Plan: Shell de navegação e base das trilhas

**Branch**: `005-shell-navegacao-base` | **Date**: 2026-10-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-shell-navegacao-base/spec.md`

**Base**: tarefas F0.7–F0.11 do [tasks do produto](../../.specify/memory/tasks.md),
[plano do produto](../../.specify/memory/plan.md) §1.3, §1.4, §2 e §6,
[design system](../../.specify/memory/design-system.md) §7.11, §7.12 e §7.16,
[constituição](../../.specify/memory/constitution.md) v1.1.0, sessão das features
[001](../001-sessao-persistente-visitante/spec.md)/[002](../002-apiclient-renovacao-sessao/plan.md),
splash da [004](../004-splash-onboarding-sessao/plan.md), wireframe `BottomNav.tsx` e `TopBar.tsx`.

## Summary

Criar a casca do app e a base das duas trilhas:

- **Navegação** ([R1](research.md)–[R3](research.md)): `StatefulShellRoute.indexedStack` com
  cinco abas (Início, Atividades, Notícias/Reels no centro, Ajuda, Perfil) e o `AppShell` com a
  barra inferior do wireframe. Telas sobre as abas no navegador raiz. Cada módulo exporta as
  suas rotas; o `app_router.dart` só compõe, e vira `buildAppRouter(session)`.
- **Esqueleto** (F0.7): módulos `news`, `notifications`, `activities`, `help`, `profile`,
  `settings` e `shell`, cada um com module, barrel, `presentation/routes/` e páginas
  provisórias (`ComingSoonView`), registrados no `main.dart` na ordem do §1.4.
- **Conta e sessão** ([R4](research.md), [R5](research.md)): `requireAccount` +
  `AccountRequiredSheet`; `redirect` só para a saída; `SessionExpiredListener` com `SnackBar`
  para a expiração.
- **Barra superior** ([R6](research.md)): `AppTopBar` público, colocado pelas páginas de Início,
  Atividades e Ajuda; sino do `notifications` sem `requireAccount` próprio (sem ciclo).
- **Estados comuns** ([R8](research.md)): `SafeLoadingState`, `SafeErrorState`,
  `SafeEmptyState`, `SafeOfflineBanner` em `core/widgets` e no style guide.
- **i18n** ([R10](research.md)) e **teste de fumaça** ([R9](research.md)); remoção da
  `HomePlaceholderPage`.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `go_router ^17.3.0` (`StatefulShellRoute`,
`refreshListenable`, `redirect`), `provider`, `get_it`, `easy_localization`,
`lucide_icons_flutter`. Nenhuma dependência nova.

**Storage**: nada novo (lê a sessão e a marcação do onboarding que já existem).

**Testing**: `flutter_test` com widget tests (relógio falso), `pumpLocalized`, `GoRouter` de
teste e `FakeSecureStorageService`; smoke test com os módulos reais. Offline.

**Target Platform**: Android e iOS (o style guide também roda no Chrome).

**Project Type**: mobile-app

**Performance Goals**: troca de aba instantânea (sem recarregar a aba: `indexedStack`).

**Constraints**: caminhos exatamente como no plano do produto §2; 48 dp/16 sp (RNF-003); rótulos
para leitor de tela (RNF-004); textos por `easy_localization` (RNF-006); `app_router.dart`,
`main.dart`, `common/` e `shell/` fechados depois desta feature.

**Scale/Scope**: 7 módulos novos (cerca de 35 arquivos pequenos), 4 widgets de estado, 2
arquivos de roteamento novos em `core/routing`, ~36 chaves de i18n; cerca de 10 arquivos de
teste.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Todo módulo novo implementa `ModuleInterface` e entra pelo `ModuleManager`. Os módulos começam só com `presentation/` (sem regra nem dados ainda; a constituição permite omitir `data/` e `domain/` nesse caso). Dependência entre módulos só pelo barrel. `shell → notifications` (permitido pelo §1.3); trilhas → `shell` (necessário para o `requireAccount` que o §2 põe no shell; §1.3 atualizado nesta feature). Sem ciclo ([R5](research.md)). | ✅ |
| II. SOLID, DRY, KISS | Um convite, uma barra superior, um `ComingSoonView` e quatro estados reutilizados por todos; sem abstrações novas além do necessário. `requireAccount` lê o serviço direto, sem usecase artificial ([R5](research.md)). | ✅ |
| III. TDD | Testes antes do código para: `requireAccount`/convite, `AppShell` (abas, estado, voltar), `AppTopBar`, reação à sessão (expirar e sair), rotas (todos os caminhos e o "não encontrada"), os quatro estados (incluindo 48 dp) e chaves de i18n; smoke test. Widget tests cobrem sucesso e recusa. | ✅ |
| IV. Stack e DI | Só go_router/provider/get_it/easy_localization já adotados. Módulos sem serviços ainda (`registerServices` vazio). | ✅ |
| V. Erros tipados, sem strings mágicas | Motivo do encerramento é o enum `SessionEndReason`; caminhos públicos numa constante nomeada; índices de aba num enum/constante do shell. Mensagens por chave de i18n. | ✅ |
| Regras globais | UI usa GetIt só para obter `UserSessionService` (permitido). Sem `!` especulativo. | ✅ |

**Pós-design (Phase 1)**: reavaliado após o data-model e os contratos; nenhum desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/005-shell-navegacao-base/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # R1–R11
├── data-model.md                 # abas, reação à sessão, requireAccount, chaves de i18n
├── quickstart.md
├── contracts/
│   ├── routes.md                 # todos os caminhos, navegador e dono
│   └── shell-api.md              # API pública do shell, notifications e core
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── main.dart                                   # registra os 7 módulos (§1.4); ClickSeguroApp(router:)
├── core/
│   ├── i18n/app_strings.dart                   # blocos por módulo; sem home_placeholder_*
│   ├── routing/
│   │   ├── app_router.dart                     # buildAppRouter(session): raiz + shell + topo, redirect, errorBuilder
│   │   ├── navigator_keys.dart                 # NOVO: rootNavigatorKey, rootScaffoldMessengerKey
│   │   ├── not_found_page.dart                 # NOVO
│   │   └── home_placeholder_page.dart          # REMOVIDO
│   └── widgets/
│       ├── coming_soon_view.dart               # NOVO
│       ├── safe_loading_state.dart             # NOVO
│       ├── safe_error_state.dart               # NOVO
│       ├── safe_empty_state.dart               # NOVO
│       └── safe_offline_banner.dart            # NOVO
├── style_guide/style_guide.dart                # + seção "Estados"
└── modules/
    ├── shell/                                  # NOVO
    │   ├── shell.dart · shell_module.dart
    │   └── presentation/
    │       ├── app_shell.dart                  # Scaffold + AppBottomNav + PopScope
    │       ├── widgets/app_bottom_nav.dart · app_top_bar.dart · account_required_sheet.dart
    │       ├── widgets/session_expired_listener.dart
    │       └── require_account.dart
    ├── news/                                   # NOVO: news.dart · news_module.dart
    │   └── presentation/{pages/news_home_page.dart, reels_page.dart, news_detail_page.dart,
    │                     routes/news_routes.dart}
    ├── notifications/                          # NOVO: + widgets/notification_bell_button.dart
    │   └── presentation/{pages/notifications_page.dart, routes/notifications_routes.dart}
    ├── activities/  presentation/{pages/activities_page.dart, activity_module_page.dart, routes/}
    ├── help/        presentation/{pages/help_page.dart, help_contact_page.dart, routes/}
    ├── profile/     presentation/{pages/profile_page.dart, profile_edit_page.dart, routes/}
    └── settings/    presentation/{pages/settings_page.dart (+ subtelas), routes/}
assets/translations/{pt-BR,en-US}.json          # chaves do data-model; sem home_placeholder_*

test/
├── widget_test.dart                            # smoke test (substitui o vazio)
├── core/routing/app_router_test.dart           # caminhos, não encontrada, redirect da saída
├── core/widgets/safe_states_test.dart · coming_soon_view_test.dart
├── modules/shell/presentation/
│   ├── app_shell_test.dart · app_top_bar_test.dart
│   ├── require_account_test.dart · session_expired_listener_test.dart
├── modules/shell/i18n_keys_test.dart           # prefixos common_/shell_/news_/…
└── modules/authentication/presentation/i18n_keys_test.dart   # sem home_placeholder_
```

**Structure Decision**: segue o §1.2 do plano do produto. Os módulos novos começam só com
`presentation/`; `data/` e `domain/` nascem com a primeira regra de cada trilha. Widgets de
estado e a tela provisória ficam em `core/widgets` (design system, sem dependência de módulo);
`requireAccount`, barras e o shell ficam no módulo `shell`.

## Fora do código (documentos do produto)

- **Plano do produto §1.3**: trocar "`news` → nenhuma", "`profile` → nenhuma" pela regra "todo
  módulo de feature → `shell` (barrel: `requireAccount`, `AppTopBar`), exceto `notifications`;
  `shell → notifications` (`NotificationBellButton`)". Feito junto com este plano.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: chaves de i18n e `navigator_keys`; `ComingSoonView`; esqueleto dos 7 módulos com
   páginas provisórias e rotas; `buildAppRouter` + `main.dart`; remover a `HomePlaceholderPage`.
2. **US1**: `AppBottomNav`, `AppShell` (abas, estado, voltar), `AppTopBar`, `NotFoundPage`,
   teste de rotas; smoke test.
3. **US2**: `requireAccount` + `AccountRequiredSheet`; sino no `AppTopBar`.
4. **US3**: `redirect` da saída; `SessionExpiredListener`.
5. **US4**: quatro estados + style guide.
6. **Polimento**: analyze, suíte, quickstart no aparelho, marcar F0.7–F0.11.

## Complexity Tracking

Nenhuma violação a justificar.
