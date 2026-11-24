---

description: "Task list for feature 005: shell de navegação e base das trilhas"
---

# Tasks: Shell de navegação e base das trilhas

**Input**: Design documents from `/specs/005-shell-navegacao-base/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/routes.md](contracts/routes.md),
[contracts/shell-api.md](contracts/shell-api.md), [quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD) e FR-022/FR-023 da spec. Todo teste é
escrito e **falha** antes da implementação. Widget tests com `pumpLocalized` (de
`click_seguro_app/test/helpers/localized_app.dart`), relógio falso do `testWidgets` (sem esperas
reais), `UserSessionService(FakeSecureStorageService())` real e `GetIt.instance.reset()` no
`tearDown` quando registrarem algo.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` abrevia `click_seguro_app/`; `mod/` abrevia
  `click_seguro_app/lib/modules/`; `tmod/` abrevia `click_seguro_app/test/modules/`.
- Textos, chaves e caminhos exatos estão no [data-model](data-model.md) e nos
  [contratos](contracts/); as tarefas citam a fonte em vez de repetir tudo.
- Valores fictícios nos testes (`Maria`, `maria@exemplo.com`, tokens `acesso-1`/`renovacao-1`).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (esperado: 258 testes verdes, 0 erros, 0 warnings, 28 infos). Se algo estiver vermelho, parar e reportar

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, chaves de navegação, tela provisória e o esqueleto dos 7 módulos com rotas.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Criar `tmod/shell/i18n_keys_test.dart` no padrão de `tmod/authentication/presentation/i18n_keys_test.dart`, com `RegExp(r"'((?:common|shell|news|notifications|activities|help|profile|settings)_[a-z0-9_]+)'")` sobre `app/lib/core/i18n/app_strings.dart`: (a) toda chave declarada existe em pt-BR e en-US com texto não vazio; (b) estão declaradas ao menos todas as chaves da tabela "Chaves de i18n" do [data-model](data-model.md#chaves-de-i18n); (c) `shell_greeting` contém `{}` nos dois idiomas; (d) os textos pt-BR de `common_try_again`, `common_empty`, `common_offline_banner`, `common_account_required_title`, `common_account_required_body`, `common_account_required_action` e `common_account_required_dismiss` são exatamente os do data-model; (e) nenhuma chave `home_placeholder_` existe em `AppStrings` nem nos JSONs (este item só passa depois da T027)
- [X] T003 [P] Criar `app/test/core/widgets/coming_soon_view_test.dart`: `ComingSoonView(title: 'Atividades')` mostra o título e "Em breve" (`common_coming_soon`), com o título como cabeçalho semântico (`Semantics(header: true)`)

### Implementação

- [X] T004 Em `app/lib/core/i18n/app_strings.dart`, criar os blocos comentados na ordem `// --- common ---`, `// --- shell ---`, `// --- news ---`, `// --- notifications ---`, `// --- activities ---`, `// --- help ---`, `// --- profile ---`, `// --- settings ---` com as constantes da tabela do [data-model](data-model.md#chaves-de-i18n) (e acrescentar os cabeçalhos `// --- splash ---` e `// --- onboarding ---` em volta das chaves que já existem) (nome da constante em lowerCamelCase da chave, ex.: `commonTryAgain = 'common_try_again'`). Acrescentar as chaves nos dois JSONs de `app/assets/translations/`, agrupadas por prefixo, com os textos pt-BR do data-model e traduções en-US equivalentes (ex.: "Try again", "Nothing here yet.", "You're offline. Showing saved content.", "Sign in to your account", "To use this feature, sign in or create an account. It's quick and free.", "Sign in or create account", "Not now", "Hi, {}", "Welcome", "Home", "Activities", "News", "Help", "Profile"). Ainda **não** remover `home_placeholder_*` (a página antiga ainda usa). Faz T002 (a)–(d) passar
- [X] T005 [P] Criar `app/lib/core/routing/navigator_keys.dart` com `final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');` e `final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();`, com dartdoc citando o [R2](research.md) e o [R4](research.md)
- [X] T006 [P] Criar `app/lib/core/widgets/coming_soon_view.dart`: `ComingSoonView({required String title})`, centralizado, ícone `LucideIcons.hourglass` 40 `AppColors.textMutedForeground`, título com `textTheme.titleMedium` cor `AppColors.secondary` em `Semantics(header: true)` e "Em breve" (`AppStrings.commonComingSoon.tr()`) com `textTheme.bodyLarge` `AppColors.textMutedForeground`; padding `AppSpacing.s6`. Faz T003 passar
- [X] T007 [P] Criar o módulo `news` em `mod/news/`: `news_module.dart` (`NewsModule implements ModuleInterface`, `registerServices` vazio, `providers` devolve `[]`); páginas provisórias em `presentation/pages/`: `news_home_page.dart` (`NewsHomePage`: `Scaffold` + `ComingSoonView(title: AppStrings.newsTitle.tr())`; o `AppTopBar` entra na T026), `reels_page.dart` (`ReelsPage({String? startNewsId})`, sem barra superior), `news_detail_page.dart` (`NewsDetailPage({required String newsId})`: `Scaffold(appBar: AppBar(title: Text(AppStrings.newsDetailTitle.tr())))` + `ComingSoonView`); `presentation/routes/news_routes.dart` com `final GoRoute newsHomeRoute` (`/home`), `final GoRoute newsReelsRoute` (`/reels`, lendo `state.uri.queryParameters['start']`) e `final List<RouteBase> newsRoutes` (`/news/:id` com `parentNavigatorKey: rootNavigatorKey`); barrel `news.dart` exportando o módulo e as rotas (ver [contracts/routes.md](contracts/routes.md))
- [X] T008 [P] Criar o módulo `notifications` em `mod/notifications/`: `NotificationsModule` (vazio), `presentation/pages/notifications_page.dart` (`NotificationsPage`, `AppBar` com `notifications_title` + `ComingSoonView`), `presentation/routes/notifications_routes.dart` (`notificationsRoutes`: `/notifications` com `parentNavigatorKey: rootNavigatorKey`) e barrel `notifications.dart`. **Não** importar `shell` (ver [R5](research.md))
- [X] T009 [P] Criar o módulo `activities` em `mod/activities/`: `ActivitiesModule` (vazio), `presentation/pages/activities_page.dart` (`ActivitiesPage`: `Scaffold` + `ComingSoonView(activities_title)`), `presentation/pages/activity_module_page.dart` (`ActivityModulePage({required String moduleId})`, `AppBar` com `activities_module_title`), `presentation/routes/activities_routes.dart` com `final GoRoute activitiesTabRoute` (`/activities`, filha `:moduleId` com `parentNavigatorKey: rootNavigatorKey`) e barrel `activities.dart`
- [X] T010 [P] Criar o módulo `help` em `mod/help/`: `HelpModule` (vazio), `presentation/pages/help_page.dart` (`HelpPage`: `Scaffold` + `ComingSoonView(help_title)`), `presentation/pages/help_contact_page.dart` (`HelpContactPage({String? contactId})`, `AppBar` com `help_contact_title`), `presentation/routes/help_routes.dart` com `final GoRoute helpTabRoute` (`/help`, filhas `contact/new` e `contact/:id` com `parentNavigatorKey: rootNavigatorKey`; declarar `contact/new` **antes** de `contact/:id`) e barrel `help.dart`
- [X] T011 [P] Criar o módulo `profile` em `mod/profile/`: `ProfileModule` (vazio), `presentation/pages/profile_page.dart` (`ProfilePage`: `Scaffold` + `ComingSoonView(profile_title)`, sem barra superior), `presentation/pages/profile_edit_page.dart` (`ProfileEditPage`, `AppBar` com `profile_edit_title`), `presentation/routes/profile_routes.dart` com `final GoRoute profileTabRoute` (`/profile`, filha `edit` com `parentNavigatorKey: rootNavigatorKey`) e barrel `profile.dart`
- [X] T012 [P] Criar o módulo `settings` em `mod/settings/`: `SettingsModule` (vazio), `presentation/pages/settings_page.dart` (`SettingsPage`, `AppBar` com `settings_title`) e `presentation/pages/settings_section_page.dart` (`SettingsSectionPage({required String titleKey})`, `AppBar` com `titleKey.tr()`), `presentation/routes/settings_routes.dart` com `settingsRoutes`: `/settings` (`parentNavigatorKey: rootNavigatorKey`) e filhas `account`, `security`, `accessibility` usando `SettingsSectionPage` com `settings_account_title`, `settings_security_title`, `settings_accessibility_title`; barrel `settings.dart`
- [X] T013 [P] Criar o esqueleto do módulo `shell` em `mod/shell/`: `shell_module.dart` (`ShellModule`, vazio) e barrel `shell.dart` exportando o módulo (os widgets entram nas histórias)

**Checkpoint**: `flutter analyze` limpo; T002 (a)–(d) e T003 verdes.

---

## Phase 3: User Story 1 - Navegar pelas abas do app (Priority: P1) 🎯 MVP

**Goal**: cinco abas com estado preservado, barras superior e inferior do wireframe, todos os caminhos do plano abrindo uma tela, e o app abrindo no Início (FR-001 a FR-008, FR-016, FR-017, FR-019, FR-021, FR-022).

**Independent Test**: entrar como visitante, tocar nas cinco abas, abrir configurações e voltar; "voltar" do aparelho em Ajuda leva ao Início (passos 1–4, 8 e 9 do [quickstart](quickstart.md)).

### Testes (escrever primeiro e ver falhar)

- [X] T014 [P] [US1] Criar `app/test/core/routing/app_router_test.dart` com `buildAppRouter(session)` (sessão de visitante) e `pumpLocalized(router:)`: para **cada** caminho da tabela de [contracts/routes.md](contracts/routes.md) exceto `/`, `/onboarding`, `/login`, `/forgot-password` (ex.: `/home`, `/activities`, `/activities/m1`, `/reels`, `/reels?start=n1`, `/help`, `/help/contact/new`, `/help/contact/c1`, `/profile`, `/profile/edit`, `/news/n1`, `/notifications`, `/settings`, `/settings/account`, `/settings/security`, `/settings/accessibility`), `router.go(caminho)` mostra o título provisório esperado e **não** mostra "Página não encontrada"; caminhos de aba mostram a barra inferior (`find.byType(AppBottomNav)`), caminhos sobre as abas não; `/nao-existe` mostra "Página não encontrada" e o botão "Voltar ao Início" leva a `/home`
- [X] T015 [P] [US1] Criar `tmod/shell/presentation/app_shell_test.dart` com `buildAppRouter` e sessão de visitante, começando em `/home`:
  - a barra inferior tem os rótulos "Início", "Atividades", "Ajuda", "Perfil" visíveis e o botão central com rótulo semântico "Notícias"; "Início" está selecionado (`Semantics(selected: true)`);
  - tocar em "Atividades" mostra a `ActivitiesPage` e a seleciona; tocar no botão central mostra a `ReelsPage`, sem `AppTopBar`;
  - estado preservado: depois de ir para "Ajuda", `find.byType(NewsHomePage, skipOffstage: false)` continua encontrando a página do Início (não foi descartada);
  - em "Ajuda", `await tester.binding.handlePopRoute()` volta para "Início"; em "Início", o mesmo pop não muda de aba;
  - cada item da barra mede pelo menos 48×48 (`tester.getSize`);
  - com `MediaQuery(textScaler: TextScaler.linear(2))`, `tester.takeException()` é nulo (sem overflow);
  - em `/reels`, `router.push('/news/n1')` abre a `NewsDetailPage` sem a barra inferior; ao voltar (`router.pop()`), a `ReelsPage` aparece de novo e o botão central continua selecionado (spec US1, cenário 5)
- [X] T016 [P] [US1] Criar `tmod/shell/presentation/app_top_bar_test.dart` com um `GoRouter` de teste (`/` → `Scaffold(body: AppTopBar(title: 'Notícias seguras'))`, `/settings` e `/notifications` → telas identificadas):
  - conectado como `Maria` → mostra "Olá, Maria" e "Notícias seguras"; visitante → "Bem-vindo"; com `subtitle: '3 notícias novas para você'` → mostra o subtítulo no lugar da saudação;
  - a saudação muda quando o `sessionStatus` muda (ex.: visitante → `saveSession` → "Olá, Maria");
  - "Configurações" (rótulo semântico) abre `/settings`; conectado, "Notificações" abre `/notifications`;
  - os dois botões medem pelo menos 48×48;
  - o subtítulo tem 14 px e o título 24 px;
  - conectado, dois toques rápidos em "Notificações" abrem uma única tela de alertas;
  - com `MediaQuery(textScaler: TextScaler.linear(2))`, `tester.takeException()` é nulo (sem overflow)
- [X] T017 [P] [US1] Substituir `app/test/widget_test.dart` pelo teste de fumaça do [R9](research.md): `SharedPreferences.setMockInitialValues({'onboarding_seen': true})`; `GetIt.instance.reset()`; registrar os módulos reais com `ModuleManager().registerModules(appModules())` (a mesma lista do `main.dart`, T024) com `GetIt.instance.allowReassignment = true` e `registerSingleton<SecureStorageService>(FakeSecureStorageService({'session': '{"status":"guest"}'}))` **antes** de resolver o `UserSessionService`; `restoreSession()`; `pumpWidget(EasyLocalization(... child: ClickSeguroApp(moduleManager:, router: buildAppRouter(session))))` (carregar traduções com `tester.runAsync`, como o `pumpLocalized`); `tester.pump(Duration(seconds: 2))` + `pumpAndSettle`; conferir o Início com "Bem-vindo" e tocar em Atividades, Notícias, Ajuda e Perfil conferindo cada tela; `tearDown` com `GetIt.instance.reset()`

### Implementação

- [X] T018 [P] [US1] Criar `app/lib/core/routing/not_found_page.dart`: `NotFoundPage`, `Scaffold` com corpo próprio centralizado: ícone `LucideIcons.searchX` 40 `textMutedForeground`, título `common_not_found_title` (`titleMedium`, `secondary`, `Semantics(header: true)`) e `SafeButton(size: compact)` "Voltar ao Início" (`common_back_home`) → `context.go('/home')`
- [X] T019 [P] [US1] Criar `mod/notifications/presentation/widgets/notification_bell_button.dart`: `NotificationBellButton({required VoidCallback onPressed})`, círculo de 48 com fundo `AppColors.input` (equivale ao `muted`), ícone `LucideIcons.bell` 20 `AppColors.secondary`, `Semantics(button: true, label: shell_notifications)` (ou `tooltip`); exportar no barrel `notifications.dart`
- [X] T020 [US1] Criar `mod/shell/presentation/widgets/app_top_bar.dart`: `AppTopBar({required String title, String? subtitle})` conforme [design system §7.11](../../.specify/memory/design-system.md): padding `fromLTRB(20, 24, 20, 12)`; à esquerda subtítulo 14/500 `textMutedForeground` (o wireframe usa 12; ver FR-016) (padrão por `ValueListenableBuilder` em `GetIt.instance<UserSessionService>().sessionStatus`: conectado com nome → `shell_greeting` com o nome; senão `shell_welcome`) e título `textTheme.titleLarge` cor `AppColors.secondary` em `Semantics(header: true)`; à direita `NotificationBellButton(onPressed: () => context.push('/notifications'))` e botão de configurações igual ao sino (ícone `LucideIcons.settings`, rótulo `shell_settings`) → `context.push('/settings')`, 8 px entre eles. Exportar no barrel `shell.dart`. Faz a T016 passar
- [X] T021 [US1] Criar `mod/shell/presentation/widgets/app_bottom_nav.dart`: `AppBottomNav({required int currentIndex, required ValueChanged<int> onSelected})` conforme [design system §7.12](../../.specify/memory/design-system.md) e a tabela de abas do [data-model](data-model.md#abas): fundo `AppColors.background` com 95% de opacidade, borda superior 1 px `AppColors.border`, `Semantics(container: true, label: shell_nav_label)`; abas comuns com ícone 20 sobre o rótulo (12 px, w500; ativo `AppColors.primary`, inativo `textMutedForeground`), área mínima 48×48, `Semantics(button: true, selected: ativo, label: rótulo)`; aba central (índice 2) com círculo 64 `AppColors.primary`, ícone `LucideIcons.newspaper` 28 branco, `AppColors.shadowPrimary`, deslocada 24 px para cima e anel de 4 px `primary` 30% quando ativa, sem rótulo visível mas com `Semantics(label: shell_tab_news)`. Centralizar os índices das abas num `enum AppTab { home, activities, news, help, profile }` no mesmo arquivo (sem números mágicos)
- [X] T022 [US1] Criar `mod/shell/presentation/app_shell.dart`: `AppShell({required StatefulNavigationShell navigationShell})`: `PopScope(canPop: navigationShell.currentIndex == AppTab.home.index, onPopInvokedWithResult: (didPop, _) { if (!didPop) navigationShell.goBranch(AppTab.home.index); })` ([R11](research.md)) envolvendo `Scaffold(body: navigationShell, bottomNavigationBar: AppBottomNav(currentIndex: navigationShell.currentIndex, onSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex)))`. Exportar `AppShell` no barrel
- [X] T023 [US1] Reescrever `app/lib/core/routing/app_router.dart` como `GoRouter buildAppRouter(UserSessionService session)` ([R3](research.md)): `navigatorKey: rootNavigatorKey`, `initialLocation: '/'`; rotas de raiz (`/` splash, `/onboarding`, `...authenticationRoutes`); `StatefulShellRoute.indexedStack(builder: (context, state, shell) => AppShell(navigationShell: shell), branches: [newsHomeRoute, activitiesTabRoute, newsReelsRoute, helpTabRoute, profileTabRoute].map((r) => StatefulShellBranch(routes: [r])))` (na ordem do `AppTab`); depois `...newsRoutes, ...notificationsRoutes, ...settingsRoutes`; `errorBuilder: (_, _) => const NotFoundPage()`. O parâmetro `session` fica para a T036. Faz a T014 passar
- [X] T024 [US1] Em `app/lib/main.dart`: registrar `CommonModule(), SettingsModule(), AuthenticationModule(), OnboardingModule(), SplashModule(), NewsModule(), NotificationsModule(), ActivitiesModule(), HelpModule(), ProfileModule(), ShellModule()` (ordem do §1.4); a lista fica numa função pública `List<ModuleInterface> appModules()` no próprio `main.dart` (usada pelo `_setup()` e pelo teste de fumaça); `_setup()` devolve também o `GoRouter` criado com `buildAppRouter(GetIt.instance<UserSessionService>())` depois do `restoreSession()`; `ClickSeguroApp({required ModuleManagerInterface moduleManager, required GoRouter router})` usa `routerConfig: router` e `scaffoldMessengerKey: rootScaffoldMessengerKey`. Faz a T015 e a T017 passarem (com a T026)
- [X] T025 [US1] Revisar o login e o splash: `context.go('/home')` em `mod/authentication/presentation/pages/login_page.dart` e o destino `home` do splash continuam válidos (agora caem na aba Início). Ajustar testes existentes que montem o `appRouter` global antigo, se houver
- [X] T026 [US1] Colocar o `AppTopBar` no topo de `NewsHomePage` (`news_title`), `ActivitiesPage` (`activities_title`) e `HelpPage` (`help_title`), com o `ComingSoonView` abaixo (`Column` + `Expanded`), dentro de `SafeArea`. `ReelsPage` e `ProfilePage` ficam sem barra superior
- [X] T027 [US1] Remover `app/lib/core/routing/home_placeholder_page.dart`, as constantes `homePlaceholder*` de `app_strings.dart` e as chaves `home_placeholder_*` dos dois JSONs; em `tmod/authentication/presentation/i18n_keys_test.dart`, trocar o padrão para `r"'(auth_[a-z_]+)'"` e o comentário. Faz T002 (e) passar

**Checkpoint**: `flutter test` verde com o teste de fumaça; app abre no Início com as cinco abas.

---

## Phase 4: User Story 2 - Convite para criar conta em ações restritas (Priority: P1)

**Goal**: verificação única para ações restritas e o convite, sem rede (FR-009 a FR-012).

**Independent Test**: como visitante, tocar no sino → convite; "Agora não" mantém a tela; "Entrar ou criar conta" → login; conectado → alertas (passos 5–7 do [quickstart](quickstart.md)).

### Testes (escrever primeiro e ver falhar)

- [X] T028 [P] [US2] Criar `tmod/shell/presentation/require_account_test.dart` com `GetIt` registrando `UserSessionService(FakeSecureStorageService())` e um `GoRouter` de teste (`/` com um botão "Ação" que chama `requireAccount(context)` e mostra "permitido" se `true`; `/login` identificado):
  - conectado → devolve `true`, sem convite;
  - visitante → convite com `common_account_required_title`, `_body`, "Entrar ou criar conta" e "Agora não"; devolve `false`;
  - sem sessão (`unauthenticated`, ex.: depois de `expire()`) → mesmo convite, `false`;
  - "Agora não" fecha e a tela continua (`find.text('Ação')`);
  - "Entrar ou criar conta" fecha e abre `/login`;
  - dois toques rápidos em "Ação" abrem **um** convite (`findsOneWidget`);
  - botões do convite medem pelo menos 48 de altura
- [X] T029 [P] [US2] Em `tmod/shell/presentation/app_top_bar_test.dart`, acrescentar: visitante toca em "Notificações" → aparece o convite e `/notifications` **não** abre; conectado continua abrindo direto

### Implementação

- [X] T030 [US2] Criar `mod/shell/presentation/widgets/account_required_sheet.dart`: `AccountRequiredSheet`, conteúdo de `showModalBottomSheet` com fundo `AppColors.card`, raio 24 em cima, padding `AppSpacing.s6`: título `common_account_required_title` (`titleMedium`, `secondary`), texto `common_account_required_body` (`bodyLarge`), `SafeButton` grande "Entrar ou criar conta" (`Navigator.pop(context, true)`) e `SafeButton(tone: ghost)` grande "Agora não" (`Navigator.pop(context, false)`), 12 px entre os botões, dentro de `SafeArea`
- [X] T031 [US2] Criar `mod/shell/presentation/require_account.dart`: `Future<bool> requireAccount(BuildContext context)` ([R5](research.md)): se `GetIt.instance<UserSessionService>().isAuthenticated` → `true`; senão, se um convite já estiver aberto (flag privada `_sheetOpen`) → `false`; senão abre `showModalBottomSheet<bool>(builder: (_) => const AccountRequiredSheet())`, e se o resultado for `true` e o `context` ainda estiver montado → `context.go('/login')`; devolve `false`. Dartdoc: usar antes de qualquer usecase de ação restrita (RN-003), nunca chama rede. Exportar no barrel. Faz a T028 passar
- [X] T032 [US2] Em `app_top_bar.dart`, trocar o `onPressed` do sino por `() async { if (await requireAccount(context) && context.mounted) context.push('/notifications'); }` (FR-012). Faz a T029 passar

**Checkpoint**: convite funcionando nos testes e no sino.

---

## Phase 5: User Story 3 - Sessão encerrada durante o uso (Priority: P2)

**Goal**: expiração mantém a tela com aviso único; saída leva ao login (FR-013, FR-014; fecha o SC-008 da feature 001).

**Independent Test**: nos testes, `expire()` numa aba mantém a tela e mostra o aviso uma vez; `logout()` leva ao login.

### Testes (escrever primeiro e ver falhar)

- [X] T033 [P] [US3] Em `app/test/core/routing/app_router_test.dart`, grupo `saída`: conectado em `/help`, `await session.logout()` + `pumpAndSettle` → tela de login; visitante em `/profile`, `logout()` → login; em `/login` com motivo `userLogout`, `router.go('/forgot-password')` **não** redireciona (caminho público); conectado em `/help`, `expire()` → continua em `/help` (o redirect não age)
- [X] T034 [P] [US3] Criar `tmod/shell/presentation/session_expired_listener_test.dart` com o app montado por `buildAppRouter` + `MaterialApp.router(scaffoldMessengerKey: rootScaffoldMessengerKey)` e sessão conectada:
  - em `/help`, `session.expire()` → continua na `HelpPage` e aparece o `SnackBar` com `error_session_expired` e a ação "Entrar" (`common_session_expired_action`);
  - tocar em "Entrar" → tela de login;
  - `expire()` duas vezes seguidas → um único `SnackBar` (`findsOneWidget`);
  - em `/settings` (navegador raiz, sobre as abas), `expire()` → continua em Configurações e o aviso aparece;
  - visitante: `logout()` não mostra o aviso de expiração

### Implementação

- [X] T035 [US3] Criar `mod/shell/presentation/widgets/session_expired_listener.dart`: `SessionExpiredListener({required Widget child})`, `StatefulWidget` que ouve `GetIt.instance<UserSessionService>().sessionStatus` (adiciona no `initState`, remove no `dispose`), guarda o último estado e, na transição `authenticated` → `unauthenticated` com `endReason == SessionEndReason.expired`, chama `rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(AppStrings.errorSessionExpired.tr()), action: SnackBarAction(label: AppStrings.commonSessionExpiredAction.tr(), onPressed: () => rootNavigatorKey.currentContext?.go('/login'))))`. No `builder` do `StatefulShellRoute` em `app_router.dart`, envolver: `SessionExpiredListener(child: AppShell(navigationShell: shell))`. Faz a T034 passar
- [X] T036 [US3] Em `buildAppRouter`, acrescentar `refreshListenable: session.sessionStatus` e `redirect` ([R4](research.md)): com `const Set<String> publicPaths = {'/', '/onboarding', '/login', '/forgot-password'}` (constante nomeada no arquivo), se `session.sessionStatus.value == UserSessionStatus.unauthenticated && session.endReason == SessionEndReason.userLogout && !publicPaths.contains(state.matchedLocation)` → `'/login'`; senão `null`. Faz a T033 passar

**Checkpoint**: reação à sessão coberta (expirar e sair).

---

## Phase 6: User Story 4 - Estados de carregando, erro, vazio e sem internet (Priority: P2)

**Goal**: quatro estados reutilizáveis com 48 dp/16 sp e no style guide (FR-015 a FR-018).

**Independent Test**: style guide mostra os quatro; nos testes, "Tentar novamente" chama a ação e os tamanhos batem (passo do style guide no [quickstart](quickstart.md)).

### Testes (escrever primeiro e ver falhar)

- [X] T037 [P] [US4] Criar `app/test/core/widgets/safe_states_test.dart` com `pumpLocalized(child:)`:
  - `SafeLoadingState()` mostra um `CircularProgressIndicator` e tem semântica "Carregando" (`common_loading`); com `message: 'Buscando notícias'` mostra o texto em ≥ 16 px;
  - `SafeErrorState(message: 'Falhou', onRetry: ...)` mostra "Falhou" e "Tentar novamente"; tocar chama `onRetry` uma vez; o botão mede ≥ 48×48; texto da mensagem ≥ 16 px;
  - `SafeEmptyState()` mostra "Nada por aqui ainda."; com `message`, `actionLabel` e `onAction`, mostra a mensagem e o botão, que chama `onAction` e mede ≥ 48×48; sem `actionLabel`, nenhum botão;
  - `SafeOfflineBanner()` mostra "Você está sem internet. Mostrando o conteúdo salvo." em ≥ 16 px dentro de uma faixa de largura total;
  - com `textScaler: TextScaler.linear(2)`, nenhum dos quatro gera exceção de overflow

### Implementação

- [X] T038 [P] [US4] Criar `app/lib/core/widgets/safe_loading_state.dart` conforme [R8](research.md): centralizado, `Semantics(liveRegion: true, label: common_loading)`, `CircularProgressIndicator(color: AppColors.primary)` e, se `message != null`, o texto com `textTheme.bodyLarge` `textMutedForeground` 12 px abaixo
- [X] T039 [P] [US4] Criar `app/lib/core/widgets/safe_error_state.dart`: centralizado, ícone `LucideIcons.circleAlert` 40 `AppColors.destructive`, mensagem `bodyLarge` `foreground` centralizada e `ConstrainedBox(minWidth: 48, minHeight: 48)` com `SafeButton(size: compact, label: common_try_again, icon: Icon(LucideIcons.rotateCcw))` → `onRetry`
- [X] T040 [P] [US4] Criar `app/lib/core/widgets/safe_empty_state.dart`: `SafeEmptyState({IconData icon = LucideIcons.inbox, String? message, String? actionLabel, VoidCallback? onAction})`, ícone 40 `textMutedForeground`, mensagem (padrão `common_empty`) `bodyLarge` centralizada e, se `actionLabel` e `onAction` vierem, botão compacto com área ≥ 48
- [X] T041 [P] [US4] Criar `app/lib/core/widgets/safe_offline_banner.dart`: faixa de largura total, fundo `AppColors.warning` 10%, padding `s4 × s3`, ícone `LucideIcons.wifiOff` 20 `AppColors.warning` e texto `common_offline_banner` (`bodyLarge`, 16 px, cor `AppColors.textForeground`), `Semantics(liveRegion: true)`
- [X] T042 [US4] Em `app/lib/style_guide/style_guide.dart`, acrescentar a seção "Estados" no mesmo padrão das outras (`_buildComponentDocumentation`), com os quatro widgets reais importados de `core/widgets` por `import '...' show SafeLoadingState, ...;` (sem colidir com as cópias locais do style guide) e o exemplo de código de cada um. Envolver o `StyleGuideApp` em `EasyLocalization` no `main()` do style guide (mesmos `supportedLocales`, `path: 'assets/translations'` e `fallbackLocale` pt-BR do `app/lib/main.dart`, com `WidgetsFlutterBinding.ensureInitialized()` e `await EasyLocalization.ensureInitialized()`), e passar `localizationsDelegates`, `supportedLocales` e `locale` ao `MaterialApp`, para que os textos padrão dos estados ("Tentar novamente", faixa de sem internet) apareçam traduzidos

**Checkpoint**: as quatro histórias verdes.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T043 Formatar só os arquivos tocados (`dart format` com os caminhos de `mod/{news,notifications,activities,help,profile,settings,shell}`, `app/lib/core/routing`, `app/lib/core/widgets`, `app/lib/main.dart`, `app/lib/core/i18n/app_strings.dart` e os testes novos), depois `flutter analyze` (sem avisos novos além dos 28 infos) e `flutter test` (todos verdes)
- [X] T044 Validar no aparelho os 10 passos do [quickstart.md](quickstart.md) e rodar o style guide no Chrome. Anotar no fim desta tarefa o resultado de cada passo. **Resultado (2026-10-04):** passos validados no aparelho pela usuária, conforme o esperado
- [X] T045 Em `.specify/memory/tasks.md`, marcar F0.7, F0.8, F0.9, F0.10 e F0.11 como `[x]` com `(specs/005-shell-navegacao-base)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro.
- **Foundational (Phase 2)**: depende da Phase 1. T002 e T003 primeiro (testes); T004 depois da T002; T005, T006 em paralelo; T007–T013 depois de T004–T006, em paralelo entre si (módulos diferentes).
- **US1 (Phase 3)**: depende da Phase 2. Testes T014–T017 em paralelo; T018, T019 em paralelo; T019 → T020; T021 → T022 → T023 → T024; T025 depois da T024; T026 depois da T020; T027 depois da T026 (as páginas antigas deixam de existir antes de remover as chaves).
- **US2 (Phase 4)**: depende da US1 (usa o `AppTopBar`).
- **US3 (Phase 5)**: depende da US1 (usa `buildAppRouter` e o `AppShell`). Independe da US2.
- **US4 (Phase 6)**: depende só da Phase 2 (i18n). Pode andar em paralelo com a US1–US3.
- **Polish (Phase 7)**: depois de todas.

### User Story Dependencies

- **US1 (P1)**: base das demais (shell e roteador).
- **US2 (P1)** e **US3 (P2)**: depois da US1; entre si, independentes (arquivos diferentes, exceto o `app_top_bar_test.dart` na US2 e o `app_router_test.dart`/`app_router.dart` na US3).
- **US4 (P2)**: independente (design system).

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Widgets → shell → roteador → `main.dart`.
- Commit ao fim de cada história.

### Parallel Opportunities

- **Phase 2:** T002 ∥ T003; T005 ∥ T006; T007 ∥ T008 ∥ T009 ∥ T010 ∥ T011 ∥ T012 ∥ T013.
- **US1:** T014 ∥ T015 ∥ T016 ∥ T017; T018 ∥ T019 ∥ T021.
- **US2:** T028 ∥ T029.
- **US3:** T033 ∥ T034.
- **US4:** T037; depois T038 ∥ T039 ∥ T040 ∥ T041; a fase inteira ∥ US1–US3.

---

## Parallel Example: Phase 2 (esqueleto)

```bash
Task: "Módulo news em click_seguro_app/lib/modules/news/"
Task: "Módulo notifications em click_seguro_app/lib/modules/notifications/"
Task: "Módulo activities em click_seguro_app/lib/modules/activities/"
Task: "Módulo help em click_seguro_app/lib/modules/help/"
Task: "Módulo profile em click_seguro_app/lib/modules/profile/"
Task: "Módulo settings em click_seguro_app/lib/modules/settings/"
```

## Parallel Example: User Story 4

```bash
Task: "SafeLoadingState em click_seguro_app/lib/core/widgets/safe_loading_state.dart"
Task: "SafeErrorState em click_seguro_app/lib/core/widgets/safe_error_state.dart"
Task: "SafeEmptyState em click_seguro_app/lib/core/widgets/safe_empty_state.dart"
Task: "SafeOfflineBanner em click_seguro_app/lib/core/widgets/safe_offline_banner.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): cinco abas, rotas e o app abrindo no Início.
3. **PARAR e VALIDAR**: teste de fumaça verde e, no aparelho, os passos 1–4, 8 e 9 do quickstart.

### Incremental Delivery

1. Setup + Foundational → esqueleto e textos.
2. US1 → navegação (MVP; a A3 já pode começar a partir daqui, usando a US4 quando chegar).
3. US2 → convite.
4. US3 → reação à sessão.
5. US4 → estados comuns (pode vir antes, em paralelo).
6. Polish → aparelho, style guide, marcar F0.7–F0.11.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [USn] mapeia a tarefa para a história da [spec](spec.md).
- Verifique que o teste falha antes de implementar.
- Testes que dependem de tempo usam o relógio falso do `testWidgets` (`tester.pump(Duration)`),
  nunca esperas reais.
- O `notifications` **não** importa o `shell` ([R5](research.md)).
- Depois desta feature, `main.dart`, `app_router.dart`, `common/` e `shell/` ficam fechados
  (plano do produto §6).
- O `dart format` em pastas inteiras reformata arquivos fora do escopo: formate só os arquivos
  tocados pela tarefa.
