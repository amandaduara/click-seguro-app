# Research: Login, cadastro, visitante e recuperação de senha

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

## R1 — `GET /users/me` logo depois do login, antes de salvar a sessão (FR-007, FR-011)

- **Decisão:** novo parâmetro opcional `String? authToken` em `ApiClient.get`. Quando informado,
  vai no header `Authorization` no lugar do token da sessão, e o pedido **não** entra na regra de
  renovação/expiração da feature 002: ele é tratado como pedido sem token da sessão
  (`sentToken = null`). O `AuthRemoteDataSource.getMe(accessToken)` usa esse parâmetro.
- **Racional:** o login devolve só os tokens. O app precisa do nome e do papel **antes** de
  decidir se salva a sessão: conta de CMS não pode conectar (FR-011), e salvar e desfazer em
  seguida notificaria `sessionStatus` duas vezes.
- **Alternativas consideradas:**
  - Salvar a sessão com nome vazio, chamar `/users/me` e depois `updateProfile` ou `logout`.
    Rejeitado: estado intermediário observável, e a saída por papel errado registraria
    `endReason = userLogout`.
  - `Dio` próprio no datasource. Proibido pela constituição (IV).

## R2 — Validação nos usecases, não no controller (FR-004, FR-005; constituição I)

- **Decisão:**
  - `CredentialsValidator` (domain, puro) tem `validateLogin(email, password)`,
    `validateRegistration(name, email, password)`, `validateNewPassword(password, confirmation)`
    e `passwordRules(password) → Set<PasswordRule>`.
  - `LoginUseCase`, `RegisterUseCase`, `RequestPasswordResetUseCase` e `ResetPasswordUseCase`
    validam primeiro. Com erro, devolvem `Left(InvalidFormFailure(fieldErrors))` sem tocar no
    repository.
  - A lista viva de regras da senha (FR-005) vem do `EvaluatePasswordUseCase`, síncrono, que
    só chama o validator.
- **Racional:** a constituição I diz que o controller fala **só** com usecases. Manter a regra
  dentro do usecase também garante o SC-004 (nenhum envio inválido) em um único ponto testável.
- **Alternativas consideradas:** controller chamando o validator direto. Rejeitado (I).

## R3 — Regras e mensagens de validação

- **Decisão:**
  - `enum AuthField { name, email, password, passwordConfirmation, code }`.
  - `enum FieldError { required, nameLength, emailInvalid, passwordRules, passwordMismatch, codeLength }`.
  - `enum PasswordRule { length, uppercase, lowercase, digit, special }`.
  - Valores fixos, iguais ao [api-contract](../../.specify/memory/api-contract.md):
    - nome com 6 a 150 caracteres após `trim`;
    - e-mail até 255, com a mesma regex do OpenAPI
      (`^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$`);
    - senha com 8 a 64 caracteres e pelo menos uma maiúscula, uma minúscula, um dígito e um
      caractere que não seja letra nem dígito;
    - código com 6 ou mais caracteres.
  - No login, a senha só precisa não estar vazia (FR-004).
- **Racional:** usar a mesma regex do backend evita aceitar no app um e-mail que a API recusa
  com 400. O `enum` atende à constituição V; a tradução fica em extension da presentation.

## R4 — Mapeamento de erros no `AuthRepositoryImpl`

| Origem | Condição | `Failure` |
|---|---|---|
| login | 401 `INVALID_CREDENTIALS` | `InvalidCredentialsFailure` |
| login | `role != USER` no `/users/me` | `InvalidCredentialsFailure` (FR-011) |
| cadastro | 409 `USER_EMAIL_ALREADY_EXISTS` | `EmailAlreadyExistsFailure` |
| cadastro | criou, mas `login`/`getMe` falhou | `AccountCreatedFailure` (FR-009) |
| verificar código | 401 `INVALID_RECOVERY_CODE` | `InvalidRecoveryCodeFailure` |
| qualquer | 400 de validação do servidor | `ServerFailure` (não deveria acontecer: o app valida antes) |
| qualquer | demais | `ApiException.toFailure()` (conexão, servidor) |

- Os códigos `INVALID_RECOVERY_CODE` e `USER_EMAIL_ALREADY_EXISTS` ficam como constantes no
  próprio repository (`_AuthErrorCodes`), como definido no R9 da 002. `INVALID_CREDENTIALS` vem
  de `ApiErrorCodes`.
- **Racional:** o 401 de senha errada passa pelo `ApiClient` sem mexer na sessão (feature 002),
  mas o `toFailure()` o transformaria em `UnauthorizedFailure` ("sessão expirada"). Por isso o
  código é testado antes do fallback.

## R5 — Cadastro em duas etapas (FR-008, FR-009)

- **Decisão:** `AuthRepositoryImpl.register` faz `POST /auth/app/register` e, com sucesso, chama o
  mesmo fluxo privado do login (`_signIn`). Se o `_signIn` falhar por qualquer motivo, devolve
  `Left(AccountCreatedFailure())`. O controller trata essa falha voltando ao modo "Entrar" com o
  e-mail preenchido.
- **Racional:** a API não devolve token no cadastro. Separar "criou, mas não entrou" de "não
  criou" evita que a pessoa tente cadastrar de novo e receba "e-mail já cadastrado".

## R6 — Navegação e rotas sem o shell (Assumptions da spec)

