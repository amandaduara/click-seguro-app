---

description: "Task list for feature 003: login, cadastro, visitante e recuperação de senha"
---

# Tasks: Login, cadastro, visitante e recuperação de senha

**Input**: Design documents from `/specs/003-login-cadastro-visitante/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/authentication.md](contracts/authentication.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** A constituição (Seção III, TDD não negociável) exige que todo teste
seja escrito e **falhe** antes da implementação correspondente. Os testes usam Fakes à mão, rodam
offline e resetam o `GetIt` no `tearDown`. As duas páginas têm widget test de sucesso e de erro.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. O app fica em `click_seguro_app/`; `auth/` abaixo
  abrevia `click_seguro_app/lib/modules/authentication/` e `tauth/` abrevia
  `click_seguro_app/test/modules/authentication/`.
- Valores fictícios nos testes (`maria@exemplo.com`, `Senha@123`, tokens `acesso-1`/`renovacao-1`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: linha de base e os dois ajustes aditivos fora do módulo ([R1](research.md), [R9](research.md)). Cada ajuste em commit isolado (plan do produto §6).

- [X] T001 Dentro de `click_seguro_app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (esperado: 97 testes verdes, 0 erros, 0 warnings, 28 infos existentes). Se algo estiver vermelho, parar e reportar
- [X] T002 Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, grupo `003 authToken`: (a) `get('/users/me', authToken: 'acesso-x')` sem sessão envia `Authorization: Bearer acesso-x`; (b) com sessão conectada (`acesso-1`), `authToken: 'acesso-x'` vence o token da sessão; (c) 401 com `authToken` → `ApiException(unauthorized)`, **0** requests para `ApiClient.refreshPath` e sessão inalterada (continua `authenticated` se estava). Ver falhar
- [X] T003 Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, adicionar `String? authToken` em `get` (dartdoc: "usa este Bearer no lugar do da sessão; o pedido não renova nem expira a sessão"). No `_send`/`_sendWithRenewal`, passar o override para o `_makeOptions` (que usa `authToken` quando não nulo) e tratar o pedido como sem token da sessão (`sentToken = null`), para que a renovação não aconteça (faz T002 passar)
- [X] T004 [P] Em `click_seguro_app/lib/core/widgets/safe_text_field.dart`, adicionar parâmetros **opcionais**, repassados ao `TextField` interno: `TextInputType? keyboardType`, `TextInputAction? textInputAction`, `ValueChanged<String>? onSubmitted`, `FocusNode? focusNode` (se informado, usar no lugar do interno e não descartá-lo no `dispose`), `Iterable<String>? autofillHints` e `String? semanticsLabel` (envolver o campo em `Semantics(label: …, textField: true)`). Sem mudar o visual. Rodar `flutter test` para garantir que nada quebrou

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: domain comum (enums, validator, entidade, failures, contrato do repository), models, fakes, i18n, extension de apresentação, rotas e casca do módulo. Base para todas as histórias.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T005 [P] Criar `tauth/domain/validators/credentials_validator_test.dart` cobrindo o [R3](research.md):
  - `passwordRules`: `'abc'` atende só `lowercase`; `'Senha@123'` atende todas; 7 caracteres falham `length`; 65 caracteres falham `length`; espaço conta como `special`;
  - `validateRegistration`: nome `'Ana'` → `name: nameLength`; nome `'  Maria Silva  '` válido (trim); nome com 151 caracteres → `nameLength`; e-mail `'maria@'` → `email: emailInvalid`; e-mail `'.maria@x.com'` e `'ma..ria@x.com'` → `emailInvalid`; e-mail com 256 caracteres → `emailInvalid`; senha `'senha123'` → `password: passwordRules`; tudo válido → mapa vazio; campo vazio → `required`;
  - `validateLogin`: senha `'x'` com e-mail válido → vazio (no login só exige não vazia); senha vazia → `password: required`;
  - `validateEmail`, `validateCode` (`'12345'` → `code: codeLength`; `'123456'` válido) e `validateNewPassword` (confirmação diferente → `passwordConfirmation: passwordMismatch`; senha fraca → `password: passwordRules`).
- [X] T006 [P] Criar `tauth/data/models/user_model_test.dart` e `tauth/data/models/auth_tokens_model_test.dart`:
  - `UserModel.fromJson` com `{"name":"Maria Silva","email":"maria@exemplo.com","phone":null,"avatarUrl":null,"role":"USER","receiveNotifications":true}` → `toEntity()` com `role == UserRole.user`;
  - `role` `"PUBLISHER"`/`"ADMIN"` → `publisher`/`admin`; `"XYZ"` → `unknown`;
  - sem `name` → `TypeError` (o `toModel` do `ApiClient` converte em `invalidResponse`);
  - `AuthTokensModel.fromJson` com os dois tokens ok; token vazio ou ausente → lança.

### Implementação

