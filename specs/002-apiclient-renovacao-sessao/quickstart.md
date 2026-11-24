# Quickstart: validar a feature 002

**Feature**: [spec.md](spec.md) · **Contratos**: [contracts/](contracts/api-client-and-session.md)
· **Modelo**: [data-model.md](data-model.md)

## Pré-requisitos

- Flutter 3.47.5 (stable), na pasta `click_seguro_app/`.
- `flutter pub get` (a feature não adiciona dependência).

## 1. Testes automatizados (o portão principal)

```bash
cd click_seguro_app
flutter analyze
flutter test test/modules/common/
```

Esperado: `analyze` sem erro nem warning novo e todos os testes verdes. Cenários que os testes
MUST cobrir, por arquivo:

| Arquivo | Cenários |
|---|---|
| `test/modules/common/api_client/api_client_test.dart` | `code` lido do corpo; corpo do Zod e HTML sem `code`; renovação com repetição (SC-001); 5 pedidos simultâneos → 1 renovação (SC-002); `INVALID_CREDENTIALS` não renova nem expira (SC-003); 401 no pedido repetido → expira, sem ciclo (SC-004); renovação recusada → expira; renovação sem rede → sessão mantida; request sem token não renova; 404 `USER_NOT_FOUND` → expira; logout durante a renovação → não repete; `CancelToken` → `cancelled`; `patch`; `postMultipart` (campo, tipo, repetição com `FormData` novo) |
| `test/modules/common/api_client/redacting_log_interceptor_test.dart` | headers e corpos de `/auth/*` e `change-password` fora do log; corpo de outras rotas registrado (SC-008) |
| `test/modules/common/services/user_session_service_test.dart` | registro v2 salvo e restaurado; registro da 001 → descartado (FR-011); `replaceTokens` aplica e recusa (corrida); `updateProfile` |
| `test/modules/common/services/session_validation_service_test.dart` | conta confirmada atualiza o nome; `USER_NOT_FOUND` → desconectado; sem rede/5xx → mantido; prazo esgotado → mantido e resposta tardia ignorada (SC-005/SC-006); visitante não chama o serviço |

## 2. Contra o servidor real (opcional, troca 🧪 por ✅ no contrato)

Com uma conta de teste criada pelo app ou pelo Swagger da API:

```bash
flutter run --dart-define=API_URL=https://<host>/api/v1 --dart-define=DEBUG_MODE=true
```

1. Faça login (quando a A2 existir) ou grave uma sessão de teste com tokens obtidos no Swagger.
2. **Renovação:** substitua o `accessToken` salvo por um valor inválido (ou espere ele vencer)
   e faça uma ação autenticada. Esperado: a ação funciona, e o log mostra `POST
   /auth/app/refresh` com status 200 **sem** corpo.
3. **Log:** procure os dois tokens na saída do `flutter run`. Esperado: nenhuma ocorrência.
4. **Abertura sem rede:** ative o modo avião e reabra o app. Esperado: continua conectado.
5. Se tudo passar, marque `POST /auth/app/refresh` e `GET /users/me` como ✅ no
   [api-contract](../../.specify/memory/api-contract.md).

A conferência na tela de abertura (história 3) só fica visível no aparelho quando a A1 ligar o
`SessionValidationService` ao `SplashController`. Até lá, ela é validada pelos testes do item 1.
