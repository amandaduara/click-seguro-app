---

description: "Task list for feature 013: configurações"
---

# Tasks: Configurações

**Input**: Design documents from `/specs/013-configuracoes/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/settings-api.md](contracts/settings-api.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeHttpClientAdapter`
(`app/test/modules/common/api_client/fake_http_client_adapter.dart`) no datasource; fakes de
repository, `FakeLocalCacheService` e `FakeAppInfoService` (`app/test/fakes/`); widget tests com
`pumpLocalized` (`app/test/helpers/localized_app.dart`) e `GetIt.instance.reset()` no `tearDown`.
JSON de teste no formato real da [R0](research.md#r0-conferência-no-servidor-real-portão-de-api).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `set/` =
  `click_seguro_app/lib/modules/settings/`; `tset/` = `click_seguro_app/test/modules/settings/`;
  `auth/` = `click_seguro_app/lib/modules/authentication/`; `tauth/` =
  `click_seguro_app/test/modules/authentication/`.
- Campos, falhas e chaves exatas no [data-model](data-model.md); endpoints e rotas no
  [contrato](contracts/settings-api.md); o porquê de cada decisão no [research](research.md).
- Visual: captura do quadro "Configurações" (2026-10-14): cartão branco da conta (iniciais, nome,
  "Ver e editar seu perfil", chevron); títulos de seção 18/700; cartões brancos com borda e raio 20
  agrupando as linhas; cada linha com ícone em quadrado de fundo claro (44), título 16/700,
  subtítulo 14 muted e chevron; chave verde na linha de alertas; "Português" à direita da linha de
  idioma; botão "Sair da conta" com contorno e texto `destructive` e ícone `log-out`, e a frase
  dos contatos centralizada embaixo. Cores sempre por `context.colors` (F0.6).
- Valores fictícios nos testes (`Maria da Silva`, `maria@exemplo.com`, senhas `Senha@123` e
  `NovaSenha@456`).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, `git fetch` e conferir se a `develop` tem algo novo (se tiver, parar e avisar: o outro desenvolvedor pode mexer em `authentication`, `shell` ou `notifications`); rodar `flutter analyze` e `flutter test` e anotar a linha de base (testes, erros, warnings, infos) no fim desta tarefa. **Linha de base (2026-10-15):** a `develop` trouxe só a PR #17 (constituição 1.2.0, docs), mesclada na branch; `flutter test` 1205 verdes; `flutter analyze` 28 issues, todos `info`
- [X] T002 Adicionar `package_info_plus` com `flutter pub add package_info_plus` em `app/pubspec.yaml` (versão atual compatível com o Flutter 3.47.5) e conferir `flutter pub get`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, política de senha compartilhada, versão do app e a camada de dados do
`settings`, que todas as histórias usam.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T003 [P] Criar `app/test/modules/common/validators/password_policy_test.dart` com os casos de regra hoje em `tauth/domain/validators/credentials_validator_test.dart` (8 e 64 caracteres ok, 7 e 65 não; sem maiúscula, minúscula, número ou especial; espaços contam) para `PasswordPolicy.rulesMet` e `PasswordPolicy.isValid`
- [X] T004 [P] Criar `app/test/modules/common/services/app_info_service_test.dart`: `PackageInfoAppInfoService` com `PackageInfo.setMockInitialValues(version: '1.0.0', …)` devolve `'1.0.0'`; e `app/test/fakes/fake_app_info_service.dart` (`version` configurável, padrão `'1.0.0'`)
- [X] T005 [P] Criar `tset/fakes/settings_fixtures.dart` (`accountJson({String name = 'Maria da Silva', String? avatarUrl, bool receiveNotifications = true})` no formato do `GET /users/me` da R0 com `email`, `phone: null` e `role: 'USER'`; `tokensJson()` com `accessToken`/`refreshToken`) e `tset/data/account_remote_data_source_impl_test.dart` (padrão de `app/test/modules/profile/data/datasources/profile_remote_data_source_impl_test.dart`): `getAccount` → `GET /users/me`; `setReceiveAlerts(false)` → `PATCH /users/me` com **só** `{'receiveNotifications': false}`; `changePassword` → `PATCH /users/me/change-password` com `{currentPassword, newPassword}`; `login(email, password)` → `POST /auth/app/login` sem `Authorization` e devolve o par; 401 `INVALID_CREDENTIALS` e 409 `USER_NEW_PASSWORD_EQUALS_OLD` sobem como `ApiException` com o `errorCode`
- [X] T006 [P] Criar `tset/data/account_repository_impl_test.dart` com `FakeAccountRemoteDataSource` (T011) e `UserSessionService(FakeSecureStorageService())` conectada como `maria@exemplo.com`/"Maria da Silva": `getAccount` e `setReceiveAlerts` → `Right`; `changePassword` ok → chama `login('maria@exemplo.com', nova)` e `saveSession` com o par novo, mantendo e-mail e nome; login depois da troca falha → `Left(PasswordChangedReloginFailure)`; 401 `INVALID_CREDENTIALS` → `WrongCurrentPasswordFailure` **sem** login e com a sessão intacta; 409 → `SamePasswordFailure`; 400 → `ServerFailure`; conexão → `ConnectionFailure`
- [X] T007 [P] Criar `tset/data/language_repository_impl_test.dart` com `FakeLocalCacheService` (`app/test/fakes/fake_local_cache_service.dart`): sem registro → `device`; grava e lê `portuguese`/`english`/`device` na chave `language_choice`; valor desconhecido ou leitura que lança → `device`; gravação que lança não sobe

### Implementação

- [X] T008 Mover a política de senha: criar `app/lib/modules/common/validators/password_policy.dart` com `enum PasswordRule { length, uppercase, lowercase, digit, special }` (de `auth/domain/enums/password_rule.dart`, que é apagado) e `abstract final class PasswordPolicy` (`minLength = 8`, `maxLength = 64`, `rulesMet`, `isValid`, com o corpo de `CredentialsValidator.passwordRules`); o `CredentialsValidator`, o `EvaluatePasswordUseCase`, os controllers e a extension do `authentication` passam a usar o `PasswordPolicy` (só imports e a chamada, sem mudar comportamento). Mover `auth/presentation/widgets/password_rules_list.dart` para `app/lib/core/widgets/password_rules_list.dart` e ajustar os imports em `auth/presentation/pages/`. Ajustar os imports dos testes em `tauth/`. Faz a T003 passar e mantém toda a suíte de `tauth/` verde
- [X] T009 Criar `app/lib/modules/common/services/app_info_service.dart` (`abstract class AppInfoService { Future<String> version(); }` e `PackageInfoAppInfoService` com `package_info_plus`; nunca lança: falha → `''`) e registrar como lazy singleton em `app/lib/modules/common/common_module.dart`. Faz a T004 passar
- [X] T010 [P] Chaves de i18n: em `app/lib/core/i18n/app_strings.dart`, bloco `// --- settings ---`, as constantes da tabela "Chaves de i18n" do [data-model](data-model.md#chaves-de-i18n-novas-prefixo-settings_-inglês-equivalente) (inclusive `settings_password_relogin` = "Senha alterada. Entre de novo com a nova senha.", os parágrafos `settings_privacy_*` — conta e atividade no serviço; contatos de emergência e fotos só neste celular; idioma e acessibilidade no aparelho; nada é vendido nem usado para propaganda — e `settings_about_*` — "O SafeNews ajuda você a reconhecer golpes digitais com notícias e atividades." e "Trabalho de Conclusão de Curso"); textos em `app/assets/translations/pt-BR.json` e `en-US.json`. As chaves já são cobertas por `app/test/modules/shell/i18n_keys_test.dart` (a expressão inclui `settings_`)
- [X] T011 Criar em `set/`: `domain/entities/account_summary_entity.dart` (`name`, `avatarUrl?`, `receiveNotifications`, `initials` = primeira e última palavra), `domain/entities/language_choice.dart`, `domain/failures/settings_failures.dart` (`WrongCurrentPasswordFailure`, `SamePasswordFailure`, `PasswordChangedReloginFailure`, `WeakPasswordFailure`; mensagens = chaves do data-model), `data/models/account_summary_model.dart` (`avatarUrl` vazio → `null`; `receiveNotifications` ausente → `true`), `data/datasources/account_remote_data_source.dart` + `_impl.dart` (caminhos em constantes `mePath`, `changePasswordPath`, `loginPath = '/auth/app/login'`; o login usa `requiresAuth: false`), `domain/repositories/account_repository.dart` + `data/repositories/account_repository_impl.dart` (`_guard` com falhas por `errorCode` em constantes `invalidCredentialsCode` e `samePasswordCode`; depois do 204, `login` + `UserSessionService.saveSession(accessToken, refreshToken, email: session.email!, userName: session.userName)`; falha no login → `PasswordChangedReloginFailure`), `data/datasources/language_local_data_source.dart` + `_impl.dart` e `domain/repositories/language_repository.dart` + `data/repositories/language_repository_impl.dart` (chave `language_choice`, valor `{'choice': 'device'|'portuguese'|'english'}`). Criar `tset/fakes/fake_account_remote_data_source.dart`, `tset/fakes/fake_account_repository.dart` (filas de respostas e `Completer` opcional por método, como `FakeProfileRepository`) e `tset/fakes/fake_language_repository.dart`. Registrar datasources e repositories em `set/settings_module.dart`. Faz a T005, a T006 e a T007 passar

**Checkpoint**: `flutter analyze` limpo; testes de política, versão, datasource e repositories verdes; suíte do `authentication` verde.

---

## Phase 3: User Story 1 - Ver as configurações e sair da conta (Priority: P1) 🎯 MVP

**Goal**: tela do quadro com cartão, seções, "Sair da conta" direto e convite no link direto;
engrenagem só com conta (FR-001 a FR-007, FR-024, FR-025).

**Independent Test**: passos 1–4, 16 e 17 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T012 [P] [US1] Criar `tset/domain/settings_usecases_test.dart`: `GetAccountUseCase` repassa; `LogoutUseCase` chama `UserSessionService.logout()` e deixa `endReason == userLogout`; `GetAppVersionUseCase` devolve a versão do `FakeAppInfoService`
- [X] T013 [P] [US1] Criar `tset/presentation/settings_controller_test.dart` (fábrica `tset/fakes/settings_controller_factory.dart` com usecases reais sobre os fakes): `load()` → `account` `loading` → `loaded`, `appVersion` `'1.0.0'`, `language` lida; conta falha → `failed` e `fallbackName` = nome da sessão; `retryAccount()` recarrega só a conta; `logout()` encerra a sessão; `dispose` durante a carga não lança
- [X] T014 [P] [US1] Criar `tset/presentation/settings_page_test.dart` com `GetIt` (sessão conectada, dependências registradas por `registerSettingsDependencies(GetIt, {FakeAccountRepository?, FakeLanguageRepository?, FakeAppInfoService?})`, criado aqui em `app/test/helpers/settings_dependencies.dart`) e um `GoRouter` de teste com `/settings` (página real), `/profile`, `/profile/edit`, `/settings/security`, `/settings/accessibility`, `/settings/privacy`, `/settings/about` e `/login` identificados:
  - cartão com "MS", "Maria da Silva" e "Ver e editar seu perfil" → `/profile`;
  - títulos "Conta", "Alertas", "Leitura e aparência", "Sobre", na ordem;
  - "Dados pessoais" (com "Nome, e-mail, telefone e foto") → `/profile/edit`; "Alterar senha" → `/settings/security`; "Acessibilidade" → `/settings/accessibility`; "Privacidade" → `/settings/privacy`; "Sobre o SafeNews" com "Versão 1.0.0" → `/settings/about`;
  - "Sair da conta" e "Ao sair, seus contatos de emergência continuam guardados neste celular." visíveis; tocar sai na hora (sem diálogo) e chega a `/login`; toque duplo chama o logout uma vez;
  - conta com erro → cartão com o nome da sessão e as iniciais; as linhas continuam navegando;
  - voltar de `/profile/edit` recarrega o cartão (o fake conta as chamadas);
  - visitante abrindo `/settings` → "Entre na sua conta" e "Entrar ou criar conta" → `/login`, nenhum pedido ao repository; sessão expirando com a tela aberta troca para o convite;
  - fonte 2× num celular (1080×2340, dpr 3) → `tester.takeException()` nulo; linhas com ≥ 48 de altura
- [X] T015 [P] [US1] Em `app/test/modules/shell/presentation/app_top_bar_test.dart`, acrescentar: visitante e desconectado → sem o botão "Configurações"; conectada → com o botão. Em `app/test/modules/profile/presentation/pages/profile_page_test.dart`, acrescentar: visitante → sem a engrenagem (tooltip "Configurações"); trocar o teste da engrenagem para conta (já é)

### Implementação

- [X] T016 [US1] Criar os usecases `set/domain/usecases/get_account_usecase.dart`, `logout_usecase.dart` (recebe `UserSessionService`) e `get_app_version_usecase.dart` (recebe `AppInfoService`); `set/presentation/controller/account_state.dart` (`sealed class AccountState` com `AccountLoading`, `AccountLoaded(account)`, `AccountFailed(failure)`) e `set/presentation/controller/settings_controller.dart` conforme o [data-model](data-model.md#controllers) (por enquanto sem a chave de alertas e sem salvar idioma). Registrar usecases e `registerFactory(SettingsController)` em `set/settings_module.dart`. Faz a T012 e a T013 passar
- [X] T017 [US1] Criar os widgets em `set/presentation/widgets/`: `settings_section.dart` (título 18/700 com `Semantics(header)` e cartão branco com borda, raio 20, linhas separadas por divisor), `settings_tile.dart` (ícone em quadrado 44 com fundo da cor a 12%, título 16/700, subtítulo 14 muted, `trailing` opcional — texto à direita ou chevron —, `InkWell`, altura mínima 64, `MergeSemantics` com `button`), `account_card.dart` (avatar 56 com foto ou iniciais em fundo `input`, nome 18/800 até 2 linhas, "Ver e editar seu perfil" 14 muted, chevron) e `settings_guest_invite.dart` (`SafeEmptyState`-like com ícone `user-round`, "Entre na sua conta", "As configurações são da sua conta." e `SafeButton` "Entrar ou criar conta" → `context.go('/login')`). Cores por `context.colors`
- [X] T018 [US1] Reescrever `set/presentation/pages/settings_page.dart`: `ValueListenableBuilder` em `sessionStatus` (sem conta → `SettingsGuestInvite`); com conta, `ChangeNotifierProvider` do `SettingsController` (`load()` na criação); `AppBar` "Configurações"; `ListView` com o cartão, as seções e as linhas do [contrato §2](contracts/settings-api.md#2-rotas) (a linha de alertas e a de idioma entram nas US3/US4; por ora a seção Alertas e a linha Idioma ficam de fora), o botão "Sair da conta" (`SafeButton` `ghost` com borda e texto `destructive`, ícone `LucideIcons.logOut`, ignora toque durante a saída) e a frase dos contatos. "Dados pessoais" faz `await context.push('/profile/edit')` e depois `retryAccount()`. Faz a T014 passar (sem os casos de alertas e idioma)
- [X] T019 [US1] Em `set/presentation/routes/settings_routes.dart`: remover `account`; `security` passa a usar um provisório até a US2; acrescentar `privacy` e `about` (provisórios até a US5). Em `app/test/core/routing/app_router_test.dart`, trocar `'/settings/account'` pelas rotas novas e ajustar o teste da linha 118 (abrir `/settings/security`)
- [X] T020 [US1] Engrenagem só com conta: em `app/lib/modules/shell/presentation/widgets/app_top_bar.dart`, o `_SettingsButton` só aparece com `sessionStatus == authenticated` (dentro do `ListenableBuilder` que já existe); em `app/lib/modules/profile/presentation/pages/profile_page.dart`, o `_Header` recebe `showSettings` e o visitante não vê a engrenagem. Faz a T015 passar
- [X] T021 [US1] Usar o `registerSettingsDependencies(GetIt, {FakeAccountRepository?, FakeLanguageRepository?, FakeAppInfoService?})` (criado na T014 em `app/test/helpers/settings_dependencies.dart`) em `app/test/core/routing/app_router_test.dart`; em `app/test/widget_test.dart`, registrar `AccountRepository` e `AppInfoService` falsos como os outros. A suíte inteira precisa continuar verde

**Checkpoint**: `flutter test` verde. Commit da Base + US1.

---

## Phase 4: User Story 2 - Trocar a senha (Priority: P1)

**Goal**: troca com regras ao vivo, erros por campo, sessão mantida (FR-008 a FR-015, CB-013, R0).

**Independent Test**: passos 8–12 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T022 [P] [US2] Criar `tset/domain/change_password_usecase_test.dart` com `FakeAccountRepository`: nova senha que não cumpre o `PasswordPolicy` → `Left(WeakPasswordFailure)` sem chamar o repository; válida → repassa `currentPassword`/`newPassword` sem `trim`; falhas do repository repassadas
- [X] T023 [P] [US2] Criar `tset/presentation/change_password_controller_test.dart`: `rulesMet` recalculado ao digitar; `canSave` só com os três preenchidos e fora do envio; campos vazios → `required` em cada um; regras faltando → `rulesNotMet`; confirmação diferente → `mismatch`, sem chamar o usecase; `WrongCurrentPasswordFailure` → erro `wrongCurrent` na senha atual e a nova mantida; `SamePasswordFailure` → `samePassword` na nova; `ServerFailure` → `failed` com `saveFailure`; `PasswordChangedReloginFailure` → `failed` com essa falha; sucesso → `saved`; editar um campo limpa o erro dele; `hasInput`
- [X] T024 [P] [US2] Criar `tset/presentation/change_password_page_test.dart` (rota `/settings/security` sobre um `/settings` identificado): três campos com "Mostrar senha" (≥ 48) que alterna o texto oculto; lista de regras do `PasswordRulesList` marcando ao digitar; "As senhas não são iguais."; senha atual errada → "Senha atual incorreta" no campo e a sessão continua `authenticated`; nova igual → "A nova senha precisa ser diferente da atual."; falha genérica → `SnackBar` "Não foi possível trocar a senha. Tente de novo mais tarde." e campos mantidos; sucesso → `SnackBar` "Senha alterada" e volta a `/settings`; `PasswordChangedReloginFailure` → sessão encerrada (`logout`) e `SnackBar` "Senha alterada. Entre de novo com a nova senha." no `rootScaffoldMessengerKey`; voltar com texto → "Descartar alterações?" ("Continuar editando" fica; "Descartar" sai); fonte 2× sem estouro

### Implementação

- [X] T025 [US2] Criar `set/domain/usecases/change_password_usecase.dart` (valida com `PasswordPolicy.isValid` antes; inválida → `Left(WeakPasswordFailure())` sem pedido — proteção: o controller já valida antes, então a tela nunca a mostra). Registrar em `set/settings_module.dart`. Faz a T022 passar
- [X] T026 [US2] Criar `set/presentation/controller/change_password_controller.dart` conforme o [data-model](data-model.md#controllers) (`PasswordFieldError { required, rulesNotMet, mismatch, wrongCurrent, samePassword }`, `ChangePasswordResult { saved, invalid, failed }`, campos de texto, visibilidade de cada campo). Em `PasswordChangedReloginFailure`, o controller chama o `LogoutUseCase`. Registrar a factory em `set/settings_module.dart`. Faz a T023 passar
- [X] T027 [US2] Criar `set/presentation/pages/change_password_page.dart` (`SafeTextField` com `obscureText` e `rightIcon` olho `eye`/`eye-off` com rótulo, `PasswordRulesList` do `core` com as chaves `auth_rule_*`, `SafeButton` "Salvar" com `loading`, `PopScope` com o diálogo de descarte, `SnackBar`s; o aviso de nova entrada vai pelo `rootScaffoldMessengerKey` de `app/lib/core/routing/navigator_keys.dart`, porque a tela some ao sair da sessão) e ligar à rota `security`. Faz a T024 passar

**Checkpoint**: testes da US2 e suíte verdes. Commit da US2.

---

## Phase 5: User Story 3 - Ligar ou desligar os alertas (Priority: P2)

**Goal**: chave otimista com volta em falha; aviso dos Alertas abre as Configurações (FR-016 a FR-018).

**Independent Test**: passos 5–7 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T028 [P] [US3] Em `tset/domain/settings_usecases_test.dart`, acrescentar `SetReceiveAlertsUseCase` repassando valor e falha. Em `tset/presentation/settings_controller_test.dart`, acrescentar: `setReceiveAlerts(false)` muda `account` na hora e `isSavingAlerts` durante o envio (segurar com `Completer`); falha → volta a `true` e devolve a falha; toque durante o envio é ignorado; sem conta carregada → não faz nada
- [X] T029 [P] [US3] Em `tset/presentation/settings_page_test.dart`, acrescentar: seção "Alertas" com "Alertas de notícias novas" e "Avisamos quando sair uma notícia de golpe"; chave com o valor da conta e `Semantics` de alternância; tocar desliga na hora; falha → volta e `SnackBar` "Não foi possível mudar os alertas. Tente de novo."; conta com erro → chave desabilitada com "Não foi possível carregar" e "Tentar novamente"
- [X] T030 [P] [US3] Em `app/test/modules/notifications/presentation/pages/notifications_page_test.dart` (ou o teste de `alerts_notices`), trocar o destino do botão do aviso de alertas desligados para `/settings` e acrescentar: ao voltar, a tela confere de novo (o fake conta as chamadas de `checkNew`)

### Implementação

- [X] T031 [US3] Criar `set/domain/usecases/set_receive_alerts_usecase.dart`; no `SettingsController`, `isSavingAlerts` e `setReceiveAlerts(bool) → Failure?` (otimista, volta em falha). Registrar em `set/settings_module.dart`. Faz a T028 passar
- [X] T032 [US3] Criar `set/presentation/widgets/alerts_switch_tile.dart` (mesmo visual do `SettingsTile` com `Switch` verde `success`; desabilitado durante o envio e sem conta; estado de falha com "Não foi possível carregar" e `TextButton` "Tentar novamente" ≥ 48) e a seção "Alertas" na `settings_page.dart`. Faz a T029 passar
- [X] T033 [US3] Em `app/lib/modules/notifications/presentation/widgets/alerts_notices.dart`, a constante vira `settingsRoute = '/settings'` e o botão chama um `onOpenSettings`; em `notifications_page.dart`, `onOpenSettings` faz `await context.push('/settings')` e depois `checkNew(force: true)`. Texto do botão: `notifications_disabled_action` passa a "Ligar nas Configurações" / "Turn on in Settings". Faz a T030 passar

**Checkpoint**: testes da US3 e suíte verdes. Commit da US3.

---

## Phase 6: User Story 4 - Escolher o idioma (Priority: P2)

**Goal**: Idioma do celular / Português / English, troca na hora e guarda (FR-019 a FR-021, RF-042).

**Independent Test**: passos 13–14 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T034 [P] [US4] Em `tset/domain/settings_usecases_test.dart`, acrescentar `GetLanguageUseCase` e `SaveLanguageUseCase`. Em `tset/presentation/settings_controller_test.dart`, acrescentar: `setLanguage(english)` guarda e atualiza `language`
- [X] T035 [P] [US4] Em `tset/presentation/settings_page_test.dart`, acrescentar (com `pumpLocalized`, que usa o `EasyLocalization` real): linha "Idioma" com "Idioma do celular" à direita quando `device`; tocar abre a folha com "Idioma do celular", "Português" e "English" (≥ 56 cada, atual marcada); "English" → a tela passa a "Settings" e a linha mostra "English", e o fake guardou `english`; depois "Idioma do celular"/"Phone language" → volta ao pt-BR (idioma do aparelho no teste) e o fake guardou `device`

### Implementação

- [X] T036 [US4] Criar `set/domain/usecases/get_language_usecase.dart` e `save_language_usecase.dart`; no `SettingsController`, `setLanguage(LanguageChoice)`. Registrar em `set/settings_module.dart`. Faz a T034 passar
- [X] T037 [US4] Criar `set/presentation/widgets/language_sheet.dart` (`showLanguageSheet(context, current) → LanguageChoice?`, mesmo padrão da folha de foto da B7, `ListTile` de 56 com `check` na atual) e a extension `set/presentation/extensions/language_choice_presentation.dart` (rótulo de cada opção; "Português"/"English" fixos no próprio idioma; `Locale` de cada uma); na `settings_page.dart`, a seção "Leitura e aparência" ganha a linha "Idioma" e, ao escolher: `controller.setLanguage(choice)` e `context.setLocale(...)`; para `device`, `context.setLocale(<locale suportado do aparelho, pelo `context.deviceLocale`>)` seguido de `context.deleteSaveLocale()` ([R5](research.md#r5-idioma)). Faz a T035 passar. **Acréscimo (2026-10-15):** `app/lib/core/widgets/locale_rebuilder.dart` (com teste), no `builder` do `MaterialApp` em `app/lib/main.dart` e no `pumpLocalized`: os textos usam `'chave'.tr()`, que não reconstrói telas `const` nem as de baixo da pilha ao trocar o idioma

**Checkpoint**: testes da US4 e suíte verdes. Commit da US4.

---

## Phase 7: User Story 5 - Privacidade e Sobre (Priority: P3)

**Goal**: as duas telas de texto, com a versão (FR-022, FR-023).

**Independent Test**: passo 15 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T038 [P] [US5] Criar `tset/presentation/privacy_and_about_pages_test.dart`: Privacidade com título e os parágrafos (contatos de emergência só no celular); Sobre com "SafeNews", o objetivo, "Versão 1.0.0" do `FakeAppInfoService` e "Trabalho de Conclusão de Curso"; fonte 2× sem estouro (texto rolável)

### Implementação

- [X] T039 [US5] Criar `set/presentation/pages/privacy_page.dart` e `set/presentation/pages/about_page.dart` (`AppBar`, `ListView` com títulos `Semantics(header)` e parágrafos 16; Sobre lê a versão pelo `GetAppVersionUseCase` via `FutureBuilder`), ligar às rotas `privacy` e `about` e apagar o que sobrar de provisório (exceto `accessibility`, que é da B9). Faz a T038 passar

**Checkpoint**: testes da US5 e suíte verdes. Commit da US5.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T040 Formatar só os arquivos tocados (`dart format` com os caminhos), `flutter analyze` (sem avisos novos em relação à T001) e `flutter test` (todos verdes). Revisar o código de produção em busca de código morto ou só de teste (ex.: `SettingsSectionPage` sem uso fora da acessibilidade) e anotar o resultado. **Resultado (2026-10-15):** `flutter test` 1312 verdes (base 1205 + 107); `flutter analyze` 28 issues, todos `info`, iguais à base. Revisão: saíram o getter `AccountSummaryEntity.initials` (a página usa `initialsOf`) e as chaves `settings_account_title`/`settings_security_title` das rotas provisórias removidas; `SettingsSectionPage` fica só para a acessibilidade (B9)
- [X] T041 Validar no aparelho os 18 passos do [quickstart.md](quickstart.md#2-no-aparelho) com uma conta da usuária e anotar o resultado. **Resultado (2026-10-15):** validado pela usuária no aparelho, sem ajustes
- [X] T042 Em `.specify/memory/tasks.md`, marcar B8 como `[x]` com `(specs/013-configuracoes)` e anotar: rota `/settings/account` removida; Segurança dentro de Conta; sair sem confirmação (folha de confirmação futura); visitante sem Configurações. Commit de docs; antes da PR, `git fetch` e trazer a `develop` se tiver mudado. **Resultado (2026-10-15):** `develop` sem novidades

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → histórias.
- **US1 (Phase 3)**: depois da Foundational. Cria a tela, o controller e as rotas.
- **US2 (Phase 4)**: depois da Foundational; a rota `security` existe desde a US1 (T019).
- **US3 (Phase 5)** e **US4 (Phase 6)**: depois da US1 (mesma tela e controller); entre si mexem
  nos mesmos arquivos (`settings_controller.dart`, `settings_page.dart`), então em sequência.
- **US5 (Phase 7)**: depois da US1 (rotas); independente das US2–US4.
- **Polish (Phase 8)**: depois de todas.

### Within Each User Story

- Testes (falhando) → domínio → controller → widgets/página.

### Parallel Opportunities

- **Foundational:** T003 ∥ T004 ∥ T005 ∥ T006 ∥ T007 ∥ T010; T008 ∥ T009; depois T011.
- **US1:** T012 ∥ T013 ∥ T014 ∥ T015; T016 → T017 → T018 → T019; T020 ∥ T019; T021 no fim.
- **US2:** T022 ∥ T023 ∥ T024; T025 → T026 → T027. A US2 inteira ∥ US5.
- **US3:** T028 ∥ T029 ∥ T030; T031 → T032; T033 ∥ T032.
- **US4:** T034 ∥ T035; T036 → T037.

---

## Parallel Example: Foundational (testes)

```bash
Task: "Política de senha em click_seguro_app/test/modules/common/validators/password_policy_test.dart"
Task: "Versão em click_seguro_app/test/modules/common/services/app_info_service_test.dart"
Task: "Datasource em click_seguro_app/test/modules/settings/data/account_remote_data_source_impl_test.dart"
Task: "Repository em click_seguro_app/test/modules/settings/data/account_repository_impl_test.dart"
Task: "Idioma em click_seguro_app/test/modules/settings/data/language_repository_impl_test.dart"
```

## Parallel Example: User Story 1 (testes)

```bash
Task: "Usecases em click_seguro_app/test/modules/settings/domain/settings_usecases_test.dart"
Task: "Controller em click_seguro_app/test/modules/settings/presentation/settings_controller_test.dart"
Task: "Página em click_seguro_app/test/modules/settings/presentation/settings_page_test.dart"
Task: "Engrenagem em click_seguro_app/test/modules/shell/presentation/app_top_bar_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): a tela com o cartão, as linhas e sair.
3. **PARAR e VALIDAR**: passos 1–4 e 17 do quickstart no aparelho.

### Incremental Delivery

1. Setup + Foundational → dados, política de senha e versão.
2. US1 → tela e sair (MVP).
3. US2 → troca de senha.
4. US3 → chave de alertas.
5. US4 → idioma.
6. US5 → privacidade e sobre.
7. Polish → aparelho, marcar B8, PR para `develop`.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- Rode cada teste sozinho e veja falhar antes de implementar.
- Um commit por história (Base + US1, US2, US3, US4, US5) e um de docs no fim; Conventional
  Commits em português com `Co-Authored-By`; `click_seguro_app/devtools_options.yaml` e
  `click-seguro.html` ficam de fora.
- `dart format` só nos arquivos tocados.
- A T008 (`authentication`), a T020 (`shell`) e a T033 (`notifications`) mexem em código de outras
  features: os testes delas têm de continuar verdes; avisar o outro desenvolvedor na PR.
- Senhas nunca vão para log, cache ou estado guardado (só nos campos de texto da tela).