- [X] T007 [P] Criar os enums em `auth/domain/enums/`: `auth_field.dart` (`enum AuthField { name, email, password, passwordConfirmation, code }`), `field_error.dart` (`enum FieldError { required, nameLength, emailInvalid, passwordRules, passwordMismatch, codeLength }`), `password_rule.dart` (`enum PasswordRule { length, uppercase, lowercase, digit, special }`), `user_role.dart` (`enum UserRole { user, publisher, admin, unknown }` com `static UserRole fromJson(Object? value)` tolerante: `'USER'`→`user`, `'PUBLISHER'`→`publisher`, `'ADMIN'`→`admin`, resto→`unknown`) e `reset_step.dart` (`enum ResetStep { email, code, newPassword }`)
- [X] T008 Criar `auth/domain/validators/credentials_validator.dart` (`class CredentialsValidator`, sem Flutter), com as constantes nomeadas `nameMinLength = 6`, `nameMaxLength = 150`, `emailMaxLength = 255`, `passwordMinLength = 8`, `passwordMaxLength = 64`, `codeMinLength = 6`, a regex de e-mail do OpenAPI `^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$` e os métodos do [data-model](data-model.md). Devolve `Map<AuthField, FieldError>` não modificável. `email` e `name` com `trim()` antes de validar; senha **sem** trim (faz T005 passar)
- [X] T009 [P] Criar `auth/domain/entities/user_entity.dart` (`UserEntity { name, email, phone?, avatarUrl?, role }`, `const`, sem lógica) e `auth/data/models/user_model.dart` / `auth/data/models/auth_tokens_model.dart` conforme o [data-model](data-model.md) (faz T006 passar)
- [X] T010 [P] Criar `auth/domain/failures/auth_failures.dart` com `InvalidFormFailure(Map<AuthField, FieldError> fieldErrors)` (mensagem `AppStrings.authErrorInvalidForm`, mapa não modificável), `InvalidCredentialsFailure`, `EmailAlreadyExistsFailure`, `AccountCreatedFailure` (`AppStrings.authInfoAccountCreated`) e `InvalidRecoveryCodeFailure`, todas `extends Failure` com a chave de i18n como `message`
- [X] T011 [P] i18n ([R11](research.md)). Em `click_seguro_app/lib/core/i18n/app_strings.dart`, bloco `// --- authentication ---` com as constantes abaixo, e as chaves nos dois JSONs (`assets/translations/pt-BR.json` | `en-US.json`):
  - **Tela:**
    - `auth_welcome` "Bem-vindo ao" | "Welcome to"
    - `auth_brand` "SafeNews" | "SafeNews"
    - `auth_mode_login` "Entrar" | "Sign in"
    - `auth_mode_register` "Criar conta" | "Create account"
    - `auth_name_placeholder` "Seu nome" | "Your name"
    - `auth_email_placeholder` "seu@email.com" | "you@email.com"
    - `auth_password_placeholder` "Senha" | "Password"
    - `auth_password_show` "Mostrar senha" | "Show password"
    - `auth_password_hide` "Ocultar senha" | "Hide password"
    - `auth_forgot_password` "Esqueci minha senha" | "I forgot my password"
    - `auth_or` "ou" | "or"
    - `auth_continue_as_guest` "Continuar sem login" | "Continue without signing in"
    - `auth_back` "Voltar" | "Back"
  - **Regras da senha:**
    - `auth_rule_length` "De 8 a 64 caracteres" | "8 to 64 characters"
    - `auth_rule_uppercase` "Uma letra maiúscula" | "One uppercase letter"
    - `auth_rule_lowercase` "Uma letra minúscula" | "One lowercase letter"
    - `auth_rule_digit` "Um número" | "One number"
    - `auth_rule_special` "Um caractere especial (ex.: ! @ #)" | "One special character (e.g. ! @ #)"
  - **Erros de campo:**
    - `auth_field_required` "Preencha este campo." | "Fill in this field."
    - `auth_field_name_length` "Digite seu nome completo (de 6 a 150 letras)." | "Enter your full name (6 to 150 letters)."
    - `auth_field_email_invalid` "Digite um e-mail válido." | "Enter a valid email."
    - `auth_field_password_rules` "A senha ainda não atende às regras abaixo." | "The password does not meet the rules below yet."
    - `auth_field_password_mismatch` "As senhas não são iguais." | "Passwords do not match."
    - `auth_field_code_length` "O código tem pelo menos 6 caracteres." | "The code has at least 6 characters."
  - **Erros e avisos:**
    - `auth_error_invalid_form` "Confira os campos destacados." | "Check the highlighted fields."
    - `auth_error_invalid_credentials` "E-mail ou senha incorretos." | "Incorrect email or password."
    - `auth_error_email_exists` "Este e-mail já está cadastrado." | "This email is already registered."
    - `auth_action_sign_in_with_email` "Entrar com este e-mail" | "Sign in with this email"
    - `auth_info_account_created` "Conta criada. Entre com seu e-mail e senha." | "Account created. Sign in with your email and password."
    - `auth_error_invalid_code` "Código inválido. Confira o e-mail ou peça um novo." | "Invalid code. Check your email or request a new one."
  - **Recuperação:**
    - `auth_reset_title` "Recuperar senha" | "Reset password"
    - `auth_reset_email_description` "Informe o e-mail da sua conta. Vamos enviar um código." | "Enter your account email. We will send you a code."
    - `auth_reset_send_code` "Enviar código" | "Send code"
    - `auth_reset_code_sent` "Se houver uma conta com este e-mail, enviamos um código." | "If there is an account with this email, we sent a code."
    - `auth_reset_code_placeholder` "Código recebido" | "Code received"
    - `auth_reset_continue` "Continuar" | "Continue"
    - `auth_reset_resend` "Reenviar código" | "Resend code"
    - `auth_reset_resend_in` "Reenviar em {} s" | "Resend in {} s"
    - `auth_reset_new_password_placeholder` "Nova senha" | "New password"
    - `auth_reset_confirm_password_placeholder` "Confirme a nova senha" | "Confirm the new password"
    - `auth_reset_save` "Salvar nova senha" | "Save new password"
    - `auth_reset_success` "Senha alterada. Entre com a nova senha." | "Password changed. Sign in with your new password."
  - **Início provisório:**
    - `home_placeholder_greeting` "Olá, {}" | "Hi, {}"
    - `home_placeholder_welcome` "Bem-vindo" | "Welcome"
    - `home_placeholder_body` "O Início chega em breve." | "Home is coming soon."

  Inserir as chaves logo depois da última `onboarding_*`, nos dois arquivos.
