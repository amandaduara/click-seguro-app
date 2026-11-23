# Tasks: Padrão único para a falta de internet

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/ui-contract.md](contracts/ui-contract.md),
[quickstart.md](quickstart.md)

**Testes**: obrigatórios (Princípio III da constituição, TDD). Em cada história, o teste vem
antes do código e precisa falhar primeiro. Todo teste de "sem conexão" tem o par com
`ServerFailure`, que precisa continuar mostrando o texto de hoje (FR-008, SC-004).

**Commits**: um por fase (Base, US1, US2, US3) e um de documentos no fim. Os arquivos entram
por nome. Nunca entram `assets/images/`, `click-seguro.html`, `demo*`, `test_visual/` nem
`devtools_options.yaml`.

Todos os caminhos partem de `click_seguro_app/`, salvo quando indicado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem depender de tarefa aberta)
- **[Story]**: história da spec (US1 a US3)

---

## Phase 1: Setup

**Purpose**: texto novo nos dois idiomas.

- [X] T001 Adicionar `commonOfflineBannerShort = 'common_offline_banner_short'` em `lib/core/i18n/app_strings.dart`, com "Você está sem internet." em `assets/translations/pt-BR.json` e "You are offline." em `assets/translations/en-US.json` (logo abaixo de `common_offline_banner`)

---

## Phase 2: Foundational (Base)

**Purpose**: a regra única (R2, R3) e a migração de todas as chamadas, **sem mudar** o que as telas já corretas mostram.

**⚠️ CRITICAL**: termine esta fase antes das histórias.

- [X] T002 [P] Escrever `test/core/errors/failure_message_test.dart`: `messageKeyOr('x')` devolve `error_connection` para `ConnectionFailure()`, `'x'` para `ServerFailure()`, `UnauthorizedFailure()` e `null`
- [X] T003 [P] Criar `lib/core/errors/failure_message.dart` com `extension FailureMessageKey on Failure?` e `String messageKeyOr(String fallbackKey)` (research R3: `this is ConnectionFailure ? this!.message : fallbackKey`), com comentário de uma linha, e exportar em `lib/core/errors/errors.dart`
- [X] T004 Atualizar `test/core/widgets/safe_states_test.dart` para a nova assinatura do `SafeErrorState` (contrato de UI): com `failure: ConnectionFailure()` → ilustração `stateOffline` e "Sem conexão com a internet. Verifique sua rede." mesmo com `message` próprio; com `failure: ServerFailure()` e `message: 'Texto da tela'` → `stateError` e "Texto da tela"; com `ServerFailure()` sem `message` → `stateError` e o texto da falha; com `failure: null` sem `message` → `stateError` e `error_generic`; "Tentar novamente" chama `onRetry` em todos
- [X] T005 Mudar `lib/core/widgets/safe_error_state.dart`: parâmetros `required Failure? failure`, `String? message`, `required VoidCallback onRetry`; `offline = failure is ConnectionFailure`; texto = offline ? `failure.message.tr()` : `message ?? (failure?.message ?? AppStrings.errorGeneric).tr()`. Remover a comparação de texto e reescrever o comentário da classe
- [X] T006 Migrar as chamadas que já passam a falha (comportamento igual), trocando `message: (x?.message ?? AppStrings.errorGeneric).tr()` ou `message: failure.message.tr()` por `failure: x`:
  - `lib/modules/assistant/presentation/widgets/assistant_history_tab.dart`
  - `lib/modules/help/presentation/pages/contact_form_page.dart` e `help_page.dart`
  - `lib/modules/news/presentation/pages/news_detail_page.dart`, `news_home_page.dart`, `user_news_list_page.dart`, `reels_page.dart`
  - `lib/modules/profile/presentation/pages/achievements_page.dart` (as duas), `profile_edit_page.dart`, `profile_page.dart`
- [X] T007 Migrar `lib/modules/activities/presentation/pages/activities_dashboard_page.dart` e `lesson_page.dart` para `SafeErrorState(failure: null, message: AppStrings.activitiesErrorTitle.tr(), …)` por enquanto (a falha entra na US1), e os exemplos de `lib/style_guide/style_guide.dart` (um com `ConnectionFailure()`, um com `message`)
- [X] T008 [P] Escrever em `test/core/widgets/safe_states_test.dart` (grupo da faixa): `SafeOfflineBanner()` mostra `common_offline_banner`; `SafeOfflineBanner(showsSavedContent: false)` mostra `common_offline_banner_short`; os dois com `liveRegion`
- [X] T009 Adicionar `final bool showsSavedContent` (padrão `true`) em `lib/core/widgets/safe_offline_banner.dart`, escolhendo entre `commonOfflineBanner` e `commonOfflineBannerShort`
- [X] T010 Acessibilidade do estado de erro (FR-012): em `test/core/widgets/safe_states_test.dart`, conferir que a frase do `SafeErrorState` (conexão e servidor) fica num nó com `liveRegion`; depois envolver o texto da mensagem em `Semantics(liveRegion: true)` em `lib/core/widgets/safe_state_layout.dart` (vale também para o vazio, que aparece no lugar da lista do mesmo jeito)
- [X] T011 Rodar `flutter analyze` e `flutter test test/core test/modules/news test/modules/profile test/modules/help test/modules/assistant`: tudo verde sem mudar os testes das telas

