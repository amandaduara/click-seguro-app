# Contratos internos: sessão e armazenamento

Esta feature não expõe nem consome endpoints HTTP (a validação na abertura está desligada;
ver [research R7](../research.md)). Os contratos abaixo são as **APIs Dart públicas** que as
outras tarefas vão consumir: A1 (splash), A2 (login), F0.9 (shell) e B8 (sair). Mudar qualquer
assinatura daqui exige combinar com as duas trilhas ([plan do produto §6](../../../.specify/memory/plan.md)).

## `SecureStorageService`: `lib/modules/common/services/secure_storage_service.dart`

```dart
abstract class SecureStorageService {
  /// Valor guardado em [key], ou null se não existir.
  /// Pode lançar exceção de plataforma; quem chama decide o fallback.
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
```

- Implementação: `FlutterSecureStorageService` (pacote `flutter_secure_storage`).
- Fake: `test/fakes/fake_secure_storage_service.dart`, com mapa em memória e as flags
  `failOnRead` e `failOnWrite`, mais contadores de chamadas.
- Registro: `CommonModule`, `registerLazySingleton<SecureStorageService>`.

## `LocalCacheService`: `lib/modules/common/services/local_cache_service.dart`

```dart
abstract class LocalCacheService {
  /// JSON guardado em [key], ou null se não existir ou não for um objeto JSON válido.
  Future<Map<String, dynamic>?> readJson(String key);

  Future<void> writeJson(String key, Map<String, dynamic> value);

  Future<void> remove(String key);
}
```

- Implementação: `SharedPreferencesLocalCacheService` (recebe `SharedPreferences` pelo
  construtor).
- Fake: `test/fakes/fake_local_cache_service.dart`.
- Registro: `CommonModule`, `registerLazySingleton<LocalCacheService>`.

## `UserSessionService`: `lib/modules/common/services/user_session_service.dart`

Classe concreta ([research R4](../research.md)), construída com `SecureStorageService`.

| Membro | Tipo | Quem usa |
|---|---|---|
| `sessionStatus` | `ValueNotifier<UserSessionStatus>` | router (F0.9), shell, splash (A1) |
| `endReason` | `SessionEndReason?` | shell: aviso de expirado vs. ir ao login (F0.9) |
| `token` | `String?` | `ApiClient` (header `Authorization`) |
| `userId`, `userName` | `String?` | feed (saudação, A3), perfil |
| `isAuthenticated`, `isGuest` | `bool` | `requireAccount` (F0.9), telas restritas |
| `restoreSession()` | `Future<void>` | `main.dart` `_setup()`, uma vez na abertura. **Nunca lança** |
| `saveSession({required token, required userId, String? userName})` | `Future<void>` | `AuthRepositoryImpl` (A2), após login/cadastro |
| `startGuestSession()` | `Future<void>` | usecase `EnterAsGuest` (A2) |
| `logout()` | `Future<void>` | `SettingsRepositoryImpl` (B8); também serve para "sair do modo visitante" |
| `expire()` | `Future<void>` | `ApiClient` num 401. Só age se `authenticated` |

Garantias (cobertas por teste):

1. `sessionStatus` notifica **depois** de `token`/`userId`/`userName`/`endReason` estarem
   atualizados. Quem escuta sempre lê valores coerentes.
2. Nenhum método, exceto `saveSession` com argumento vazio, lança por falha de storage.
3. `expire()` fora de `authenticated` não faz nada (senha errada no login não gera aviso).
4. `logout()`/`expire()` só apagam a chave `session`.

## Mudança em contrato existente: `ApiClient`

- 401 → `GetIt.instance<UserSessionService>().expire()` (antes era `logout()`). É chamado sem
  `await`: o estado em memória muda na hora e a exceção `ApiException(unauthorized)` segue
  normalmente para o repository.
- `LogInterceptor(requestHeader: false, ...)`: os headers de request não vão mais para o log
  ([research R9](../research.md)).