- [X] T012 [P] Criar `tauth/presentation/extensions/auth_presentation_extension_test.dart` (cada `FieldError` e cada `PasswordRule` tem uma chave `AppStrings` distinta e não vazia) e depois `auth/presentation/extensions/auth_presentation_extension.dart`, com `extension FieldErrorPresentation on FieldError { String get messageKey }` e `extension PasswordRulePresentation on PasswordRule { String get labelKey }`
- [X] T013 Criar `auth/domain/repositories/auth_repository.dart` (contrato com os 6 métodos do [data-model](data-model.md), `Either<Failure, …>` do fpdart, `Unit` nos sem retorno) e `auth/data/datasources/auth_remote_data_source.dart` (contrato com os 6 métodos, sem implementação ainda). Criar `tauth/fakes/fake_auth_repository.dart` (resultados configuráveis por método e contadores `loginCalls`, `registerCalls`, `guestCalls`, `requestResetCalls`, `verifyCodeCalls`, `resetCalls`, com os argumentos recebidos) e `tauth/fakes/fake_auth_remote_data_source.dart` (respostas ou `ApiException` configuráveis por método e contadores)
- [X] T014 [P] Criar `click_seguro_app/lib/core/routing/home_placeholder_page.dart` (`HomePlaceholderPage`, comentário `// TODO(F0.9): substituir pelo shell com as abas.`): lê `GetIt.instance<UserSessionService>()` e mostra `home_placeholder_greeting` com `userName`, ou `home_placeholder_welcome` para visitante, e `home_placeholder_body`
- [X] T015 Criar `auth/presentation/routes/authentication_routes.dart` com `final List<RouteBase> authenticationRoutes` contendo `/login` → `LoginPage` e `/forgot-password` → `ForgotPasswordPage(initialEmail: state.extra as String?)`. Criar `LoginPage` e `ForgotPasswordPage` como `StatefulWidget` mínimos (`Scaffold` vazio) em `auth/presentation/pages/`, para compilar. Em `click_seguro_app/lib/core/routing/app_router.dart`, trocar a rota `/login` por `...authenticationRoutes` e adicionar `GoRoute(path: '/home', builder: (_, _) => const HomePlaceholderPage())`. Apagar `auth/presentation/pages/login_placeholder_page.dart` e ajustar os barrels (`authentication.dart` exporta `authentication_module.dart`, `presentation/routes/authentication_routes.dart`, `presentation/pages/login_page.dart` e `presentation/pages/forgot_password_page.dart`)
- [X] T016 [P] Criar os widgets compartilhados em `auth/presentation/widgets/`: `auth_header.dart` (quadrado de 48 em `AppColors.primary`, raio 16, ícone `Icons.shield_outlined` branco; ao lado, `auth_welcome` em texto pequeno muted e `auth_brand` em título bold `AppColors.secondary`) e `or_divider.dart` (duas linhas `AppColors.border` com `auth_or` no meio). Com `tauth/presentation/widgets/auth_header_test.dart` simples (renderiza os dois textos)

**Checkpoint**: `flutter analyze` limpo e `flutter test` verde. O app abre no login vazio, e a rota `/home` existe.

---

## Phase 3: User Story 1 - Entrar com e-mail e senha (Priority: P1) 🎯 MVP

**Goal**: login completo, do formulário à sessão salva e à navegação para `/home` (FR-001, FR-003, FR-004, FR-006, FR-007, FR-011, FR-017).