- **Decisão:**
  - `lib/modules/authentication/presentation/routes/authentication_routes.dart` exporta
    `authenticationRoutes` com `/login` e `/forgot-password`. O `app_router.dart` passa a
    compor `...authenticationRoutes` (padrão do plan do produto §2).
  - Rota provisória `/home` → `HomePlaceholderPage` em `lib/core/routing/`, com saudação pelo
    nome (ou "Bem-vindo" para visitante) e `TODO(F0.9)`. A F0.9 apaga.
  - Sucesso no login, no cadastro ou como visitante → `context.go('/home')`.
  - "Esqueci minha senha" → `context.push<String>('/forgot-password', extra: email)`. Ao concluir,
    a página faz `pop(email)`, e a tela de login preenche o e-mail e mostra a mensagem
    (FR-016), sem estado global.
- **Racional:** o `go_router` já é a solução do projeto. O resultado do `push` evita guardar "senha
  alterada" num controller global.
- **Fora daqui:** o splash continua levando a `/login`. Ir direto ao `/home` com sessão salva é da
  A1.

## R7 — Recuperação: um controller, três passos numa rota (FR-012 a FR-016)

- **Decisão:** `ForgotPasswordController` com `step` (`enum ResetStep { email, code, newPassword }`),
  `email` e `code` guardados entre os passos, `isSubmitting`, `failure` e `fieldErrors`.
  - `back()` volta um passo; no primeiro, devolve `false` para a página fechar. A página usa
    `PopScope` para que o voltar do sistema siga a mesma regra (cenário 7).
  - **Reenvio (FR-015):** o controller guarda `lastCodeSentAt` e recebe um relógio injetável
    (`DateTime Function() now`). `secondsUntilResend` é calculado a partir dele. A página
    redesenha a contagem com um `Timer.periodic` de 1 s, que só existe no passo do código.
- **Racional:** com o relógio injetável, o teste do controller é determinístico, sem
  `fake_async` (que não é dependência direta). O timer fica só na UI.

## R8 — Controllers globais com `reset()` (constituição IV)

- **Decisão:** `AuthenticationController` (login, cadastro e visitante; o controller vazio que já
  existe passa a ser este) e `ForgotPasswordController` são registrados em `providers()` do
  `AuthenticationModule`, como manda a constituição. As páginas chamam `reset()` no `initState`
  para não herdar estado de uma visita anterior (ex.: erro antigo depois de um logout).
- **Alternativas consideradas:** provider por rota. Rejeitado: foge do padrão
  `providers()` do módulo.

## R9 — Ajustes aditivos no design system (FR-019, edge "Teclado")

- **Decisão:** o `SafeTextField` ganha parâmetros **opcionais**: `keyboardType`,
  `textInputAction`, `onSubmitted`, `focusNode`, `autofillHints` e `semanticsLabel`. Sem mudar o
  visual nem quebrar quem já usa. O botão do olho é um `IconButton` (alvo de 48×48) passado em
  `rightIcon`.
- **Racional:** a spec exige teclado de e-mail, "próximo/concluir" e rótulos para leitor de tela.
  O plan do produto §6 pede commit isolado para mudanças em `core/widgets`. O ajuste de fonte base
  para 16 sp e os estados comuns continuam sendo da F0.10.

## R10 — Widgets próprios da tela

- **Decisão:** em `authentication/presentation/widgets/`:
  - `AuthHeader` (escudo + "Bem-vindo ao" + "SafeNews");
  - `AuthModeSwitch` (seletor "Entrar"/"Criar conta" em pílula, com `Semantics` de botão
    selecionado);
  - `PasswordRulesList` (as 5 regras com ícone de check);
  - `OrDivider`;
  - `ResendCodeButton`.

  Todos "burros": recebem valores prontos, não a entity.
- **Visual:** segue o wireframe (`LoginScreen.tsx`), com o seletor pill sobre fundo `input`,
  campos `SafeTextField` com ícones `mail_outline`/`lock_outline`/`person_outline`, botão
  principal `SafeButton(large, primary)` e "Continuar sem login" `SafeButton(large, secondary)`
  com borda.

## R11 — i18n (FR-018)

- **Decisão:** bloco `// --- authentication ---` em `AppStrings` e chaves `auth_*` nos dois JSONs
  (pt-BR e en-US), inseridas juntas. Mensagens de `Failure` também são chaves `auth_error_*`.
  Extension `FieldErrorPresentation`/`PasswordRulePresentation` traduz os enums.
- **Racional:** é o padrão previsto para a F0.8, antecipado só para este módulo.

## R12 — Testes

- **Decisão:**
  - **Models e datasource:** `ApiClient` real sobre o `FakeHttpClientAdapter` da 002 (caminho,
    método, corpo, `Authorization` do `authToken`).
  - **Repository:** `FakeAuthRemoteDataSource` + `UserSessionService` real com
    `FakeSecureStorageService`.
  - **Usecases e controllers:** usecases reais sobre um `FakeAuthRepository` (padrão do guia §6).
  - **Widget tests** (`LoginPage`, `ForgotPasswordPage`): `EasyLocalization` com
    `SharedPreferences.setMockInitialValues({})` e as traduções reais de `assets/translations`;
    controllers reais sobre o `FakeAuthRepository`; `GoRouter` de teste com `/home` falso para
    conferir a navegação. Cobrem sucesso e erro (constituição III).
- **Racional:** tudo offline, sem pacote novo.