**Checkpoint**: regra única no `core`, telas já corretas iguais. **Commit**: `refactor(027): estado de erro decide pela falha, não pelo texto`.

---

## Phase 3: User Story 1 - Tela sem nada para mostrar avisa sempre do mesmo jeito (Priority: P1) 🎯 MVP

**Goal**: Atividades e Lição mostram a nuvem com "Sem conexão…"; nos Reels a frase fica legível.

**Independent Test**: modo avião em Atividades, uma lição e Reels: mesmo desenho, mesma frase, mesmo botão (quickstart passos 1 a 5).

### Tests for User Story 1 ⚠️

- [X] T012 [P] [US1] Em `test/modules/activities/presentation/pages/activities_dashboard_page_test.dart`: com o repositório falso devolvendo `ConnectionFailure` → `stateOffline` e "Sem conexão…"; com `ServerFailure` → `stateError` e "Não foi possível carregar as atividades"
- [X] T013 [P] [US1] Em `test/modules/activities/presentation/controller/lesson_controller_test.dart`: `failure` guarda a falha de `load` (`ConnectionFailure`) e volta a `null` na carga seguinte; com `ModuleNotFoundFailure` o estado é `empty` (como hoje)
- [X] T014 [P] [US1] Em `test/modules/activities/presentation/pages/lesson_page_test.dart`: carregar com `ConnectionFailure` → `stateOffline` e "Sem conexão…"; com `ServerFailure` → `stateError` e "Não foi possível carregar as atividades"
- [X] T015 [P] [US1] Em `test/modules/news/presentation/pages/reels_page_test.dart`: com `ConnectionFailure`, o `Text` da frase usa `textPrimaryForeground` (branco) e não `textForeground`; o mesmo no estado vazio dos Reels

### Implementation for User Story 1

- [X] T016 [US1] Em `lib/modules/activities/presentation/pages/activities_dashboard_page.dart`, passar `failure: controller.failure`, mantendo `message: AppStrings.activitiesErrorTitle.tr()`
- [X] T017 [US1] Em `lib/modules/activities/presentation/controller/lesson_controller.dart`, guardar `Failure? _failure` (getter `failure`) quando `_load` falha com algo que não seja `ModuleNotFoundFailure`, e limpar ao começar uma carga (data-model)
- [X] T018 [US1] Em `lib/modules/activities/presentation/pages/lesson_page.dart`, passar `failure: controller.failure` no estado de erro, mantendo `message: AppStrings.activitiesErrorTitle.tr()`
- [X] T019 [US1] Em `lib/modules/news/presentation/pages/reels_page.dart`, fazer o `_Dark` sobrepor também a `AppPalette` (research R5): `context.colors.copyWith(textForeground: textPrimaryForeground, textMutedForeground: textPrimaryForeground com alpha ~0.72)` em `extensions`, além do `textTheme` atual; conferir que o alto contraste continua legível
- [ ] T020 [US1] Rodar `flutter test test/modules/activities test/modules/news/presentation/pages/reels_page_test.dart`: verde

**Checkpoint**: P1 entregue e testável sozinha. **Commit**: `feat(027): Atividades, Lição e Reels com o estado de sem internet`.

---

## Phase 4: User Story 2 - Ação que falha diz que o problema é a internet (Priority: P2)

**Goal**: ações e blocos parciais mostram "Sem conexão…" na falta de internet e o texto de hoje nas outras falhas.

**Independent Test**: com a tela aberta, modo avião e cada ação (quickstart passos 6 a 11).

### Tests for User Story 2 ⚠️