**Independent Test**: com o repository falso devolvendo sucesso, a `LoginPage` vai para `/home`; com `InvalidCredentialsFailure`, mostra "E-mail ou senha incorretos." e mantém os campos; com e-mail inválido, marca o campo e não chama o repository.

### Tests for User Story 1 ⚠️

- [X] T017 [P] [US1] Criar `tauth/data/datasources/auth_remote_data_source_impl_test.dart` (grupo `login`), com `ApiClient` real sobre `FakeHttpClientAdapter` e `UserSessionService` com `FakeSecureStorageService` no `GetIt`:
  - `login` faz `POST /auth/app/login` com `{"email","password"}`, sem `Authorization`, e devolve `AuthTokensModel`;
  - `getMe('acesso-1')` faz `GET /users/me` com `Authorization: Bearer acesso-1` e devolve `UserModel`;
  - 401 `INVALID_CREDENTIALS` no login → `ApiException(unauthorized, errorCode: 'INVALID_CREDENTIALS')`.
- [X] T018 [P] [US1] Criar `tauth/data/repositories/auth_repository_impl_test.dart` (grupo `login`), com `FakeAuthRemoteDataSource` e `UserSessionService` real:
  - sucesso → `Right(UserEntity)` e `saveSession` feito (`accessToken`, `refreshToken`, `email` do `/users/me`, `userName`);
  - 401 `INVALID_CREDENTIALS` → `Left(InvalidCredentialsFailure)`, sessão continua desconectada;
  - `role` `admin`/`unknown` → `Left(InvalidCredentialsFailure)` e **nada salvo**;
  - `connection` → `ConnectionFailure`; 500 → `ServerFailure`;
  - falha no `getMe` depois do login → `toFailure()` correspondente e nada salvo.
- [X] T019 [P] [US1] Criar `tauth/domain/usecases/login_usecase_test.dart` (com `FakeAuthRepository`): e-mail inválido → `Left(InvalidFormFailure({email: emailInvalid}))` com `loginCalls == 0`; senha vazia → `{password: required}`; válido → repassa `email.trim()` e a senha ao repository e devolve o resultado dele
- [X] T020 [P] [US1] Criar `tauth/presentation/controller/authentication_controller_test.dart` (grupo `US1`), com usecases reais sobre `FakeAuthRepository`:
  - `submit` no modo login alterna `isSubmitting` `[true, false]` e, com sucesso, `authenticated == true`;
  - `InvalidFormFailure` vai para `fieldErrors` (`failure` fica nulo);
  - `InvalidCredentialsFailure` vai para `failure`;
  - um segundo `submit` enquanto `isSubmitting` é ignorado (`loginCalls == 1`, FR-006);
  - `togglePasswordVisibility` alterna `isPasswordVisible`;
  - `reset()` volta ao estado inicial.
- [X] T021 [P] [US1] Criar `tauth/presentation/pages/login_page_test.dart` (grupo `US1`). Setup do [R12](research.md): `EasyLocalization` com as traduções reais, `SharedPreferences.setMockInitialValues({})`, `AuthenticationController` real sobre `FakeAuthRepository` via `ChangeNotifierProvider`, e `GoRouter` de teste com `/login` → `LoginPage` e `/home` → `Text('HOME')`. Casos:
  - mostra `AuthHeader`, campos de e-mail e senha e o botão "Entrar";
  - e-mail e senha válidos + toque em "Entrar" → mostra `HOME`;
  - repository com `InvalidCredentialsFailure` → mostra "E-mail ou senha incorretos." e o e-mail continua no campo;
  - e-mail `maria@` → "Digite um e-mail válido." sob o campo e `loginCalls == 0`;
  - tocar no olho (`Semantics` "Mostrar senha") troca para "Ocultar senha" e revela o texto.

### Implementation for User Story 1

- [X] T022 [US1] Criar `auth/data/datasources/auth_remote_data_source_impl.dart` com `login` e `getMe` (constantes `loginPath = '/auth/app/login'`, `mePath = '/users/me'`; `requiresAuth: false` no login; `authToken:` no `getMe`; `toModel(...)`). Os demais métodos lançam `UnimplementedError` até as próximas histórias (faz T017 passar)
- [X] T023 [US1] Criar `auth/data/repositories/auth_repository_impl.dart` com `login` (fluxo privado `_signIn`, ver [data-model](data-model.md) e [R4](research.md)). `INVALID_CREDENTIALS` comparado com `ApiErrorCodes.invalidCredentials` **antes** do `toFailure()`. Os demais métodos devolvem `Left(ServerFailure())` até as próximas histórias (faz T018 passar)
- [X] T024 [US1] Criar `auth/domain/usecases/login_usecase.dart` (`LoginUseCase(AuthRepository, CredentialsValidator)`, `call({required String email, required String password})`) (faz T019 passar)
- [X] T025 [US1] Reescrever `auth/presentation/controller/authentication_controller.dart` (o controller vazio atual) com o estado do [data-model](data-model.md) necessário à US1: `mode` (só `login` por ora), `isSubmitting`, `fieldErrors`, `failure`, `isPasswordVisible`, `authenticated`, `submit`, `togglePasswordVisibility` e `reset`. Depende só de usecases (faz T020 passar)
- [X] T026 [US1] Implementar `auth/presentation/pages/login_page.dart` conforme o wireframe ([R10](research.md)):
  - `SafeArea` + `SingleChildScrollView` com padding 24;
  - `AuthHeader`;
  - `SafeTextField` de e-mail (`Icons.mail_outline`, `TextInputType.emailAddress`, `TextInputAction.next`, `AutofillHints.email`);
  - `SafeTextField` de senha (`Icons.lock_outline`, `obscureText: !isPasswordVisible`, `rightIcon: IconButton` 48×48 com `tooltip`/`Semantics` `auth_password_show`/`auth_password_hide`, `TextInputAction.done` → submit);
  - erros de campo pela extension;
  - `failure` em um aviso acima do botão (texto `AppColors.destructive`, `Semantics(liveRegion: true)`);
  - `SafeButton(size: large, tone: primary, loading: isSubmitting)` "Entrar".

  `initState` chama `controller.reset()`. Quando `authenticated` vira `true`, `context.go('/home')` e `reset()`. `TextEditingController`s na página e descartados no `dispose` (faz T021 passar)
