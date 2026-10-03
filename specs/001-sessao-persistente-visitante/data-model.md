# Data Model: Sessão persistente com modo visitante

**Feature**: [spec.md](spec.md) · **Research**: [research.md](research.md)

## UserSessionStatus (enum)

Conjunto fechado dos estados da sessão (FR-003). Arquivo existente:
`lib/modules/common/services/user_session_service.dart`.

| Valor | Significado | Tem credencial? |
|---|---|---|
| `authenticated` | conectado com uma conta | sim |
| `guest` | visitante (RF-005) | não |
| `unauthenticated` | desconectado | não |

## SessionEndReason (enum, novo)

Motivo do **último** encerramento (FR-012a, research R6).

| Valor | Origem | Efeito esperado na UI (tarefas F0.9/A1) |
|---|---|---|
| `userLogout` | o usuário saiu da conta ou do modo visitante | navegar para `/login` |
| `expired` | o serviço recusou a sessão (401) durante o uso | ficar na tela e mostrar o aviso de sessão expirada |

`endReason` vale `null` enquanto não houver encerramento na execução atual e volta a `null`
quando uma nova sessão começa (`saveSession` / `startGuestSession`).

## SessionRecord (persistido, novo)

O que fica guardado no armazenamento seguro, sob a chave `session` (research R2). O estado
`unauthenticated` é a **ausência** do registro.

| Campo JSON | Tipo | Obrigatório quando | Regra |
|---|---|---|---|
| `status` | `"authenticated"` \| `"guest"` | sempre | outro valor → registro inválido |
| `token` | string não vazia | `status = authenticated` | nunca presente em `guest` |
| `userId` | string não vazia | `status = authenticated` | — |
| `userName` | string | `status = authenticated` | pode ser vazia (saudação genérica) |

Exemplos:

```json
{ "status": "authenticated", "token": "<credencial>", "userId": "u-42", "userName": "Maria" }
{ "status": "guest" }
```

**Validação na leitura (FR-014):** JSON inválido, `status` desconhecido, `authenticated` sem
`token`/`userId`, ou `guest` com `token` → o registro é **apagado** e a sessão começa como
`unauthenticated`. Esse caso não conta como encerramento, então `endReason` continua `null`.

## Sessão em memória (`UserSessionService`)

| Campo | Tipo | Observação |
|---|---|---|
| `sessionStatus` | `ValueNotifier<UserSessionStatus>` | já existe; é o que a UI escuta (FR-004) |
| `token` | `String?` | lido pelo `ApiClient` para o header |
| `userId` | `String?` | — |
| `userName` | `String?` | **novo**, usado na saudação (RF-009) |
| `endReason` | `SessionEndReason?` | **novo** |
| `isAuthenticated` / `isGuest` | `bool` | derivados de `sessionStatus` |

## Transições

| De | Ação | Para | Persistência | `endReason` |
|---|---|---|---|---|
| (abertura) | `restoreSession()` com registro `authenticated` válido | `authenticated` | — | `null` |
| (abertura) | `restoreSession()` com registro `guest` válido | `guest` | — | `null` |
| (abertura) | `restoreSession()` sem registro, inválido ou falha de leitura | `unauthenticated` | apaga o inválido | `null` |
| `unauthenticated` / `guest` | `saveSession(token, userId, userName)` | `authenticated` | grava registro `authenticated` (substitui o de visitante, FR-007) | `null` |
| `unauthenticated` | `startGuestSession()` | `guest` | grava registro `guest` | `null` |
| `authenticated` / `guest` | `logout()` | `unauthenticated` | apaga o registro | `userLogout` |
| `authenticated` | `expire()` (401 durante o uso) | `unauthenticated` | apaga o registro | `expired` |
| `guest` / `unauthenticated` | `expire()` | (sem mudança) | — | (sem mudança) |
| `authenticated` | `saveSession(...)` com outra conta | `authenticated` | substitui o registro (troca de conta, sem resto da anterior) | `null` |

Regras transversais:

- Em toda transição, a memória e o `sessionStatus` mudam **antes** da escrita no disco. Falha
  de escrita não sobe para quem chamou (research R5).
- `logout()`/`expire()` nunca tocam em outras chaves do storage nem no `shared_preferences`:
  contatos, acessibilidade e flag de onboarding sobrevivem (FR-013).
- `saveSession` rejeita (`ArgumentError`) `token` ou `userId` vazios. Isso é erro de
  programação do chamador (A2), não um fluxo de usuário.
