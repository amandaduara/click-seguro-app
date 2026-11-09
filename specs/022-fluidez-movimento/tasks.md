# Tasks: Fluidez, movimento e estados de carregamento

**Input**: Design documents from `specs/022-fluidez-movimento/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/ui-components.md](contracts/ui-components.md)

**Tests**: obrigatórios pela Constituição §III (TDD) para lógica nova; widget tests para UI com
lógica condicional.

Caminhos relativos a `click_seguro_app/` salvo indicação. Ao fim de cada fase: `flutter analyze`
limpo, `flutter test` verde e o trecho correspondente do [quickstart](quickstart.md) no emulador.

## Phase 1: Setup

**Purpose**: compilar no emulador e preparar fontes e dependências.

- [x] T001 Atualizar o toolchain Android (research R14):
  - Gradle 9.3.1 em `android/gradle/wrapper/gradle-wrapper.properties`;
  - AGP 9.1.0 e Kotlin 2.4.0 em `android/settings.gradle.kts`;
  - `kotlinOptions` → `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` em
    `android/app/build.gradle.kts`;
  - validar com `flutter run -d emulator-5554`.
- [x] T002 [P] Embutir a Montserrat (research R1): baixar Regular, Medium, SemiBold, Bold e
  ExtraBold (TTF estáticos) e `OFL.txt` para `assets/fonts/montserrat/`, declarar
  `flutter.fonts` (`family: Montserrat`, pesos 400–800) em `pubspec.yaml`.
- [x] T003 [P] Adicionar `animations` e `skeletonizer` em `pubspec.yaml`
  (`flutter pub add animations skeletonizer`) e registrar as duas na tabela de stack do
  `README.md` da raiz.

---

## Phase 2: Foundational (bloqueia as histórias)

- [x] T004 [P] Teste: `AppMotion` normal (150/250/350 ms) e reduzido (zero) com a preferência e
  com `MediaQuery.disableAnimations`, em `test/core/theme/app_motion_test.dart`.
- [x] T005 Criar `AppMotion` e `AppMotionScope` conforme o
  [contrato](contracts/ui-components.md#appmotion--appmotionscope--corethemeapp_motiondart) em
  `lib/core/theme/app_motion.dart`.
- [x] T006 Envolver o `builder` do `MaterialApp` com `AppMotionScope` e
  `AnnotatedRegion<SystemUiOverlayStyle.dark>` em `lib/main.dart`; fazer o mesmo no harness
  `test/helpers/localized_app.dart`.

**Checkpoint**: tokens disponíveis; nenhuma mudança visível ainda.

---

## Phase 3: User Story 1 — Corrigir o que quebra a experiência (P1) 🎯 MVP

**Goal**: fonte da marca, feed estável e coerente, toque no botão central, semântica de botão.
**Independent Test**: roteiro 1–8 e 16 do quickstart; testes abaixo.

### Tests (US1)

- [x] T007 [P] [US1] Testes do `FeedController` em
  `test/modules/news/presentation/controller/feed_controller_test.dart`:
  - a recarga mantém `items` e `status == loaded` com `isRefreshing`;
  - uma falha na recarga mantém a lista e emite um `FeedMessage`;
  - trocar a categoria mantém a lista anterior até a resposta chegar;
  - uma mudança em `sessionStatus` dispara a recarga;
  - um `NewsInteractionChange` corrige só o item.
- [x] T008 [P] [US1] Testes do stream de interações do `NewsRepositoryImpl` em
  `test/modules/news/data/repositories/news_repository_impl_test.dart`: publica depois de
  `markAsRead`, `toggleSave` e `toggleLike` com sucesso e não publica depois de uma falha.
- [x] T009 [P] [US1] Widget tests em `test/core/widgets/safe_button_test.dart` e
  `test/core/widgets/safe_card_test.dart`:
  - `SafeButton` tem `button: true` e `enabled` coerente com `disabled`/`loading`;
  - `SafeCard` interativo é botão.
- [x] T010 [P] [US1] Widget test em
  `test/modules/shell/presentation/widgets/app_bottom_nav_test.dart`: tocar 4 dp abaixo do topo
  do círculo central chama `onSelected(AppTab.news.index)`.

### Implementation (US1)

- [x] T011 [P] [US1] Criar a entidade `NewsInteractionChange` (`newsId`, `isRead?`, `isSaved?`,
  `isLiked?`, `likes?`; `null` = não mudou) em
  `lib/modules/news/domain/entities/news_interaction_change.dart`.
- [x] T012 [US1] Acrescentar `Stream<NewsInteractionChange> get interactionChanges` ao contrato em
  `lib/modules/news/domain/repositories/news_repository.dart`; implementar no `NewsRepositoryImpl`
  (`StreamController.broadcast`, publicação só depois de sucesso) em
  `lib/modules/news/data/repositories/news_repository_impl.dart`; atualizar os fakes de teste que
  implementam o contrato.
- [x] T013 [US1] Criar `WatchNewsInteractionsUseCase` em
  `lib/modules/news/domain/usecases/watch_news_interactions_usecase.dart` e registrar em
  `lib/modules/news/news_module.dart`.
- [x] T014 [US1] `FeedController` em
  `lib/modules/news/presentation/controller/feed_controller.dart`:
  - separar a primeira carga da recarga (`isRefreshing`);
  - `Stream<FeedMessage> messages` (novo `feed_message.dart`);
  - receber `sessionStatus` e `watchInteractions` e recarregar quando o status muda;
  - corrigir o item afetado por `NewsInteractionChange`;
  - cancelar as assinaturas no `dispose`;
  - injetar as dependências em `news_module.dart`.
- [x] T015 [US1] `ReelsController` assina `watchInteractions` e corrige o Reel afetado, em
  `lib/modules/news/presentation/controller/reels_controller.dart`.
- [x] T016 [US1] `NewsHomePage` em `lib/modules/news/presentation/pages/news_home_page.dart`:
  - o refresh devolve um future que termina na recarga, sem trocar a árvore;
  - durante a troca de categoria ou busca, `AnimatedOpacity` (0,5) na lista e
    `LinearProgressIndicator` fino no topo;
  - `FeedMessage` vira um aviso rápido (snackbar).
- [x] T017 [US1] Botão central dentro dos limites (research R12): faixa transparente de 16 dp no
  topo da barra e sem `Transform.translate` em
  `lib/modules/shell/presentation/widgets/app_bottom_nav.dart`; `extendBody: true` em
  `lib/modules/shell/presentation/app_shell.dart`. Conferir no emulador que nenhuma aba tem
  conteúdo escondido atrás da barra.
- [x] T018 [P] [US1] `Semantics(button: true, enabled:)` no `SafeButton`
  (`lib/core/widgets/safe_button.dart`) e no `SafeCard` interativo
  (`lib/core/widgets/safe_card.dart`).
- [x] T019 [US1] Conferir no emulador que o texto sai em Montserrat (T002) e ajustar os pesos do
  `textTheme` em `lib/core/theme/app_theme.dart`, se algum estilo depender de um peso que não foi
  embutido.

**Checkpoint**: US1 completa e testável sozinha.

---

## Phase 4: User Story 2 — Movimento coerente e "Reduzir animações" (P1)

**Goal**: opção no app; transições de página e de abas com os tokens.
**Independent Test**: roteiro 7, 13 e 14 do quickstart.

### Tests (US2)

- [x] T020 [P] [US2] Testes do campo `reduceMotion` (padrão `false`; a chave ausente é lida como
  `false`; ida e volta no modelo) em
  `test/modules/settings/data/models/accessibility_preferences_model_test.dart`.
- [x] T021 [P] [US2] Widget test: o interruptor "Reduzir animações" na `AccessibilityPage` muda a
  preferência e persiste, em `test/modules/settings/presentation/accessibility_page_test.dart`.
- [x] T022 [P] [US2] Widget test do `TabBranchContainer`: só a aba ativa fica com `TickerMode`
  ligado e o estado das outras é preservado, em
  `test/core/routing/tab_branch_container_test.dart`.

### Implementation (US2)

- [x] T023 [US2] Acrescentar `reduceMotion` (bool, padrão `false`) em
  `lib/modules/common/accessibility/accessibility_preferences.dart` (`copyWith`, `==` e
  `hashCode`) e no modelo em `lib/modules/settings/data/models/accessibility_preferences_model.dart`
  ("preferência guardada antes desta versão é lida como `false`").
- [x] T024 [US2] Ação `setReduceMotion` no `AccessibilityController` (no módulo `settings`) e
  interruptor na `lib/modules/settings/presentation/pages/accessibility_page.dart`. Novas chaves em
  `lib/core/i18n/app_strings.dart` e `assets/translations/{pt-BR,en-US}.json`.
- [x] T025 [US2] Ligar a preferência ao `AppMotionScope(appReduceMotion:)` em `lib/main.dart`.
- [x] T026 [US2] `pageTransitionsTheme` com o `_MotionAwareTransitionsBuilder` (volta preditiva no
  Android, Cupertino no iOS, corte quando o movimento está reduzido) em
  `lib/core/theme/app_theme.dart`.
- [x] T027 [P] [US2] `appFadePage` em `lib/core/routing/app_fade_page.dart`; usar em `/onboarding`
  (`lib/core/routing/app_router.dart`) e `/login`
  (`lib/modules/authentication/presentation/routes/authentication_routes.dart`).
- [x] T028 [US2] `TabBranchContainer` (Offstage + TickerMode + FadeThroughTransition) em
  `lib/core/routing/tab_branch_container.dart`. No `lib/core/routing/app_router.dart`, trocar
  `StatefulShellRoute.indexedStack` por `StatefulShellRoute(navigatorContainerBuilder:)` com
  `pageBuilder` de esmaecimento.
- [x] T029 [US2] Trocar as durações literais de animação pelos tokens de `AppMotion` em
  `lib/core/widgets/safe_button.dart`, `safe_card.dart` e `safe_text_field.dart`,
  `lib/modules/onboarding/presentation/**`,
  `lib/modules/authentication/presentation/widgets/auth_mode_switch.dart`, e nas animações de
  Reels e do assistente.

**Checkpoint**: navegação animada; tudo some com "Reduzir animações".

---

## Phase 5: User Story 3 — Carregamento no formato do conteúdo (P2)

**Goal**: esqueletos e troca animada nas seis telas.
**Independent Test**: roteiro 15 do quickstart; testes abaixo.

### Tests (US3)

- [x] T030 [P] [US3] Widget tests do `SafeSkeleton` (lido como "Carregando", não expõe o texto de
  exemplo, estático com movimento reduzido) e do `SafeStateSwitcher`, em
  `test/core/widgets/safe_skeleton_test.dart` e `safe_state_switcher_test.dart`.

### Implementation (US3)

- [x] T031 [US3] Criar `SafeSkeleton` e `SafeStateSwitcher` conforme o contrato em
  `lib/core/widgets/`. O esqueleto usa cores do `AppPalette`, inclusive no alto contraste.
- [x] T032 [P] [US3] Dados de exemplo (`placeholder()`) para notícia, Reel, módulo, perfil e
  notificação nas extensions de apresentação de cada módulo (por exemplo
  `lib/modules/news/presentation/extensions/news_placeholders.dart`).
- [x] T033 [US3] Feed: esqueleto dos cartões e `SafeStateSwitcher` em `_content` de
  `lib/modules/news/presentation/pages/news_home_page.dart`; manter o `SlowRequestNotice`.
- [x] T034 [P] [US3] Reels: esqueleto escuro de tela cheia em
  `lib/modules/news/presentation/pages/reels_page.dart`. Tirar os efeitos colaterais do `build`
  (`_resetPages`): o descarte do `PageController` passa a acontecer por mudança de status num
  listener.
- [x] T035 [P] [US3] Painel de atividades em
  `lib/modules/activities/presentation/pages/activities_dashboard_page.dart`.
- [x] T036 [P] [US3] Perfil em `lib/modules/profile/presentation/pages/profile_page.dart`.
- [x] T037 [P] [US3] Notificações em
  `lib/modules/notifications/presentation/pages/notifications_page.dart`.
- [x] T038 [US3] Ajustar os widget tests existentes dessas telas que procuram
  `CircularProgressIndicator`/`SafeLoadingState` para o novo estado de carregamento.

**Checkpoint**: nenhuma das seis telas mostra o círculo sozinho.

---

## Phase 6: User Story 4 — Navegação que mostra de onde veio (P2)

**Goal**: prévia no detalhe, saída da splash e carrossel → Reels.
**Independent Test**: roteiro 1, 4 e 9 do quickstart.

- [x] T039 [P] [US4] Widget test: o detalhe aberto com a prévia mostra o título antes da carga
  terminar; sem a prévia, mostra o esqueleto completo. Em
  `test/modules/news/presentation/pages/news_detail_page_test.dart`.
- [x] T040 [US4] Criar `NewsDetailPreview` (`item`, `heroTag`) e ler `extra` na rota `/news/:id`
  em `lib/modules/news/presentation/routes/news_routes.dart`. Os cartões passam a prévia com a tag
  `news-image-<seção>-<id>` (`news_card.dart`, `news_home_page.dart`, `user_news_list_page.dart`).
- [x] T041 [US4] `NewsDetailPage`: cabeçalho da prévia durante o loading, esqueleto só do corpo,
  `Hero` na imagem (`news_detail_header.dart`, `news_detail_page.dart`).
- [x] T042 [US4] Splash: entrada do logo e do título (fade + escala 0,9 → 1 com `AppMotion.long`)
  em `lib/modules/splash/presentation/pages/splash_page.dart`. A saída usa o `appFadePage` do
  shell (T028).
- [x] T043 [US4] Carrossel: `precacheImage` antes do `go('/reels?start=')` em
  `lib/modules/news/presentation/widgets/reels_carousel.dart`/`news_home_page.dart`, e resposta
  de pressão no cartão.

---

## Phase 7: User Story 6 — Imagens leves (P3)

**Goal**: decodificar no tamanho, esmaecer, pré-carregar e ajustar a barra de status.
**Independent Test**: roteiro 10 do quickstart.

- [x] T044 [P] [US6] Widget test do `SafeNetworkImage` (placeholder sem URL e em erro; sem
  esmaecimento quando o carregamento é síncrono) em
  `test/core/widgets/safe_network_image_test.dart`.
- [x] T045 [US6] Criar `SafeNetworkImage` em `lib/core/widgets/safe_network_image.dart` e trocar os
  `Image.network` em `person_avatar.dart`, `news_card.dart`, `news_detail_header.dart`,
  `reels_carousel.dart`, `reel_view.dart`, `module_icon.dart`, `lesson_page.dart` e
  `account_card.dart`.
- [x] T046 [US6] Pré-carregar a imagem do Reel `index + 1` no `onPageChanged` e envolver a página
  com `AnnotatedRegion<SystemUiOverlayStyle.light>` em
  `lib/modules/news/presentation/pages/reels_page.dart`.
- [x] T047 [US6] Nos botões redondos dos Reels, trocar `Opacity` + `BackdropFilter` pela cor com
  alfa no estado desabilitado, em `lib/modules/news/presentation/widgets/reel_actions.dart`.
  Conferir também o esqueleto dos Reels: no emulador, os botões redondos saem como anéis pretos
  (visto na verificação da US4).

---

## Phase 8: User Story 5 — Toques que respondem (P3)

**Goal**: microinterações.
**Independent Test**: roteiro 10–12 do quickstart; em cada tela, conferir com "Reduzir
animações".

- [x] T048 [P] [US5] Criar `AppHaptics` em `lib/core/utils/app_haptics.dart`.
- [x] T049 [US5] `SafeButton` e `SafeCard`: pressão mínima de `AppMotion.short` e
  `AnimatedSwitcher` entre o ícone e o spinner (`lib/core/widgets/safe_button.dart`,
  `safe_card.dart`).
- [x] T050 [US5] Curtir: pulso no coração (`ReelActions`) e dois toques na imagem (`ReelView`)
  chamando o mesmo `_like` da `ReelsPage`, com `AppHaptics.selection`. O visitante continua
  vendo o convite de conta. Widget test em
  `test/modules/news/presentation/pages/reels_page_test.dart`.
- [x] T051 [P] [US5] Lição: `PageTransitionSwitcher` + `SharedAxisTransition` horizontal pelo
  sentido do índice em `lib/modules/activities/presentation/pages/lesson_page.dart`; destaque
  animado e `AppHaptics.success/error` no resultado em
  `lib/modules/activities/presentation/widgets/lesson_option_card.dart`.
- [x] T052 [P] [US5] Login: `AnimatedSize` + `AnimatedSwitcher` no campo de nome, nas regras de
  senha e nas mensagens em `lib/modules/authentication/presentation/pages/login_page.dart`; trocar
  `Icons.*` por Lucide (design system §5).
- [x] T053 [P] [US5] Onboarding: o indicador escuta o `PageController` e interpola a largura pela
  página fracionária (`onboarding_page_indicator.dart`, `onboarding_page.dart`); `AnimatedSwitcher`
  no rótulo do botão.
- [x] T054 [P] [US5] Barra inferior: cor e escala animadas na aba ativa e desfoque leve no fundo em
  `lib/modules/shell/presentation/widgets/app_bottom_nav.dart`.
- [x] T055 [P] [US5] Assistente: balão "digitando" (três pontos; estático com movimento reduzido;
  `Semantics` com a chave nova "O assistente está digitando") e entrada animada das mensagens em
  `lib/modules/assistant/presentation/pages/assistant_page.dart`; strings novas no i18n.

---

## Phase 9: Polish & Cross-Cutting

- [x] T056 Procurar durações literais restantes
  (`grep "Duration(milliseconds" lib --include=*.dart`) e trocar pelos tokens.
- [x] T057 Atualizar a §6 (Movimento) de `.specify/memory/design-system.md` com os tokens, a opção
  "Reduzir animações" e os padrões (esqueleto, fade-through, volta preditiva).
- [ ] T058 Rodar o [quickstart](quickstart.md) completo no emulador, com e sem "Reduzir
  animações", e com letra em 200% e alto contraste; registrar os achados.
- [x] T060 [P] `SafeTextField`: o preenchimento do `inputDecorationTheme` (`filled: true`) desenha um retângulo de outro tom dentro do campo arredondado (visto no login, no emulador); usar `filled: false` no `InputDecoration` interno em `lib/core/widgets/safe_text_field.dart`.
- [x] T061 [P] Chip "Todas" sai como círculo (largura mínima = altura com letra grande); conferir `lib/modules/news/presentation/widgets/category_filter_bar.dart`.
- [x] T062 [P] `SlowRequestNotice` sem margem lateral: o texto encosta nas bordas da tela; padding horizontal `AppSpacing.s5` em `lib/core/widgets/slow_request_notice.dart`.
- [ ] T059 `flutter analyze` limpo e `flutter test` verde; perfil (`--profile`) do feed e dos Reels
  sem travadas perceptíveis (SC-006).

Achados da T058 (emulador, 2026-11-09):

- [x] T063 [P] FR-019 não cumprido na primeira abertura dos Reels: o carrossel pré-carrega a
  imagem, mas a tela mostra só o esqueleto até a lista chegar (~4 s com o servidor lento). Passar o
  item tocado como `extra` de `/reels?start=` e, no esqueleto, mostrar a imagem dele
  (`Skeleton.keep` na imagem do `ReelView`), em `reels_page.dart`, `reel_view.dart`,
  `news_routes.dart` e `news_home_page.dart`.
- [x] T064 [P] Lição: a imagem da pergunta chega depois e empurra as alternativas ~580 px para
  baixo (o toque cai na imagem). Pré-carregar as imagens de todas as perguntas quando a lição
  carrega, em `lib/modules/activities/presentation/pages/lesson_page.dart`.
- [x] T065 [P] Esqueleto escuro dos Reels: o brilho usa `card` (preto) como destaque e desenha uma
  faixa preta. Destaque claro próprio no `SafeSkeleton` (`highlightColor`), usado em
  `_ReelSkeleton`.
- [x] T066 [P] Feed: ao trocar de categoria vindo de "Todas", "Nenhuma notícia nesta categoria"
  pisca enquanto a nova lista carrega (o vazio olha o filtro novo com a lista antiga). Não mostrar
  o vazio durante `isRefreshing`, em `news_home_page.dart`.
- [ ] T067 Reels com raster mediano de 14 ms e 6% dos quadros acima de 16,7 ms no emulador (feed:
  3 ms, 0%). Medir sem os `BackdropFilter` (barra e botões) e decidir.

---

## Dependencies & Execution Order

- Setup (T001–T003) → Foundational (T004–T006) → histórias.
- **US1** e **US2** (P1) dependem só da fase 2; podem correr em paralelo.
  - T014 depende de T011–T013.
  - T016 depende de T014.
- **US3** depende de US2 (os tokens no switcher) e de T014 (`isRefreshing` no feed).
- **US4** depende de US3 (o esqueleto do corpo do detalhe) e de T028 (`appFadePage` do shell).
- **US6** depende só da fase 2.
- **US5** depende de US2. T049 altera os mesmos arquivos de T018, então faça depois dela.
- Polish por último.

## Parallel Examples

- **US1**:
  - testes T007, T008, T009 e T010 juntos;
  - depois T011 ∥ T018.
- **US3**: T034, T035, T036 e T037 juntos, depois de T031 e T032.
- **US5**: T051, T052, T053, T054 e T055 juntos, depois de T048.

## Implementation Strategy

1. **MVP**: Setup, Foundational e US1. Corrige o que o usuário sente hoje (fonte, feed, toque e
   leitor de tela).
2. Incremento 2: US2 (navegação animada e a opção de reduzir).
3. Incremento 3: US3 e US4 (carregamento e continuidade).
4. Incremento 4: US6 e US5 (polimento).

Cada incremento termina com um commit, a suíte verde e verificação no emulador.