- [X] T027 [US1] Em `auth/authentication_module.dart`, registrar `AuthRemoteDataSource` (`AuthRemoteDataSourceImpl(injector<ApiClient>())`), `AuthRepository` (`AuthRepositoryImpl(..., injector<UserSessionService>())`), `CredentialsValidator`, `LoginUseCase`, e o provider `AuthenticationController(...)`. Rodar o app no aparelho (`flutter run -d RQGYB02P7HD`) e conferir que a tela abre

**Checkpoint**: login funcionando de ponta a ponta com o repository falso nos testes. MVP.

---

## Phase 4: User Story 2 - Criar conta (Priority: P1)

**Goal**: cadastro com entrada automática, regras da senha visíveis, e-mail duplicado e conta criada sem login (FR-002, FR-004, FR-005, FR-008, FR-009).

**Independent Test**: no modo "Criar conta", dados válidos levam a `/home`; e-mail duplicado mostra a mensagem e o atalho "Entrar com este e-mail"; senha fraca mostra as regras faltando, sem chamar o repository.

### Tests for User Story 2 ⚠️

- [X] T028 [P] [US2] Em `tauth/data/datasources/auth_remote_data_source_impl_test.dart`, grupo `register`: `POST /auth/app/register` com `{"name","email","password"}` e `requiresAuth: false`; 409 `USER_EMAIL_ALREADY_EXISTS` → `ApiException(client, errorCode: 'USER_EMAIL_ALREADY_EXISTS')`
- [X] T029 [P] [US2] Em `tauth/data/repositories/auth_repository_impl_test.dart`, grupo `register`:
  - sucesso → chama `register`, depois `login` e `getMe` com as mesmas credenciais, salva a sessão e devolve `Right(user)`;
  - 409 → `EmailAlreadyExistsFailure`, sem chamar `login`;
  - `register` ok mas `login` com `connection` → `AccountCreatedFailure` e nada salvo;
  - `register` ok mas papel ≠ USER → `AccountCreatedFailure`.
- [X] T030 [P] [US2] Criar `tauth/domain/usecases/register_usecase_test.dart` (nome curto, e-mail inválido e senha fraca → `InvalidFormFailure` com os campos certos e `registerCalls == 0`; válido → repassa `name.trim()` e `email.trim()`) e `tauth/domain/usecases/evaluate_password_usecase_test.dart` (`'Senha@123'` → as 5 regras)
- [X] T031 [P] [US2] Em `tauth/presentation/controller/authentication_controller_test.dart`, grupo `US2`:
  - `setMode(register)` limpa `fieldErrors` e `failure`;
  - `onPasswordChanged('Ab1')` → `passwordRules == {uppercase, lowercase, digit}`;
  - `submit` no cadastro com sucesso → `authenticated`;
  - `EmailAlreadyExistsFailure` → `failure` e o modo continua `register`;
  - `AccountCreatedFailure` → `mode == login` e `failure is AccountCreatedFailure`.
- [X] T032 [P] [US2] Em `tauth/presentation/pages/login_page_test.dart`, grupo `US2`:
  - tocar em "Criar conta" no seletor mostra o campo de nome e a lista de regras, e o e-mail digitado continua;
  - digitar `Senha@123` marca as 5 regras;
  - cadastro válido → `HOME`;
  - `EmailAlreadyExistsFailure` → mensagem + botão "Entrar com este e-mail", que volta ao modo "Entrar" com o e-mail;
  - `AccountCreatedFailure` → modo "Entrar" com "Conta criada. Entre com seu e-mail e senha.".

### Implementation for User Story 2

