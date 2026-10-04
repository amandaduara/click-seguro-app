# Contratos: autenticação

## Endpoints (fonte: [openapi.json](../../../.specify/memory/openapi.json))

| Método e caminho | Auth | Corpo | Sucesso | Erros que a UI distingue |
|---|---|---|---|---|
| `POST /auth/app/register` | não | `{name, email, password}` | 201 `{name, email}` | 409 `USER_EMAIL_ALREADY_EXISTS` |
| `POST /auth/app/login` | não | `{email, password}` | 200 `{accessToken, refreshToken}` | 401 `INVALID_CREDENTIALS` |
| `GET /users/me` | token do login | — | 200 `{name, email, phone?, avatarUrl?, role, receiveNotifications}` | — |
| `POST /auth/forgot-password` | não | `{email}` | 204 (sempre) | — |
| `POST /auth/forgot-password/verify` | não | `{email, code}` | 204 | 401 `INVALID_RECOVERY_CODE` |
| `POST /auth/forgot-password/reset` | não | `{email, code, newPassword}` | 204 (sempre) | — |

## Mudança aditiva em `ApiClient` (common)

```dart
Future<Response> get(String path, {
  Map<String, dynamic>? queryParameters,
  bool requiresAuth = true,
  CancelToken? cancelToken,
  String? authToken,   // NOVO: usa este Bearer no lugar do da sessão; sem renovação/expiração
});
```

Garantia (com teste): com `authToken`, o header é `Bearer <authToken>`; um 401 **não** chama
`/auth/app/refresh` nem `expire()`.

## Mudança aditiva em `SafeTextField` (core/widgets)

Novos parâmetros opcionais: `keyboardType`, `textInputAction`, `onSubmitted`, `focusNode`,
`autofillHints` e `semanticsLabel`. Os valores padrão mantêm o comportamento atual.

## Barrel público `authentication.dart`

Exporta `AuthenticationModule`, `authenticationRoutes`, `LoginPage` e `ForgotPasswordPage`.
Nada de data/domain fica público: nenhum outro módulo precisa (constituição I).

## Rotas

| Caminho | Tela | Entrada | Saída |
|---|---|---|---|
| `/login` | `LoginPage` | — | `go('/home')` após entrar, cadastrar ou continuar como visitante |
| `/forgot-password` | `ForgotPasswordPage` | `extra: String?` (e-mail já digitado) | `pop(String email)` ao concluir; `pop()` sem valor ao desistir |
| `/home` (provisória) | `HomePlaceholderPage` (`lib/core/routing/`) | — | removida pela F0.9 |