- [ ] T021 [P] [US2] Em `test/modules/activities/presentation/controller/lesson_controller_test.dart`: `confirm()` com `ConnectionFailure` devolve `AnswerAttempt.failed`, guarda `answerFailure` e mantém a escolha; a confirmação seguinte limpa `answerFailure`
- [ ] T022 [P] [US2] Em `test/modules/activities/presentation/pages/lesson_page_test.dart`: confirmar com `ConnectionFailure` → SnackBar "Sem conexão…"; com `ServerFailure` → "Não foi possível enviar sua resposta. Tente de novo."
- [ ] T023 [P] [US2] Em `test/modules/settings/presentation/change_password_page_test.dart`: salvar com `ConnectionFailure` → SnackBar "Sem conexão…" e campos mantidos; `ServerFailure` → `settings_password_failed` (como hoje)
- [ ] T024 [P] [US2] Em `test/modules/profile/presentation/pages/profile_edit_page_test.dart`: salvar, trocar a foto e remover a foto com `ConnectionFailure` → SnackBar "Sem conexão…"; com `ServerFailure` → os textos de hoje; `AvatarTypeFailure` continua com a mensagem dela
- [ ] T025 [P] [US2] Em `test/modules/profile/presentation/pages/profile_page_test.dart`: números e conquistas com `ConnectionFailure` → "Sem conexão…" no bloco, com o tentar de novo; `ServerFailure` → `profile_stats_failed` / `profile_achievements_failed`
- [ ] T026 [P] [US2] Em `test/modules/settings/presentation/settings_controller_test.dart`: `alertsFailure` guarda a falha do salvar e a de `AccountFailed`, e volta a `null` quando o salvar ou a carga seguinte dá certo
- [ ] T027 [P] [US2] Em `test/modules/settings/presentation/settings_page_test.dart`: mexer na chave com `ConnectionFailure` → a chave volta e a linha diz "Sem conexão…" com o tentar de novo; `ServerFailure` → `settings_alerts_failed`; conta não carregada por conexão → "Sem conexão…", por servidor → `settings_account_load_failed`
- [ ] T028 [P] [US2] Em `test/modules/news/presentation/pages/news_home_page_test.dart` (rodapé) e `reels_page_test.dart`: carregar mais com `ConnectionFailure` → "Sem conexão…" com o botão de tentar de novo; `ServerFailure` → `news_load_more_failed`
- [ ] T029 [P] [US2] Conferir em teste o que já está certo (FR-006), criando o caso só se ainda não existir: em `test/modules/authentication/presentation/pages/login_page_test.dart` e `forgot_password_page_test.dart`, `ConnectionFailure` mostra "Sem conexão…" embaixo dos campos; em `test/modules/help/presentation/pages/help_page_test.dart`, apagar contato com `ConnectionFailure` → SnackBar "Sem conexão…"; no teste da tela do Assistente (`test/modules/assistant/presentation/`), enviar com `ConnectionFailure` → "Sem conexão…" na própria tela. Salvar e curtir no detalhe já têm caso em `news_detail_page_test.dart`

### Implementation for User Story 2

- [ ] T030 [US2] Em `lib/modules/activities/presentation/controller/lesson_controller.dart`, guardar `Failure? _answerFailure` (getter `answerFailure`) no `case Left()` de `confirm()` e limpar ao começar a confirmação
- [ ] T031 [US2] Em `lib/modules/activities/presentation/pages/lesson_page.dart`, `AnswerAttempt.failed => _controller.answerFailure.messageKeyOr(AppStrings.activitiesAnswerFailed).tr()`
- [ ] T032 [P] [US2] Em `lib/modules/settings/presentation/pages/change_password_page.dart`, o ramo `_` usa `failure.messageKeyOr(AppStrings.settingsPasswordFailed).tr()`
- [ ] T033 [P] [US2] Em `lib/modules/profile/presentation/pages/profile_edit_page.dart`: salvar com `failure.messageKeyOr(AppStrings.profileEditSaveFailed)`; trocar a foto (fora o `AvatarTypeFailure`) e remover a foto com `failure.messageKeyOr(AppStrings.profilePhotoFailed)`
- [ ] T034 [P] [US2] Em `lib/modules/profile/presentation/pages/profile_page.dart` e `lib/modules/profile/presentation/widgets/achievements_section.dart`, `AreaFailed(:final failure)` com `failure.messageKeyOr(AppStrings.profileStatsFailed / profileAchievementsFailed).tr()`
- [ ] T035 [US2] Em `lib/modules/settings/presentation/controller/settings_controller.dart`, `Failure? get alertsFailure`: a falha do último salvar que falhou, senão `(_account as AccountFailed?).failure`; limpar a do salvar quando ele dá certo (data-model)
- [ ] T036 [US2] Em `lib/modules/settings/presentation/widgets/alerts_switch_tile.dart` receber `Failure? failure` e montar o subtítulo com `failure.messageKeyOr(loadFailed ? settingsAccountLoadFailed : settingsAlertsFailed)`; passar `controller.alertsFailure` em `lib/modules/settings/presentation/pages/settings_page.dart`
- [ ] T037 [US2] Em `lib/modules/news/presentation/widgets/feed_list_footer.dart`, trocar `bool failed` por `Failure? failure` e usar `failure.messageKeyOr(AppStrings.newsLoadMoreFailed)`; atualizar as chamadas em `news_home_page.dart` e `user_news_list_page.dart`
- [ ] T038 [US2] Em `lib/modules/news/presentation/pages/reels_page.dart`, o rodapé usa `controller.loadMoreFailure.messageKeyOr(AppStrings.newsLoadMoreFailed).tr()`
- [ ] T039 [US2] Rodar `flutter test test/modules/activities test/modules/settings test/modules/profile test/modules/news test/modules/authentication`: verde