- [X] T033 [US2] Implementar `register` em `auth/data/datasources/auth_remote_data_source_impl.dart` (`registerPath = '/auth/app/register'`) (faz T028 passar)
- [X] T034 [US2] Implementar `register` em `auth/data/repositories/auth_repository_impl.dart` ([R5](research.md)), com `_AuthErrorCodes.emailAlreadyExists = 'USER_EMAIL_ALREADY_EXISTS'` (faz T029 passar)
- [X] T035 [P] [US2] Criar `auth/domain/usecases/register_usecase.dart` e `auth/domain/usecases/evaluate_password_usecase.dart` (síncrono: `Set<PasswordRule> call(String password)`) (faz T030 passar)
- [X] T036 [US2] No `AuthenticationController`: `mode` com `AuthMode { login, register }`, `setMode`, `onPasswordChanged`, `passwordRules`, e `submit(name:, email:, password:)` decidindo entre `LoginUseCase` e `RegisterUseCase` e tratando `AccountCreatedFailure`/`EmailAlreadyExistsFailure` ([data-model](data-model.md)) (faz T031 passar)
- [X] T037 [P] [US2] Criar `auth/presentation/widgets/auth_mode_switch.dart` (pílula com fundo `AppColors.input`, raio total e dois botões de 48 de altura; o selecionado em fundo `AppColors.background`, texto `AppColors.secondary` e sombra leve, o outro em muted; `Semantics(button: true, selected: …)`) e `auth/presentation/widgets/password_rules_list.dart` (as 5 regras, ícone `Icons.check_circle` em `AppColors.success` quando atendida e `Icons.radio_button_unchecked` muted quando não; texto ≥ 14 com `labelKey.tr()`)
- [X] T038 [US2] Na `LoginPage`:
  - `AuthModeSwitch` abaixo do header;
  - campo de nome (`Icons.person_outline`, `AutofillHints.name`, `TextInputAction.next`) só no cadastro;
  - `PasswordRulesList` sob a senha só no cadastro, alimentada por `onChanged` → `onPasswordChanged`;
  - texto do botão conforme o modo;
  - aviso `EmailAlreadyExistsFailure` com `SafeButton(compact, ghost)` "Entrar com este e-mail" → `setMode(login)`.

  O `TextEditingController` do e-mail é o mesmo nos dois modos (faz T032 passar)
- [X] T039 [US2] Registrar `RegisterUseCase` e `EvaluatePasswordUseCase` em `auth/authentication_module.dart` e passá-los ao `AuthenticationController`

**Checkpoint**: login e cadastro completos.

---

## Phase 5: User Story 3 - Continuar sem login (Priority: P2)

**Goal**: visitante com um toque, sem rede (FR-010).

**Independent Test**: tocar em "Continuar sem login" leva a `/home`, e a sessão fica `guest` sem nenhuma chamada de rede.

### Tests for User Story 3 ⚠️

- [ ] T040 [P] [US3] Em `tauth/data/repositories/auth_repository_impl_test.dart`, grupo `guest`: `enterAsGuest()` → `Right(unit)`, `sessionStatus == guest` e 0 chamadas ao datasource
- [ ] T041 [P] [US3] Criar `tauth/domain/usecases/enter_as_guest_usecase_test.dart` e, em `authentication_controller_test.dart`, grupo `US3`: `continueAsGuest()` → `authenticated == true` e `guestCalls == 1`; ignorado enquanto `isSubmitting`
- [ ] T042 [P] [US3] Em `tauth/presentation/pages/login_page_test.dart`, grupo `US3`: `OrDivider` e o botão "Continuar sem login" aparecem nos dois modos; tocar → `HOME`

### Implementation for User Story 3

- [ ] T043 [US3] Implementar `enterAsGuest` em `auth/data/repositories/auth_repository_impl.dart` (`session.startGuestSession()`) e criar `auth/domain/usecases/enter_as_guest_usecase.dart` (faz T040 e a parte de usecase da T041 passarem)
- [ ] T044 [US3] No `AuthenticationController`, adicionar `continueAsGuest()`. Na `LoginPage`, adicionar `OrDivider` e `SafeButton(large, secondary)` "Continuar sem login" no fim do formulário. Registrar `EnterAsGuestUseCase` no módulo (faz T041 e T042 passarem)

**Checkpoint**: as três formas de entrar funcionando.

---

## Phase 6: User Story 4 - Recuperar a senha (Priority: P2)

**Goal**: três passos com o código validado antes da troca, reenvio a cada 60 s e volta ao login com o e-mail preenchido (FR-012 a FR-016).

**Independent Test**: percorrer os três passos com o repository falso e voltar ao login com o e-mail e a mensagem de sucesso; código inválido mantém no passo 2; reenvio bloqueado por 60 s com relógio falso.

### Tests for User Story 4 ⚠️

