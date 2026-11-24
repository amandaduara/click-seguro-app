# Contratos internos: `ApiClient`, sessão e conferência na abertura

APIs Dart públicas que as trilhas consomem, mais os dois endpoints que esta feature chama.
Mudar uma assinatura daqui exige combinar com as duas trilhas
([plan do produto §6](../../../.specify/memory/plan.md)).

## Endpoints chamados (fonte: [openapi.json](../../../.specify/memory/openapi.json))

| Método e caminho | Auth | Corpo | Sucesso | Erros tratados aqui |
|---|---|---|---|---|
| `POST /auth/app/refresh` | não | `{ "refreshToken": "<renovação>" }` | 200 `{ accessToken, refreshToken }` | 401 `TOKEN_INVALID` → `expire()` |
| `GET /users/me` | sim | — | 200 `{ name, email, phone?, avatarUrl?, role, receiveNotifications }` | 404 `USER_NOT_FOUND` → `expire()` |

Caminhos relativos a `API_URL` (que inclui `/api/v1`).

## `ApiClient`: `lib/modules/common/api_client/api_client.dart`

```dart
class ApiClient {
  static const String refreshPath = '/auth/app/refresh';
  static const List<String> sensitivePathPrefixes = ['/auth/', '/users/me/change-password'];

  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    CancelToken? cancelToken,            // NOVO (F0.2)
  });

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, bool requiresAuth = true});
  Future<Response> put(String path, {dynamic data, bool requiresAuth = true});
  Future<Response> delete(String path, {bool requiresAuth = true});

  Future<Response> patch(String path, {dynamic data, bool requiresAuth = true});   // NOVO (a API usa PATCH em /users/me, change-password)

  Future<Response> postMultipart(String path, {           // NOVO (F0.2)
    required String fieldName,
    required String filePath,
    required String contentType,
    bool requiresAuth = true,
  });
}
```

Garantias (cobertas por teste):

1. **Código de erro:** `ApiException.errorCode` = campo `code` do corpo JSON. Corpo sem `code`,
   em outro formato ou que não é JSON → `errorCode == null`, sem lançar outra exceção.
2. **Renovação:** segue a tabela "Decisão do `ApiClient`" do [data-model](../data-model.md).
   No máximo **uma** renovação simultânea e **uma** repetição por pedido.
3. **Credenciais inválidas:** 401 com `INVALID_CREDENTIALS` nunca altera a sessão nem renova.
4. **Sem token, sem efeito na sessão:** requests que não enviaram `Authorization` nunca renovam
   nem chamam `expire()`.
5. **Conta desativada:** 404 `USER_NOT_FOUND` em request com token → `expire()`.
6. **Cancelamento:** `cancelToken.cancel()` → `ApiException(cancelled)`, sem renovação.
7. **Multipart:** o request sai com `multipart/form-data`, o arquivo vai no campo `fieldName` com o
   `contentType` informado, e um 401 renovável repete o envio com um `FormData` novo.
8. **Log:** com `DEBUG_MODE`, nenhum header é registrado, e os corpos de request e resposta de
   caminhos que começam com um item de `sensitivePathPrefixes` também não.

**Para os repositories (A2, B8):** 401 `INVALID_CREDENTIALS` continua chegando como
`ApiErrorType.unauthorized`. Como `toFailure()` mapeia `unauthorized` → `UnauthorizedFailure`, o
repository MUST testar `errorCode == ApiErrorCodes.invalidCredentials` **antes** do fallback
para devolver `InvalidCredentialsFailure` ("Senha atual incorreta" / "E-mail ou senha
inválidos").

## `ApiErrorCodes`: `lib/modules/common/api_client/api_error_codes.dart` (novo)

```dart
abstract final class ApiErrorCodes {
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String userNotFound = 'USER_NOT_FOUND';
}
```

Só os códigos que o `common` usa. Os códigos de cada feature ficam no repository dela.

## `UserSessionService`: mudanças

| Membro | Antes (001) | Agora |
|---|---|---|
| `token` | `String?` | **renomeado** para `accessToken` |
| `refreshToken` | — | `String?` (novo) |
| `userId` | `String?` | **removido**; no lugar entra `email` (`String?`) |
| `saveSession` | `({required token, required userId, String? userName})` | `({required String accessToken, required String refreshToken, required String email, String? userName})` |
| `replaceTokens` | — | `Future<bool> replaceTokens({required String previousRefreshToken, required String accessToken, required String refreshToken})`. Uso exclusivo do `ApiClient` |
| `updateProfile` | — | `Future<void> updateProfile({required String name, required String email})`. Só age se `authenticated` |

Continuam valendo as garantias 1 a 4 do [contrato da 001](../../001-sessao-persistente-visitante/contracts/session-and-storage.md).
Novas:

5. `replaceTokens` só aplica se `authenticated` **e** `refreshToken == previousRefreshToken`, e
   não notifica `sessionStatus`.
6. `restoreSession` trata como inválido (apaga) o registro sem `accessToken`, `refreshToken` ou
   `email`.

## `SessionValidationService`: `lib/modules/common/services/session_validation_service.dart` (novo)

```dart
class SessionValidationService {
  SessionValidationService(
    ApiClient apiClient,
    UserSessionService session, {
    Duration timeout = const Duration(seconds: 3),
  });

  /// Confere a conta salva com o serviço (FR-008). Nunca lança.
  /// - visitante/desconectado: retorna sem chamar o serviço;
  /// - 200: atualiza nome e e-mail da sessão;
  /// - conta desativada ou renovação recusada: a sessão termina `unauthenticated`;
  /// - sem rede, 5xx, corpo inválido ou prazo esgotado: sessão mantida.
  Future<void> validateStoredSession();
}
```

- Registro: `CommonModule`, `registerLazySingleton`.
- **Quem chama:** `SplashController` (tarefa A1), via `ValidateStoredSessionUseCase` do splash,
  em paralelo com o tempo mínimo do splash. Depois
  dos dois terminarem, a rota sai de `sessionStatus` (`authenticated`/`guest` → `/home`,
  senão `/login`). Ver [research R8](../research.md).
