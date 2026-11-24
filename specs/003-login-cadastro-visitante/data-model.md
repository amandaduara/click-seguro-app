# Data Model: Login, cadastro, visitante e recuperação de senha

**Feature**: [spec.md](spec.md) · **Research**: [research.md](research.md)

Tudo em `lib/modules/authentication/` (exceto onde indicado).

## Domain

### UserEntity (`domain/entities/user_entity.dart`)

| Campo | Tipo | Origem (`GET /users/me`) | Regra |
|---|---|---|---|
| `name` | `String` | `name` | obrigatório |
| `email` | `String` | `email` | obrigatório |
| `phone` | `String?` | `phone` | — |
| `avatarUrl` | `String?` | `avatarUrl` | — |
| `role` | `UserRole` | `role` | só `user` pode conectar (FR-011) |

### UserRole (`domain/enums/user_role.dart`)

`user`, `publisher`, `admin` e `unknown`. O `fromJson` é tolerante: um valor desconhecido vira
`unknown` e é tratado como "não é usuário do app".

### AuthField, FieldError, PasswordRule (`domain/enums/`)

Ver [R3](research.md). `InvalidFormFailure.fieldErrors` é um `Map<AuthField, FieldError>`
imutável.

### ResetStep (`domain/enums/reset_step.dart`)

`email` → `code` → `newPassword`.

### Failures (`domain/failures/auth_failures.dart`)

| Failure | Chave i18n | Quando |
|---|---|---|
| `InvalidFormFailure(fieldErrors)` | `auth_error_invalid_form` | validação local falhou (nada é enviado) |
| `InvalidCredentialsFailure` | `auth_error_invalid_credentials` | senha/e-mail errados ou papel ≠ usuário |
| `EmailAlreadyExistsFailure` | `auth_error_email_exists` | 409 no cadastro |
| `AccountCreatedFailure` | `auth_info_account_created` | conta criada, entrada automática falhou |
| `InvalidRecoveryCodeFailure` | `auth_error_invalid_code` | 401 na verificação do código |
| `ConnectionFailure` / `ServerFailure` | já existentes | rede / servidor |

### CredentialsValidator (`domain/validators/credentials_validator.dart`)

Classe pura (sem Flutter), com as regras do [R3](research.md):

| Método | Devolve |
|---|---|
| `validateLogin(email, password)` | `Map<AuthField, FieldError>`; vazio = válido |
| `validateRegistration(name, email, password)` | idem |
| `validateEmail(email)` | idem (passo 1 da recuperação) |
| `validateCode(code)` | idem |
| `validateNewPassword(password, confirmation)` | idem |
| `passwordRules(password)` | `Set<PasswordRule>` atendidas |

Antes de validar e enviar, `email` passa por `trim()` e `name`, por `trim()`.

### AuthRepository (`domain/repositories/auth_repository.dart`)

```text
login(email, password)            → Either<Failure, UserEntity>   (salva a sessão)
register(name, email, password)   → Either<Failure, UserEntity>   (cadastra + login + salva)
enterAsGuest()                    → Either<Failure, Unit>
requestPasswordReset(email)       → Either<Failure, Unit>
verifyResetCode(email, code)      → Either<Failure, Unit>
resetPassword(email, code, newPassword) → Either<Failure, Unit>
```

### Usecases (`domain/usecases/`)

| Usecase | Valida antes (sem rede) | Chama |
|---|---|---|
| `LoginUseCase` | `validateLogin` | `login` |
| `RegisterUseCase` | `validateRegistration` | `register` |
| `EnterAsGuestUseCase` | — | `enterAsGuest` |
| `RequestPasswordResetUseCase` | `validateEmail` | `requestPasswordReset` |
| `VerifyResetCodeUseCase` | `validateCode` | `verifyResetCode` |
| `ResetPasswordUseCase` | `validateNewPassword` | `resetPassword` |
| `EvaluatePasswordUseCase` (síncrono) | — | `passwordRules` |

## Data

### Models (`data/models/`)

- `AuthTokensModel`: `{accessToken, refreshToken}`, ambos strings não vazias (senão `invalidResponse`).
- `UserModel`: `name`, `email`, `phone?`, `avatarUrl?`, `role` → `toEntity()`.

### AuthRemoteDataSource (`data/datasources/`)

| Método | Request | Resposta |
|---|---|---|
| `register(name, email, password)` | `POST /auth/app/register`, `requiresAuth: false` | 201 (corpo ignorado) |
| `login(email, password)` | `POST /auth/app/login`, `requiresAuth: false` | `AuthTokensModel` |
| `getMe(accessToken)` | `GET /users/me`, `authToken: accessToken` ([R1](research.md)) | `UserModel` |
| `forgotPassword(email)` | `POST /auth/forgot-password`, `requiresAuth: false` | 204 |
| `verifyCode(email, code)` | `POST /auth/forgot-password/verify`, `requiresAuth: false` | 204 |
| `resetPassword(email, code, newPassword)` | `POST /auth/forgot-password/reset`, `requiresAuth: false` | 204 |

### AuthRepositoryImpl (`data/repositories/`)

Recebe `AuthRemoteDataSource` e `UserSessionService`. Fluxo `_signIn(email, password)`:
`login` → `getMe(tokens.accessToken)` → `role == user`? → `saveSession(accessToken, refreshToken,
email: user.email, userName: user.name)` → `Right(user)`. Mapeamento de erros: [R4](research.md).

## Presentation — estado dos controllers

### AuthenticationController

| Estado | Tipo | Observação |
|---|---|---|
| `mode` | `AuthMode { login, register }` | `setMode` limpa `fieldErrors` e `failure` (FR-002) |
| `isSubmitting` | `bool` | ignora `submit` enquanto `true` (FR-006) |
| `fieldErrors` | `Map<AuthField, FieldError>` | não modificável |
| `failure` | `Failure?` | exceto `InvalidFormFailure`, que vai para `fieldErrors` |
| `passwordRules` | `Set<PasswordRule>` | atualizado por `onPasswordChanged` (FR-005) |
| `isPasswordVisible` | `bool` | `togglePasswordVisibility()` (FR-003) |
| `authenticated` | `bool` | `true` após login/cadastro/visitante ok; a página navega e chama `reset()` |

Transições de `submit(name, email, password)`:
- `login`/`register` ok → `authenticated = true`.
- `InvalidFormFailure` → `fieldErrors`.
- `AccountCreatedFailure` → `mode = login`, `failure` = aviso de conta criada (FR-009).
- `EmailAlreadyExistsFailure` → `failure`. A página oferece "Entrar com este e-mail" →
  `setMode(login)`.

`continueAsGuest()` → `authenticated = true`.

### ForgotPasswordController

| Estado | Tipo |
|---|---|
| `step` | `ResetStep` |
| `email`, `code` | `String` (guardados entre passos) |
| `isSubmitting`, `fieldErrors`, `failure` | como acima |
| `secondsUntilResend` | `int` (0 = pode reenviar), calculado com o relógio injetado |
| `completed` | `bool`. `true` após o passo 3; a página faz `pop(email)` |

Operações: `start(initialEmail)`, `submitEmail(email)`, `submitCode(code)`, `resendCode()`,
`submitNewPassword(password, confirmation)`, `back() → bool` (`false` no primeiro passo).