- [ ] T045 [P] [US4] Em `tauth/data/datasources/auth_remote_data_source_impl_test.dart`, grupo `recuperação`: `forgotPassword` → `POST /auth/forgot-password` `{"email"}`; `verifyCode` → `POST /auth/forgot-password/verify` `{"email","code"}`; `resetPassword` → `POST /auth/forgot-password/reset` `{"email","code","newPassword"}`. Todos com `requiresAuth: false`
- [ ] T046 [P] [US4] Em `tauth/data/repositories/auth_repository_impl_test.dart`, grupo `recuperação`: os três com 204 → `Right(unit)`; `verifyCode` com 401 `INVALID_RECOVERY_CODE` → `InvalidRecoveryCodeFailure`; `connection` → `ConnectionFailure`. A sessão nunca é alterada
- [ ] T047 [P] [US4] Criar os testes dos usecases `request_password_reset_usecase_test.dart` (e-mail inválido barrado), `verify_reset_code_usecase_test.dart` (código com 5 caracteres barrado) e `reset_password_usecase_test.dart` (senha fraca e confirmação diferente barradas), todos em `tauth/domain/usecases/`
- [ ] T048 [P] [US4] Criar `tauth/presentation/controller/forgot_password_controller_test.dart`, com relógio falso (`DateTime now`, avançado à mão):
  - `start('maria@exemplo.com')` → `step == email`, `email` preenchido;
  - `submitEmail` ok → `step == code`, `secondsUntilResend == 60`;
  - avançar 59 s → 1; avançar 60 s → 0;
  - `resendCode()` com contagem > 0 é ignorado; com 0, chama o repository e volta a 60;
  - `submitCode` com `InvalidRecoveryCodeFailure` → continua em `code` com `failure`;
  - `submitCode` ok → `newPassword`;
  - `submitNewPassword` ok → `completed == true`;
  - `back()` volta um passo e devolve `false` no passo `email`;
  - envio duplicado ignorado.
- [ ] T049 [P] [US4] Criar `tauth/presentation/pages/forgot_password_page_test.dart` e, em `login_page_test.dart`, grupo `US4`:
  - "Esqueci minha senha" só no modo "Entrar" e abre a recuperação com o e-mail já digitado;
  - fluxo completo → volta à `LoginPage` com o e-mail e "Senha alterada. Entre com a nova senha.";
  - código inválido → mensagem e continua no passo do código;
  - botão de voltar no passo 2 volta ao passo 1;
  - "Reenviar em 60 s" visível depois do envio.

### Implementation for User Story 4

- [ ] T050 [US4] Implementar `forgotPassword`, `verifyCode` e `resetPassword` em `auth/data/datasources/auth_remote_data_source_impl.dart` (constantes `forgotPasswordPath`, `verifyCodePath`, `resetPasswordPath`) e os três métodos em `auth/data/repositories/auth_repository_impl.dart`, com `_AuthErrorCodes.invalidRecoveryCode = 'INVALID_RECOVERY_CODE'` (faz T045 e T046 passarem)
- [ ] T051 [P] [US4] Criar `auth/domain/usecases/request_password_reset_usecase.dart`, `verify_reset_code_usecase.dart` e `reset_password_usecase.dart`, cada um validando antes ([data-model](data-model.md)) (faz T047 passar)
- [ ] T052 [US4] Criar `auth/presentation/controller/forgot_password_controller.dart` conforme o [data-model](data-model.md) e o [R7](research.md): construtor com os três usecases e `{DateTime Function()? now}` (padrão `DateTime.now`), `static const Duration resendCooldown = Duration(seconds: 60)` (faz T048 passar)
- [ ] T053 [P] [US4] Criar `auth/presentation/widgets/resend_code_button.dart`, que recebe `secondsUntilResend` e `onPressed`. Com contagem > 0, fica desabilitado com `auth_reset_resend_in` e os segundos; com 0, `auth_reset_resend`
- [ ] T054 [US4] Implementar `auth/presentation/pages/forgot_password_page.dart`:
  - `AppBar` com voltar (`auth_back`) e título `auth_reset_title`;
  - `PopScope` chamando `controller.back()` ([R7](research.md));
  - por passo:
    - **e-mail:** descrição, campo de e-mail e "Enviar código";
    - **código:** aviso `auth_reset_code_sent`, campo `auth_reset_code_placeholder` (`TextInputType.text`, `AutofillHints.oneTimeCode`), "Continuar" e `ResendCodeButton` com `Timer.periodic(1 s)` só neste passo, cancelado no `dispose`;
    - **nova senha:** nova senha com olho e `PasswordRulesList`, confirmação e "Salvar nova senha".

  `initState` → `controller.start(widget.initialEmail)`. Em `completed`, `context.pop(controller.email)` e `reset()` (faz a parte de página da T049 passar)
- [ ] T055 [US4] Na `LoginPage`, adicionar "Esqueci minha senha" (`TextButton` alinhado à direita, cor `AppColors.primary`, só no modo login): `final email = await context.push<String>('/forgot-password', extra: emailController.text.trim())`. Com retorno, preencher o e-mail e mostrar `auth_reset_success` como aviso de sucesso (`AppColors.success`). Registrar os usecases e o provider `ForgotPasswordController` em `auth/authentication_module.dart` (faz T049 passar)