**Checkpoint**: P2 entregue. **Commit**: `feat(027): ações e blocos dizem quando falta internet`.

---

## Phase 5: User Story 3 - Conteúdo guardado com a faixa azul, sem prometer o que não há (Priority: P3)

**Goal**: nos Alertas sem nada guardado a faixa diz só "Você está sem internet.".

**Independent Test**: modo avião nos Alertas com e sem alertas (quickstart passo 13).

### Tests for User Story 3 ⚠️

- [ ] T040 [P] [US3] Em `test/modules/notifications/presentation/widgets/alerts_notices_test.dart`: `showOffline` com `showsSavedContent: true` → texto longo; `false` → texto curto
- [ ] T041 [P] [US3] Em `test/modules/notifications/presentation/pages/notifications_page_test.dart`: sem conexão e lista vazia → "Você está sem internet."; com alertas → o texto longo

### Implementation for User Story 3

- [ ] T042 [US3] Em `lib/modules/notifications/presentation/widgets/alerts_notices.dart`, receber `required bool showsSavedContent` e repassar ao `SafeOfflineBanner`; em `lib/modules/notifications/presentation/pages/notifications_page.dart` passar `controller.alerts.isNotEmpty`
- [ ] T043 [US3] Rodar `flutter test test/modules/notifications`: verde

**Checkpoint**: P3 entregue. **Commit**: `feat(027): faixa curta nos Alertas sem conteúdo salvo`.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T044 Procurar sobras: `grep -rn "errorConnection.tr()" lib` (só pode sobrar no `SafeErrorState`, se sobrar) e qualquer `Failed.tr()` de ação de rede que ainda não passe por `messageKeyOr`; revisar código só usado por teste (prática do projeto)
- [ ] T045 `flutter analyze` (esperado: 1 info de base) e `flutter test` completo: verde; formatar só os arquivos tocados com `dart format`
- [ ] T046 [P] Atualizar `.specify/memory/design-system.md` (repo root): linhas "Vazio e erro" e "Sem internet" com o padrão dos três casos (tela sem conteúdo, ação/bloco, conteúdo guardado), a decisão pela falha e a variação curta da faixa (FR-014)
- [ ] T047 [P] Atualizar `.specify/memory/specification.md` (repo root): CB-001/CB-002 citando o padrão e a spec 027; subir a versão do documento
- [ ] T048 [P] Adicionar **R4 Padrão de sem internet** na Fase R de `.specify/memory/tasks.md` (repo root), em aberto até a validação
- [ ] T049 Validação no aparelho pela usuária com [quickstart.md](quickstart.md) (passos 1 a 15); ajustes viram esclarecimentos na spec
- [ ] T050 Marcar R4 como concluída, `/revisar-pr` na branch, push e PR para `develop`

---

## Dependencies & Execution Order

- **Setup (T001)** → **Base (T002–T011)** → histórias.
- **US1** depende só da Base. **US2** depende da Base; toca a `lesson_controller.dart`, a `lesson_page.dart` e a `reels_page.dart` também usadas na US1, então vem depois dela. **US3** depende só da Base (T009) e pode ir em paralelo à US2.
- Dentro de cada história: testes primeiro (precisam falhar), depois o código.

### Parallel Opportunities

- Base: T002/T003 em paralelo com T008/T009.
- US1: T012, T013, T014 e T015 em paralelo (arquivos diferentes).
- US2: os testes T021–T029 em paralelo; T032, T033 e T034 em paralelo.
- US3: T040 e T041 em paralelo; a história inteira em paralelo com a US2.
- Polimento: T046, T047 e T048 em paralelo.

### Parallel Example: User Story 1

```text
T012 activities_dashboard_page_test.dart
T013 lesson_controller_test.dart
T014 lesson_page_test.dart
T015 reels_page_test.dart
```

## Implementation Strategy

1. **MVP**: Setup + Base + US1. Já resolve as duas capturas que motivaram a feature (Atividades e Reels) e fecha a regra no `core`.
2. **Incremento 2**: US2, que tira os "Não foi possível…" das ações sem internet.
3. **Incremento 3**: US3, só os Alertas.
4. Cada fase termina com a suíte do módulo verde e um commit; a validação no aparelho é uma só, no fim (T049).
