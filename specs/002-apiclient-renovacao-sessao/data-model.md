# Data Model: Comunicação com a API real e renovação da sessão

**Feature**: [spec.md](spec.md) · **Research**: [research.md](research.md) · **Base**:
[data-model da 001](../001-sessao-persistente-visitante/data-model.md). Os estados
(`UserSessionStatus`) e os motivos de encerramento (`SessionEndReason`) continuam iguais. Abaixo
está só o que muda.

## SessionRecord v2 (persistido)

Chave `session` no armazenamento seguro ([R6](research.md)). O estado `unauthenticated` continua
sendo a ausência do registro.

| Campo JSON | Tipo | Obrigatório quando | Mudança em relação à 001 |
|---|---|---|---|
| `status` | `"authenticated"` \| `"guest"` | sempre | — |
| `accessToken` | string não vazia | `authenticated` | **renomeado** (era `token`) |
| `refreshToken` | string não vazia | `authenticated` | **novo** |
| `email` | string não vazia | `authenticated` | **novo**, substitui `userId` |
| `userName` | string | opcional em `authenticated` | — |

Em `guest`, nenhum campo além de `status` é aceito (presença de `accessToken` ou
`refreshToken` → inválido).

```json
{ "status": "authenticated", "accessToken": "<acesso>", "refreshToken": "<renovação>", "email": "maria@exemplo.com", "userName": "Maria" }
{ "status": "guest" }
```

**Validação na leitura:** além das regras da 001, um registro `authenticated` sem
`accessToken`, `refreshToken` ou `email` não vazios é inválido. É apagado, e a sessão começa
como `unauthenticated` (FR-011). O registro da 001 (`token` + `userId`) cai nessa regra.

## Sessão em memória (`UserSessionService`)

| Campo | Tipo | Mudança |
|---|---|---|
| `accessToken` | `String?` | **renomeado** (era `token`); lido pelo `ApiClient` |
| `refreshToken` | `String?` | **novo**; lido só pelo `ApiClient` na renovação |
| `email` | `String?` | **novo**, substitui `userId` |
| `userName` | `String?` | — |
| `endReason`, `sessionStatus`, `isAuthenticated`, `isGuest` | — | sem mudança |

## Novas transições e operações

| De | Operação | Para | Persistência | Observação |
|---|---|---|---|---|
| qualquer | `saveSession(accessToken, refreshToken, email, userName?)` | `authenticated` | grava v2 | antes: `(token, userId, userName?)`. Vazio → `ArgumentError` |
| `authenticated` | `replaceTokens(previousRefreshToken, accessToken, refreshToken)` com `refreshToken` atual == `previousRefreshToken` | `authenticated` | regrava com o novo par | devolve `true`. **Não** notifica `sessionStatus` (o estado não mudou) |
| `authenticated` com outro `refreshToken`, `guest` ou `unauthenticated` | `replaceTokens(...)` | sem mudança | — | devolve `false` (corrida com logout ou troca de conta, [R7](research.md)) |
| `authenticated` | `updateProfile(name, email)` | `authenticated` | regrava | só atualiza nome e e-mail; outros estados ignoram |
| `authenticated` | `expire()` (renovação recusada, 404 `USER_NOT_FOUND`) | `unauthenticated` | apaga | `endReason = expired` (já existia) |

## Recusa do serviço (`ApiException`)

| Campo | Tipo | Mudança |
|---|---|---|
| `type` | `ApiErrorType` | sem mudança. 401 continua `unauthorized`, inclusive `INVALID_CREDENTIALS` |
| `statusCode` | `int?` | — |
| `errorCode` | `String?` | **passa a vir de `code`** (era `error`). `null` se ausente ou não for o formato `{code, message}` |
| `message` | `String` | — (técnica, nunca exibida) |

`ApiErrorCodes` (constantes, [R9](research.md)): `invalidCredentials = 'INVALID_CREDENTIALS'`,
`userNotFound = 'USER_NOT_FOUND'`.

## Decisão do `ApiClient` para uma resposta de erro

| Condição (request que **enviou** token) | Ação na sessão | Pedido original |
|---|---|---|
| 401 com `code == INVALID_CREDENTIALS` | nenhuma | `ApiException(unauthorized, errorCode: INVALID_CREDENTIALS)` |
| 401 com outro `code` ou sem `code`, token enviado ≠ token atual | nenhuma | repete uma vez com o token atual |
| 401 com outro `code` ou sem `code`, token enviado == token atual | renova (compartilhada, [R2](research.md)) | renovou → repete uma vez; recusada → `expire()` + `unauthorized`; falha de rede/servidor → erro da renovação |
| 401 no pedido **repetido** | `expire()` | `unauthorized` (sem nova renovação, SC-004) |
| 404 com `code == USER_NOT_FOUND` | `expire()` | `ApiException(client, 404)` |
| Request **sem** token (visitante, `requiresAuth: false`) | nunca | erro mapeado normalmente |