**Checkpoint**: as quatro histórias funcionando.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: acessibilidade, revisão, validação no aparelho e documentação.

- [ ] T056 [P] Em `tauth/presentation/pages/login_page_test.dart` e `forgot_password_page_test.dart`, grupo `acessibilidade` (FR-019, SC-007): com `MediaQuery(textScaler: TextScaler.linear(1.5))` e tela de 360×690, nenhum overflow (`tester.takeException()` nulo) e o botão principal alcançável por rolagem; cada interativo tem rótulo semântico (`find.bySemanticsLabel`) e tamanho ≥ 48×48 (`tester.getSize`)
- [ ] T057 Revisar os textos en-US e pt-BR em `assets/translations/` (sem chave faltando: um teste em `tauth/presentation/i18n_keys_test.dart` lê os dois JSONs e confere que toda chave `auth_*`/`home_placeholder_*` de `AppStrings` existe nos dois)
- [ ] T058 Dentro de `click_seguro_app/`, rodar `flutter analyze` (sem erro ou warning novo) e `flutter test` (tudo verde) e comparar com a linha de base da T001
- [ ] T059 Build e instalação no aparelho (`flutter build apk --debug` + `flutter install --debug -d RQGYB02P7HD`), conferir que a tela de login abre e navega entre os modos sem erro no log. Se houver `API_URL` disponível, seguir a seção 2 do [quickstart](quickstart.md) e trocar 🧪 por ✅ nas linhas de autenticação do `.specify/memory/api-contract.md`; senão, registrar que a validação contra o servidor ficou pendente
- [ ] T060 Em `.specify/memory/tasks.md`, marcar `[x] **A2 …** (specs/003-login-cadastro-visitante)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro; T002 → T003; T004 independente.
- **Foundational (Phase 2)**: depende da Phase 1. T005 → T007 → T008; T006 → T009 (T009 usa `UserRole` da T007); T010, T011 e T012 depois da T007; T013 depois de T009/T010; T014 depois da T011; T015 depois de T014; T016 depois da T011.
- **US1 (Phase 3)**: depende da Phase 2 e da T003 (`authToken`). Testes T017–T021 em paralelo; T022 → T023 → T024 → T025 → T026 → T027.
- **US2 (Phase 4)**: depende da US1 (mesmo controller, página, datasource e repository).
- **US3 (Phase 5)**: depende da US1 (página e controller). Pode vir antes da US2, se preferir.
- **US4 (Phase 6)**: depende da Phase 2. Controller e página próprios, mas a T055 mexe na `LoginPage` (depois da US1).
- **Polish (Phase 7)**: depois de todas as histórias.

### User Story Dependencies

- **US1 (P1)**: base das demais (página e controller de login).
- **US2 (P1)** e **US3 (P2)**: depois da US1, em sequência, porque mexem nos mesmos arquivos.
- **US4 (P2)**: as tarefas T045–T054 podem andar em paralelo com a US2/US3 (outros arquivos); só a T055 espera a US1.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Datasource → repository → usecase → controller → página → registro no módulo (ordem do guia).
- Commit ao fim de cada história. Os ajustes de `common`/`core` (T003, T004) vão em commit isolado.

### Parallel Opportunities

- **Phase 1:** T004 em paralelo com T002/T003.
- **Phase 2:** T005 ∥ T006; T007 ∥ T009 depois dos testes; T010, T011, T012, T014 e T016 entre si.
- **Cada história:** todos os testes [P] juntos; na US4, também T051 e T053.

---

## Parallel Example: User Story 1

```bash
Task: "Teste do datasource (login/getMe) em click_seguro_app/test/modules/authentication/data/datasources/auth_remote_data_source_impl_test.dart"
Task: "Teste do repository (login) em click_seguro_app/test/modules/authentication/data/repositories/auth_repository_impl_test.dart"
Task: "Teste do LoginUseCase em click_seguro_app/test/modules/authentication/domain/usecases/login_usecase_test.dart"
Task: "Teste do AuthenticationController (US1) em click_seguro_app/test/modules/authentication/presentation/controller/authentication_controller_test.dart"
Task: "Widget test da LoginPage (US1) em click_seguro_app/test/modules/authentication/presentation/pages/login_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): login de ponta a ponta.
3. **PARAR e VALIDAR**: `flutter test` verde e a tela de login no aparelho.

### Incremental Delivery

1. Setup + Foundational → módulo pronto para receber as histórias; rota `/home` provisória.
2. US1 → login (MVP).
3. US2 → cadastro.
4. US3 → visitante.
5. US4 → recuperação de senha.
6. Polish → acessibilidade, aparelho, PR para `develop` (depois das PRs de docs e da 002).

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [USn] mapeia a tarefa para a história da [spec](spec.md).
- Verifique que o teste falha antes de implementar.
- **Não** mexer no splash (A1), em `main.dart` nem no shell (F0.9). O destino `/home` é provisório.
- O `dart format` em pastas inteiras reformata arquivos fora do escopo: formate só os arquivos
  tocados pela tarefa.
